import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConfigManager {
  static final ConfigManager _instance = ConfigManager._internal();

  late final String humeApiKey;
  late final String humeConfigId;

  ConfigManager._internal();

  static ConfigManager get instance => _instance;

  Future<void> loadConfig() async {
    // Make sure to create a .env file in your root directory which mirrors the .env.example file
    // and add your API key and an optional EVI config ID.

    // Fetch API key and config ID from environment variables
    humeApiKey = 'arw90qGD1Hb9lIbdjGq1qMCRCt6lSwcMrwcCb5ju5GmCIJGG';
    humeConfigId =
        'NlrAhNHdk1Uk0xITAHJn1S0AzsBAErT9o7iRrGa8ZZqJKl8mYnrijw8aJV3FO0ZU';
  }
}

class InstructionsPage extends StatefulWidget {
  final String recipe;
  final List ingredients;
  final List steps;

  const InstructionsPage(
      {super.key,
      required this.recipe,
      required this.ingredients,
      required this.steps});

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  // define config here for recorder
  static const config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    bitRate:
        1536000, // 48000 samples per second * 2 channels (stereo) * 16 bits per sample
    sampleRate: 48000,
    numChannels: 2,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );
  static final audioInputBufferSize = config.bitRate ~/
      10; // bitrate is "number of bits per second". Dividing by 10 should buffer approximately 100ms of audio at a time.

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  WebSocketChannel? _chatChannel;
  bool _isConnected = false;
  bool _isMuted = false;

  // As EVI speaks, it will send audio segments to be played back. Sometimes a new segment
  // will arrive before the old audio segment has had a chance to finish playing, so -- instead
  // of directly playing an audio segment as it comes back, we queue them up here.
  final List<Source> _playbackAudioQueue = [];

  // Holds bytes of audio recorded from the user's microphone.
  List<int> _audioInputBuffer = <int>[];

  String instructions = "";

  @override
  Widget build(BuildContext context) {
    final muteButton = _isMuted
        ? ElevatedButton(
            onPressed: _unmuteInput,
            child: const Text('Unmute'),
          )
        : ElevatedButton(
            onPressed: _muteInput,
            child: const Text('Mute'),
          );
    final connectButton = _isConnected
        ? ElevatedButton(
            onPressed: _disconnect,
            child: const Text('Disconnect'),
          )
        : ElevatedButton(
            onPressed: _connect,
            child: const Text('Connect'),
          );
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'You are ${_isConnected ? 'connected' : 'disconnected'}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[connectButton, muteButton]))
                  ]))),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load config in singleton
    ConfigManager.instance.loadConfig();
    setState(() {
      instructions =
          "recipe:\n${widget.recipe} \n\n ingredients:\n${widget.ingredients.toString()} \n\n instructions:\n${widget.steps.toString()}";
    });
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: const {
          AVAudioSessionOptions.defaultToSpeaker,
        },
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        audioMode: AndroidAudioMode.normal,
        stayAwake: false,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.voiceCommunication,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);
    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextAudioSegment();
    });
  }

  // Opens a websocket connection to the EVI API and registers a listener to handle
  // incoming messages.
  void _connect() {
    setState(() {
      _isConnected = true;
    });
    var uri =
        'wss://api.hume.ai/v0/evi/chat?api_key=${ConfigManager.instance.humeApiKey}';
    if (ConfigManager.instance.humeConfigId.isNotEmpty) {
      uri = '$uri&config_id=${ConfigManager.instance.humeConfigId}';
    }

    _chatChannel = WebSocketChannel.connect(Uri.parse(uri));

    _chatChannel!.stream.listen(
      (event) async {
        final json = jsonDecode(event) as Map<String, dynamic>;
        final type = json['type'] as String;
        debugPrint("Received message: $type");
        // This message contains audio data for playback.
        if (type == 'audio_output') {
          final data = json['data'] as String;
          final rawAudio = base64Decode(data);
          Source source;
          if (!kIsWeb) {
            source = _urlSourceFromBytes(rawAudio);
          } else {
            source = BytesSource(rawAudio);
          }

          _enqueueAudioSegment(source);
        }

        // This message is sent by EVI when the connection is established.
        if (type == 'chat_metadata') {
          debugPrint("Chat metadata: $event");
          _prepareAudioSettings();
          _startRecording();
        }

        // This message is sent by EVI when the user says something while EVI is still speaking.
        if (type == 'user_interruption') {
          _handleInterruption();
        }

        if (type == 'error') {
          debugPrint("Error: ${json['message']}");
        }
      },
      onError: (error) {
        debugPrint("Connection error: $error");
        _handleConnectionClosed();
      },
      onDone: () {
        debugPrint("Connection closed");
        _handleConnectionClosed();
      },
    );

    debugPrint("Connected");
  }

  void _disconnect() {
    _handleConnectionClosed();
    _handleInterruption();
    _chatChannel?.sink.close();
    debugPrint("Disconnected");
  }

  void _enqueueAudioSegment(Source audioSegment) {
    debugPrint("Enqueueing audio segment");
    if (!_isConnected) {
      return;
    }
    if (_audioPlayer.state == PlayerState.playing) {
      _playbackAudioQueue.add(audioSegment);
    } else {
      _audioPlayer.play(audioSegment);
    }
  }

  void _flushAudio() {
    if (_audioInputBuffer.isNotEmpty) {
      _sendAudio(_audioInputBuffer);
      _audioInputBuffer = [];
    }
  }

  void _handleConnectionClosed() {
    setState(() {
      _isConnected = false;
    });
    _audioInputBuffer.clear();
    _stopRecording();
  }

  void _handleInterruption() {
    _playbackAudioQueue.clear();
    _audioPlayer.stop();
  }

  void _muteInput() {
    _stopRecording();
    setState(() {
      _isMuted = true;
    });
    // When the user hits mute, we should send any audio that's in the buffer
    // waiting to be sent. Otherwise, for example, if you are sending audio in
    // 100ms chunks, and the user says something and immediately hits mute, the
    // last 99ms of audio might not get sent.
    _flushAudio();
  }

  void _playNextAudioSegment() {
    if (_playbackAudioQueue.isNotEmpty) {
      final audioSegment = _playbackAudioQueue.removeAt(0);
      _audioPlayer.play(audioSegment);
    }
  }

  void _prepareAudioSettings() {
    // set session settings to prepare EVI for receiving linear16 encoded audio
    // https://dev.hume.ai/docs/empathic-voice-interface-evi/configuration#session-settings
    _chatChannel!.sink.add(jsonEncode({
      'type': 'session_settings',
      'variables': {
        'instructions': instructions,
      },
      'audio': {
        'encoding': 'linear16',
        'sample_rate': 48000,
        'channels': 2,
      },
    }));
  }

  void _sendAudio(List<int> audioBytes) {
    final base64 = base64Encode(audioBytes);
    _chatChannel!.sink.add(jsonEncode({
      'type': 'audio_input',
      'data': base64,
    }));
  }

  void _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      return;
    }
    final audioStream = await _audioRecorder.startStream(config);

    audioStream.listen((data) async {
      _audioInputBuffer.addAll(data);

      if (_audioInputBuffer.length >= audioInputBufferSize) {
        final bufferWasEmpty =
            !_audioInputBuffer.any((element) => element != 0);
        if (bufferWasEmpty) {
          _audioInputBuffer = [];
          return;
        }
        _sendAudio(_audioInputBuffer);
        _audioInputBuffer = [];
      }
    });
    audioStream.handleError((error) {
      debugPrint("Error recording audio: $error");
    });
  }

  void _stopRecording() {
    _audioRecorder.stop();
  }

  void _unmuteInput() {
    _startRecording();
    setState(() {
      _isMuted = false;
    });
  }

  // In the `audioplayers` library, iOS does not support playing audio from a `ByteSource` but
  // we can use a `UrlSource` with a data URL.
  UrlSource _urlSourceFromBytes(List<int> bytes,
      {String mimeType = "audio/wav"}) {
    return UrlSource(Uri.dataFromBytes(bytes, mimeType: mimeType).toString());
  }
}
