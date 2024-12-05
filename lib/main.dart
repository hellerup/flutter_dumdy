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
        title: 'Dumdy App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

// State-klassen er status på appen - storen
class MyAppState extends ChangeNotifier {
  // Characters
  // Add Json variable to hold json value
  var characters = [];
  var campaigns = [];
  var fetching = false;

  // Call using http to get data from api and store the json data in the json variable
  void getData() async {
    print("getData");
    fetching = true;
    notifyListeners();

    var response = await http.get(Uri.parse(
        'http://64.20.52.59:30081/characters_for_user/?token=b4f69ac5af753a361a5f116eea64ac88' // Production
        // 'http://localhost:3001/characters_for_user/?token=a86921914213b918f6c95f676fb6955c' // Development - GM
        // 'http://localhost:3001/characters_for_user/?token=3bc0fb3c866389faaf5e857ce1a26ac2' // Development - Humlehans
        ));

    if (response.statusCode == 200) {
      characters = jsonDecode(response.body);

      response = await http.get(Uri.parse(
          'http://64.20.52.59:30081/campaigns/?token=b4f69ac5af753a361a5f116eea64ac88' // Production
          // 'http://localhost:3001/campaigns/?token=a86921914213b918f6c95f676fb6955c' // Development - GM
          // 'http://localhost:3001/campaigns/?token=3bc0fb3c866389faaf5e857ce1a26ac2' // Development - Humlehans
          ));

      if (response.statusCode == 200) {
        campaigns = jsonDecode(response.body);
      } else {
        print('Failed to load campaigns');
      }
    } else {
      print('Failed to load characters');
    }

    fetching = false;
    notifyListeners();
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
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: CampaignsPage(),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Pages------------------------------------------------------------
class CampaignsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.fetching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Loading campaigns...',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
      );
    }

    if (appState.campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No campaigns yet.'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                appState.getData();
              },
              child: Text('Load Campaigns'),
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
            child: Text('Load Campaigns'),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('You have '
                '${appState.campaigns.length} campaigns:'),
          ),
          for (var campaign in appState.campaigns)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharactersPage(campaign: campaign),
                  ),
                );
              },
              child: Text(campaign['name']),
            ),
        ],
      ),
    );
  }
}

class CharactersPage extends StatelessWidget {
  final Map<String, dynamic> campaign;

  CharactersPage({required this.campaign});
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    var campaignCharacters = appState.characters
        .where((element) => element['campaign_id'] == campaign['id'])
        .toList()
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(campaign['name']),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('You have '
                            '${campaignCharacters.length} characters:'),
                      ),
                      for (var character in campaignCharacters)
                        if (character['campaign_id'] == campaign['id'])
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CharacterDetailsPage(
                                      character: character),
                                ),
                              );
                            },
                            child: Text(character['name']),
                          ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
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
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
              Table(
                // border: TableBorder.all(),
                columnWidths: {
                  0: FixedColumnWidth(120.0),
                },
                children: [
                  defaultValue(completeCharacter, 'Name'),
                  levels(completeCharacter),
                  defaultValue(completeCharacter, 'Gender'),
                  defaultValue(completeCharacter, 'Race'),
                  defaultValue(completeCharacter, 'Alignment'),
                  defaultValue(completeCharacter, 'Speed'),
                  defaultValue(completeCharacter, 'Ac'),
                  defaultValue(completeCharacter, 'Hp'),
                  defaultValue(completeCharacter, 'Owner'),
                  defaultValue(completeCharacter, ''),
                  attributeValue(completeCharacter, 'Strength'),
                  attributeValue(completeCharacter, 'Intelligence'),
                  attributeValue(completeCharacter, 'Wisdom'),
                  attributeValue(completeCharacter, 'Dexterity'),
                  attributeValue(completeCharacter, 'Constitution'),
                  attributeValue(completeCharacter, 'Charisma'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Returns two cells - label and data
TableRow defaultValue(completeCharacter, String attribute) {
  var label = attribute;
  var value = '';
  if (completeCharacter[attribute.toLowerCase()] != null) {
    value = completeCharacter[attribute.toLowerCase()].toString();
  }

  return TableRow(children: [Text(label), Text(value)]);
}

// Returns two cells - label and data
TableRow levels(completeCharacter) {
  var label = 'Levels';
  var value = '';
  completeCharacter['character_levels'].forEach((level) {
    if (value != '') {
      value += ' / ';
    }
    value += '${level['character_class']['name']} ${level['level']}';
  });

  return TableRow(children: [Text(label), Text(value)]);
}

// Returns label and data - in this case a tablw with two cells
TableRow attributeValue(completeCharacter, String attribute) {
  var label = attribute;
  var value = '';

  if (completeCharacter[attribute.toLowerCase()] != null) {
    value = completeCharacter[attribute.toLowerCase()].toString();
  }
  var bonusAttribute = '${attribute.toLowerCase()}_bonus';
  var bonus = '';
  var bonusSign = '';
  if (completeCharacter[bonusAttribute] != null) {
    bonus = completeCharacter[bonusAttribute].toString();
    bonusSign = completeCharacter[bonusAttribute] > 0 ? '+' : '';
    bonus = '(${bonusSign + bonus})';
  }
  var saveAttribute = '${attribute.toLowerCase()}_save';
  var saveSign = '';
  var saveBonus = '';
  if (completeCharacter[saveAttribute] != null) {
    saveBonus = completeCharacter[saveAttribute].toString();
    saveSign = completeCharacter[saveAttribute] > 0 ? '+' : '';
    saveBonus = saveSign + saveBonus;
  }

  return TableRow(children: [
    Text(label),
    Table(
      // border: TableBorder.all(),
      columnWidths: {
        0: FixedColumnWidth(30.0),
        1: FixedColumnWidth(55.0),
        2: FixedColumnWidth(60.0),
        3: FixedColumnWidth(30.0),
      },
      children: [
        TableRow(children: [
          Text(value, textAlign: TextAlign.right),
          Text(bonus, textAlign: TextAlign.right),
          Text('  Save: '),
          Text(saveBonus, textAlign: TextAlign.right),
          Text(''),
        ]),
      ],
    ),
  ]);
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
