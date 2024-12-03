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
        'http://64.20.52.59:30081/characters_for_user/?token=b4f69ac5af753a361a5f116eea64ac88'
        // 'http://localhost:3001/characters_for_user/?token=a86921914213b918f6c95f676fb6955c'
        ));

    if (response.statusCode == 200) {
      characters = jsonDecode(response.body);

      response = await http.get(Uri.parse(
          'http://64.20.52.59:30081/campaigns/?token=b4f69ac5af753a361a5f116eea64ac88'
          // 'http://localhost:3001/characters_for_user/?token=a86921914213b918f6c95f676fb6955c'
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
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => Text(
            //                 campaign['name'],
            //                 // CampaignDetailsPage(campaign: campaign),
            //               )
            //           // CampaignDetailsPage(campaign: campaign),
            //           ),
            //     );
            //   },
            //   child: Text(campaign['name']),
            // ),
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
        .toList();

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
