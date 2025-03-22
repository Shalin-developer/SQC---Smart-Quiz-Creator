import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'response_screen.dart'; // Import the ResponseScreen
import 'splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For storing preferences

String apiKey = ''; // ENTER YOUR API KEY HERE

void main() {
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class QuestionCreatorApp extends StatelessWidget {
  const QuestionCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuestionCreatorScreen(),
    );
  }
}

class QuestionCreatorScreen extends StatefulWidget {
  const QuestionCreatorScreen({super.key});

  @override
  _QuestionCreatorScreenState createState() => _QuestionCreatorScreenState();
}

class _QuestionCreatorScreenState extends State<QuestionCreatorScreen> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController apiKeyController = TextEditingController(
      text: apiKey); // Initialize with the current API key
  List<Map<String, String>> topics = [];
  String apiResponse = '';
  bool isLoading = false; // Tracks loading state
  bool dontShowAgain = false; // Tracks the "Don't show me again" checkbox

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _checkAndShowDialog();
  }

  Future<void> _checkAndShowDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool showDialog = !(prefs.getBool('dontShowDialog') ?? false);

    if (showDialog && apiKey.isEmpty) {
      // Only show the dialog if the API key is not already loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiKeyDialog();
      });
    }
  }

  Future<void> _loadApiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedApiKey = prefs.getString('apiKey') ?? '';
    if (savedApiKey.isNotEmpty) {
      setState(() {
        apiKey = savedApiKey;
        apiKeyController.text = savedApiKey; // Set the text in the controller
      });
    }
  }

  Future<void> fetchQuestions() async {
    setState(() {
      isLoading = true; // Show progress indicator
    });

    String prompt = '''
Generate JSON data for questions and answers based on this schema:
{
  "questions": [
    {
      "id": integer,
      "text": string,
      "options": {
        "A": string,
        "B": string,
        "C": string,
        "D": string
      }
    }
  ],
  "answers": [
    {
      "question_id": integer,
      "correct_option": string,
      "explanation": string
    }
  ]
}

Ensure that the correct answer is randomly placed in one of the options (A, B, C, or D). Here are the topics and number of questions for each:
''';

    for (var topic in topics) {
      prompt += '- ${topic['topic']}: ${topic['number']} questions\n';
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        apiResponse = response.text ?? 'No response received.';
        isLoading = false; // Hide progress indicator
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResponseScreen(apiResponse: apiResponse),
        ),
      );
    } catch (e) {
      setState(() {
        apiResponse = 'Error: $e';
        isLoading = false; // Hide progress indicator
      });
    }
  }

  void _showApiKeyDialog() {
    bool showFullDisclaimer =
        false; // Tracks whether to show the full disclaimer

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: const Color.fromARGB(255, 132, 109, 173),
              content: SizedBox(
                width: 400, // specify width
                height: showFullDisclaimer
                    ? 230
                    : 200, // adjust height based on disclaimer state
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'Enter API Key:',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.purple[400],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) {
                        // Update the state to enable/disable the button
                        setState(() {});
                      },
                    ),
                    Row(
                      children: [
                        Theme(
                          data: ThemeData(
                            checkboxTheme: CheckboxThemeData(
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) {
                                  if (!states.contains(WidgetState.selected)) {
                                    return const Color.fromARGB(
                                        255, 114, 116, 250); // Inactive color
                                  }
                                  return Colors.purple; // Active color
                                },
                              ),
                            ),
                          ),
                          child: Checkbox(
                            value: dontShowAgain,
                            onChanged: (value) {
                              setState(() {
                                dontShowAgain = value ?? false;
                              });
                            },
                            activeColor: Colors.purple,
                          ),
                        ),
                        Text(
                          "Don't show me again",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: apiKeyController.text.isNotEmpty
                          ? () async {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();

                              // Save the API key
                              await prefs.setString(
                                  'apiKey', apiKeyController.text);

                              // Save the "Don't show me again" preference
                              if (dontShowAgain) {
                                await prefs.setBool('dontShowDialog', true);
                              }

                              // Update the API key
                              setState(() {
                                apiKey = apiKeyController.text;
                              });

                              Navigator.pop(context); // Close the dialog
                            }
                          : null, // Disable the button if the textbox is empty
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 15),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showFullDisclaimer = !showFullDisclaimer;
                        });
                      },
                      child: Text(
                        'Disclaimer:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (showFullDisclaimer)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'The Questions and Answers may contain errors as they are generated by AI. The developers takes no liability for the use of the software.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.blue, Colors.purple], // Define your gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Smart Quiz Creator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors
                  .white, // This color is required, but it will be overridden by the gradient
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(158, 39, 205, 255),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgImage2.jpg',
              fit: BoxFit.cover, // Cover the entire screen
            ),
          ),
          // Existing Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: topicController,
                        decoration: InputDecoration(
                          labelText: 'Type your topic!',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                              0.8), // Slightly transparent white background
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'No. of Qn.s (eg: 7)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                              0.8), // Slightly transparent white background
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        String topic = topicController.text;
                        String number = numberController.text;
                        if (topic.isNotEmpty && number.isNotEmpty) {
                          setState(() {
                            topics.add({'topic': topic, 'number': number});
                          });
                          topicController.clear();
                          numberController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Qn. Topic',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .white), // White text for better visibility
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Number of Qn.s',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .white), // White text for better visibility
                      ),
                    ),
                  ],
                ),
                Divider(
                    color: Colors.white), // White divider for better visibility
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: topics.map((topic) {
                        int index = topics.indexOf(topic);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(topic['topic'] ?? '',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255))), // White text for better visibility
                              ),
                              Expanded(
                                child: Text(topic['number'] ?? '',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .white)), // White text for better visibility
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    topics.removeAt(index);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                ),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: isLoading ? null : fetchQuestions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        child: Text(
                          'Create',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      if (isLoading)
                        SizedBox(
                          width: 40,
                          height: 24,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: CircularProgressIndicator(
                              color: Colors.indigo,
                              strokeWidth: 3.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
