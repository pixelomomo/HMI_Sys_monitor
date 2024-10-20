import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http; // Import nécessaire pour Flutter Web

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Initialise les bindings Flutter
  runApp(MyApp());
}

// Classe représentant une configuration de test
class TestConfig {
  final String id;
  String? testId; // Ajoutez cette ligne
  String? selectedTest;
  String description;
  String parameter;
  String value;

  TestConfig({
    String? id,
    this.testId, // Ajoutez cette ligne
    this.selectedTest,
    this.description = '',
    this.parameter = '',
    this.value = '',
  }) : id = id ?? UniqueKey().toString();

  Map<String, dynamic> toJson() => {
        'test_id': testId, // Ajoutez cette ligne
        'selected_test': selectedTest,
        'description': description,
        'parameter': parameter,
        'value': value,
      };

  factory TestConfig.fromJson(Map<String, dynamic> json) => TestConfig(
        id: json['id'],
        testId: json['test_id']?.toString(), // Assurez-vous de le convertir en String
        selectedTest: json['selectedTest'],
        description: json['description'],
        parameter: json['parameter'],
        value: json['value'],
      );
}

// Classe de stockage pour lire et écrire les configurations
class ConfigStorage {
  static const String apiUrl = 'http://localhost:3000/configs';

  // Lire les configurations depuis l'API
  Future<List<TestConfig>> readConfigs() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<TestConfig> configs =
            jsonData.map((item) => TestConfig.fromJson(item)).toList();
        print('Configurations lues: ${configs.length}');
        return configs;
      } else {
        print('Erreur lors de la lecture des configurations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la lecture des configurations: $e');
      return [];
    }
  }

  // Écrire les configurations dans l'API
  Future<void> writeConfigs(List<TestConfig> configs) async {
    try {
      final List<Map<String, dynamic>> jsonConfigs =
          configs.map((config) => config.toJson()).toList();

      for (var config in jsonConfigs) {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(config),
        );

        if (response.statusCode != 201) {
          print('Erreur lors de la sauvegarde de la configuration: ${response.body}');
          throw Exception('Failed to save configuration');
        }
      }
      print('Configurations sauvegardées avec succès.');
    } catch (e) {
      print('Erreur lors de l\'écriture des configurations: $e');
      throw e;
    }
  }

  // Exporter les configurations dans un fichier texte et déclencher le téléchargement
  Future<void> exportConfigsToTextFile(List<TestConfig> configs) async {
    try {
      String fileContent = configs.map((config) {
        return '${config.id};${config.selectedTest ?? ''};${config.description};${config.parameter};${config.value}';
      }).join('\n');

      final bytes = utf8.encode(fileContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
            'download', 'configurations_${DateTime.now().millisecondsSinceEpoch}.txt')
        ..click();

      html.Url.revokeObjectUrl(url);

      print('Fichier texte téléchargé avec succès.');
    } catch (e) {
      print('Erreur lors de l\'exportation des configurations: $e');
      throw e;
    }
  }
}

// Classe de gestion de l'état global de l'application
class MyAppState extends ChangeNotifier {
  List<TestConfig> currentConfig = [];
  final ConfigStorage storage = ConfigStorage();

  MyAppState() {
    loadConfigs();
  }

  Future<void> loadConfigs() async {
    try {
      print('Chargement des configurations...');
      currentConfig = await storage.readConfigs();
      print('Configurations chargées: ${currentConfig.length}');
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des configurations: $e');
    }
  }

  void saveConfiguration(String selectedTest) {
  String? testId; // Changer en String? pour gérer les valeurs nulles
  switch (selectedTest) {
    case 'disk checker':
      testId = '1';
      break;
    case 'network adapters':
      testId = '2';
      break;
    case 'removable drive':
      testId = '3';
      break;
    case 'check services':
      testId = '4';
      break;
    default:
      print('Test non reconnu');
      return; // Sortir de la méthode si le test n'est pas reconnu
  }

  TestConfig config = TestConfig(
    testId: testId, // S'assurer que testId est bien défini
    selectedTest: selectedTest,
    description: 'Description du test $selectedTest',
    parameter: 'Paramètre du test',
    value: 'Valeur du test',
  );

  // Envoyer à l'API
  saveConfigToServer(config);
}

  Future<void> saveConfigToServer(TestConfig config) async {
  try {
    final jsonConfig = config.toJson();
    print('Configuration à envoyer: ${json.encode(jsonConfig)}'); // Débogage
    final response = await http.post(
      Uri.parse('http://localhost:3000/configs'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(jsonConfig),
    );

    if (response.statusCode == 201) {
      print('Configuration sauvegardée avec succès');
    } else {
      print('Erreur lors de la sauvegarde de la configuration: ${response.body}');
      throw Exception('Failed to save configuration');
    }
  } catch (e) {
    print('Erreur lors de l\'écriture des configurations: $e');
  }
}

  Future<void> saveConfigs() async {
    try {
      print('Début de la sauvegarde des configurations.');
      await storage.writeConfigs(currentConfig);
      print('Configurations sauvegardées avec succès.');

      await storage.exportConfigsToTextFile(currentConfig);
    } catch (e) {
      print('Erreur lors de la sauvegarde des configurations: $e');
    }
  }

  void addNewConfig() {
    currentConfig.add(TestConfig());
    notifyListeners();
  }

  void addNewTest() {
    currentConfig.add(TestConfig());
    notifyListeners();
  }

  void removeTestConfig(int index) {
    if (index >= 0 && index < currentConfig.length) {
      currentConfig.removeAt(index);
      notifyListeners();
    }
  }

  void updateTestConfig(int index, String? selectedTest, String description,
      String parameter, String value) {
    if (index >= 0 && index < currentConfig.length) {
      currentConfig[index].selectedTest = selectedTest;
      currentConfig[index].description = description;
      currentConfig[index].parameter = parameter;
      currentConfig[index].value = value;
      notifyListeners();
    }
  }
}

// Classe principale de l'application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'System Monitor',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

// Page principale de l'application
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('System Monitor'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Section pour les configurations de test
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configurations de Test',
                  style: TextStyle(fontSize: 24),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        appState.addNewConfig();
                      },
                      child: Text('New config'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (appState.currentConfig.isNotEmpty) {
                          appState.addNewTest();
                        } else {
                          // Afficher un message si aucune configuration n'existe
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Veuillez créer une nouvelle configuration d\'abord.'),
                            ),
                          );
                        }
                      },
                      child: Text('New Test'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              Center(child: CircularProgressIndicator()),
                        );

                        await appState.saveConfigs();

                        Navigator.of(context).pop(); // Ferme l'indicateur de chargement

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Configurations sauvegardées et fichier téléchargé avec succès!'),
                            ),
                          );
                        }
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // Liste des configurations de test
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: appState.currentConfig.length,
              itemBuilder: (context, index) {
                return TestConfigWidget(
                  key: ValueKey(appState.currentConfig[index].id),
                  index: index,
                  config: appState.currentConfig[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget représentant une seule configuration de test
class TestConfigWidget extends StatefulWidget {
  final int index;
  final TestConfig config;

  const TestConfigWidget(
      {Key? key, required this.index, required this.config})
      : super(key: key);

  @override
  State<TestConfigWidget> createState() => _TestConfigWidgetState();
}

class _TestConfigWidgetState extends State<TestConfigWidget> {
  String? selectedTest;
  String description = '';
  String parameter = '';
  String value = '';
  late TextEditingController _descriptionController;
  late TextEditingController _parameterController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    selectedTest = widget.config.selectedTest;
    description = widget.config.description;
    parameter = widget.config.parameter;
    value = widget.config.value;
    _descriptionController = TextEditingController(text: description);
    _parameterController = TextEditingController(text: parameter);
    _valueController = TextEditingController(text: value);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _parameterController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.read<MyAppState>();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne avec le menu déroulant pour choisir un test
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Choisir un test',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTest,
                    items: [
                      DropdownMenuItem(
                        value: 'disk checker',
                        child: Text('disk checker'),
                      ),
                      DropdownMenuItem(
                        value: 'removable drive',
                        child: Text('removable drive'),
                      ),
                      DropdownMenuItem(
                        value: 'check services',
                        child: Text('check services'),
                      ),
                      DropdownMenuItem(
                        value: 'newtork adapters',
                        child: Text('network adapters'),
                      ),
                      // Ajoutez d'autres tests ici si nécessaire
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTest = newValue;
                      });
                      appState.updateTestConfig(
                        widget.index,
                        selectedTest,
                        description,
                        parameter,
                        value,
                      );
                    },
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    appState.removeTestConfig(widget.index);
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            // Champ de saisie pour la description
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  description = value;
                });
                appState.updateTestConfig(
                  widget.index,
                  selectedTest,
                  description,
                  parameter,
                  value,
                );
              },
              controller: _descriptionController,
            ),
            SizedBox(height: 10),
            // Champ de saisie pour le paramètre
            TextField(
              decoration: InputDecoration(
                labelText: 'Paramètre',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  parameter = value;
                });
                appState.updateTestConfig(
                  widget.index,
                  selectedTest,
                  description,
                  parameter,
                  value,
                );
              },
              controller: _parameterController,
            ),
            SizedBox(height: 10),
            // Champ de saisie pour la valeur
            TextField(
              decoration: InputDecoration(
                labelText: 'Valeur',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  this.value = value;
                });
                appState.updateTestConfig(
                  widget.index,
                  selectedTest,
                  description,
                  parameter,
                  this.value,
                );
              },
              controller: _valueController,
            ),
          ],
        ),
      ),
    );
  }
}
