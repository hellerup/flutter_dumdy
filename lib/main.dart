import 'dart:convert';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import http package
import 'package:http/http.dart' as http;

// Alle apps har denne metode som er entry point
void main() {
  runApp(DumdyApp());
}

// Dette er den den indledende widget
class DumdyApp extends StatelessWidget {
  const DumdyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

// State-klassen er status på appen
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  // Gets the next random word pair
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  // Sets the word pair as favorite if it is not already a favorite, and vice versa
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  // Characters
  // Add Json variable to hold json value
  var characters = [];

  // Call using http to get data from api and store the json data in the json variable
  void getData() async {
    var response = await http.get(Uri.parse(
        'http://64.20.52.59:30081/characters_for_user/?token=b4f69ac5af753a361a5f116eea64ac88'
        // 'http://localhost:3001/characters_for_user/?token=a86921914213b918f6c95f676fb6955c'
        ));

    if (response.statusCode == 200) {
      characters = jsonDecode(response.body);
      print(response.body);
      print(characters);
      print("Hurra");
      notifyListeners();
    } else {
      print('Failed to load data');
    }
  }
  // @override
  // void initState() {
  //   super.initState();
  //   getData();
  // }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Alt der starter med _ er private
// Stat er al den data der skal bruges i widgeten
// Denne holder også layout for appen
class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      case 2:
        page = CharactersPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth > 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person),
                    label: Text('Characters'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// GeneratorPage er en stateless widget som bruges til at vise ord og knapper
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ...

// Pages------------------------------------------------------------

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class CharactersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No characters yet.'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                appState.getData();
              },
              child: Text('Load Characters'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ListView(
        children: [
          ElevatedButton(
            onPressed: () {
              appState.getData();
            },
            child: Text('Load Characters'),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('You have '
                '${appState.characters.length} characters:'),
          ),
          for (var character in appState.characters)
            // ListTile(
            //   leading: Icon(Icons.favorite),
            //   title:
            //       Text(character['name'] + ' - ' + character['campaign_name']),
            // ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CharacterDetailsPage(character: character),
                  ),
                );
              },
              child: Text(character['name']),
            ),
        ],
      ),
    );
  }
}

class CharacterDetailsPage extends StatelessWidget {
  final Map<String, dynamic> character;

  CharacterDetailsPage({required this.character});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    // Find the complete character in the app state
    var completeCharacter = appState.characters.firstWhere(
      (element) => element['id'] == character['id'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(character['name']),
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Character Details:'),
              SizedBox(height: 10),
              Text('Name: ${completeCharacter['name']}'),
              Text('Campaign: ${completeCharacter['campaign_name']}'),
              Text('Gender: ${completeCharacter['gender']}'),
              Text(''),
              Text('Strength: ${completeCharacter['strength']}'),
              Text('Intelligence: ${completeCharacter['intelligence']}'),
              Text('Wisdom: ${completeCharacter['wisdom']}'),
              Text('Dexterity: ${completeCharacter['dexterity']}'),
              Text('Constitution: ${completeCharacter['constitution']}'),
              Text('Charisma: ${completeCharacter['charisma']}'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@override
Widget build(BuildContext context) {
  var appState = context.watch<MyAppState>();
  var pair = appState.current;

  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Dumgeons and Dragons:'),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorite();
                  },
                  icon: Icon(Icons.favorite),
                  label: Text('Like')),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// En widget er at sammenligne med et Component i Vue
// Det er en sam ling af kode som er genbrugelig
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary, letterSpacing: 4);
    return Card(
      color: theme.colorScheme.primary,
      elevation: 10,
      shadowColor: Colors.red,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}
