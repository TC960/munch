import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert'; // required to encode/decode json data
import 'package:http/http.dart' as http;
import 'string_extensions.dart';

class ShowSteps extends StatefulWidget {
  const ShowSteps(
      {super.key, required this.recipe, required this.detectedIngredients});

  final String recipe;
  final List detectedIngredients;

  @override
  State<ShowSteps> createState() => _ShowStepsState();
}

class _ShowStepsState extends State<ShowSteps> {
  dynamic description = "";
  List<dynamic> ingredients = [];
  List<dynamic> instructions = [];

  void getSteps(
      String recipe, List detectedIngredients, Function callback) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/get_instructions'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'recipe': recipe,
        'ingredients': detectedIngredients.toString()
      }),
    );

    if (response.statusCode == 200) {
      // If the server did return a 201 CREATED response,
      // then parse the JSON.
      var json = jsonDecode(response.body);
      setState(() {
        description = json['description'];
        json['ingredients'].entries.forEach(
            (entry) => ingredients.add("${entry.key}: ${entry.value}"));
        instructions = json['instructions'];
      });
      callback();
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      throw Exception('Failed to create album.');
    }
  }

  @override
  void initState() {
    super.initState();
    getSteps(widget.recipe, widget.detectedIngredients, () {
      setState(() {});
      build(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: buildStepDetails(context));
  }

  Widget buildStepDetails(BuildContext context) {
    if (instructions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    widget.recipe.toTitleCase(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.apply(color: Theme.of(context).colorScheme.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text(
                      description.toString(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text(
                      "Ingredients",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.apply(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        return Text(
                          ingredients[index].toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text(
                      "Instructions",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.apply(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: instructions.length,
                      itemBuilder: (context, index) {
                        return Text(
                          instructions[index].toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(onPressed: () {}, child: const Text("Voice Guidance"))
          ],
        ),
      );
    }
  }
}
