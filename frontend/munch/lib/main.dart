import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // required to encode/decode json data
import 'package:http/http.dart' as http;
import 'package:munch/show_steps.dart';
import 'string_extensions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Munch App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x00632CB5)),
        typography: Typography.material2021(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'Munch'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> ingredients = [];
  List<dynamic> breakfast = [];
  List<dynamic> lunch = [];
  List<dynamic> dinner = [];
  List<dynamic> snacks = [];

  void fetchRecipeList(Function callback) async {
    print("Fetch Started");
    const url = 'http://10.0.2.2:8000/get_recipe_list';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(http.MultipartFile.fromBytes('image',
        (await rootBundle.load('images/groceries2.jpg')).buffer.asUint8List(),
        filename: 'image'));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    var json = jsonDecode(response.body);
    print(response.body);
    print(json);
    if (response.statusCode == 200) {
      print("Upload successful");
      setState(() {
        ingredients = json['detected_ingredients'];
        breakfast = json['breakfast'];
        lunch = json['lunch'];
        dinner = json['dinner'];
        snacks = json['snacks'];
      });
      callback();
      print("Fetch Completed");
    } else {
      print("Error getting recipe list");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/groceries2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(96.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      ingredients = [];
                      breakfast = [];
                      lunch = [];
                      dinner = [];
                      snacks = [];
                    });
                    fetchRecipeList(() {
                      setState(() {});
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        builder: buildBottomSheet,
                        isScrollControlled: true,
                        showDragHandle: true,
                        enableDrag: true,
                        useSafeArea: true,
                      );
                    });
                    showModalBottomSheet(
                      context: context,
                      builder: buildBottomSheet,
                      isScrollControlled: true,
                      showDragHandle: true,
                      enableDrag: true,
                      useSafeArea: true,
                    );
                  },
                  child: Image.asset(
                    'images/shutter_button.png',
                    width: 88,
                    height: 88,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomSheet(BuildContext context) {
    if (ingredients.isEmpty) {
      return const SizedBox(
        width: double.infinity,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      var categoryStrings = ["Breakfast", "Lunch", "Dinner", "Snacks"];
      var categoryObjects = [breakfast, lunch, dinner, snacks];
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) {
          var category = categoryObjects[index];
          return Column(
            children: [
              Text(
                categoryStrings[index].toTitleCase(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.apply(color: Theme.of(context).colorScheme.primary),
              ),
              ListView.builder(
                primary: false,
                shrinkWrap: true,
                itemCount: category.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ShowSteps(
                                recipe: category[index]['recipe'].toString(),
                                detectedIngredients: ingredients)),
                      );
                    },
                    title: Text(
                        category[index]['recipe'].toString().toTitleCase()),
                    subtitle:
                        Text("Prep time: ${category[index]['prep_time']} mins"),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }
}
