import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;

class ResponseScreen extends StatefulWidget {
  final String apiResponse;

  const ResponseScreen({super.key, required this.apiResponse});

  @override
  _ResponseScreenState createState() => _ResponseScreenState();
}

class _ResponseScreenState extends State<ResponseScreen> {
  late TextEditingController responseController;
  late TextEditingController fileNameController;
  bool saveAsDocx = false;
  bool saveAsPdf = false;
  String folderPath = "None";

  @override
  void initState() {
    super.initState();
    responseController =
        TextEditingController(text: formatApiResponse(widget.apiResponse));
    fileNameController = TextEditingController();
  }

  @override
  void dispose() {
    responseController.dispose();
    fileNameController.dispose();
    super.dispose();
  }

  String formatApiResponse(String apiResponse) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(apiResponse);
      final questions = jsonResponse['questions'] as List<dynamic>;
      final answers = jsonResponse['answers'] as List<dynamic>;

      final Map<int, String> updatedAnswers = {};

      for (var question in questions) {
        final questionId = question['id'] as int;
        final correctOption = answers.firstWhere((answer) =>
            answer['question_id'] == questionId)['correct_option'] as String;

        final options = question['options'] as Map<String, dynamic>;
        final randomizedCorrectOption =
            randomizeCorrectOption(correctOption, options);

        updatedAnswers[questionId] = randomizedCorrectOption;
      }

      for (var answer in answers) {
        final questionId = answer['question_id'] as int;
        answer['correct_option'] = updatedAnswers[questionId];
      }

      String formattedResponse = 'Questions:\n';
      for (var question in questions) {
        formattedResponse += '${question['id']}. ${question['text']}\n';

        // Sorting options alphabetically by key
        final options = question['options'] as Map<String, dynamic>;
        final sortedOptions = options.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (var entry in sortedOptions) {
          formattedResponse += '${entry.key}) ${entry.value}\n';
        }
        formattedResponse += '\n';
      }

      formattedResponse += '\nAnswers:\n';
      for (var answer in answers) {
        formattedResponse +=
            '${answer['question_id']}. ${answer['correct_option']}) ${answer['explanation']}\n';
      }

      return formattedResponse;
    } catch (e) {
      return 'Error parsing response: $e';
    }
  }

  String randomizeCorrectOption(
      String correctOption, Map<String, dynamic> options) {
    // Extract available option keys (A, B, C, D) that exist in the map
    final availableKeys = options.keys.toList();

    if (availableKeys.length < 2) {
      // No need to shuffle if there's only one option or none
      return correctOption;
    }

    // Shuffle the keys to randomize option order
    final shuffledKeys = List.of(availableKeys)..shuffle();

    // Create a new mapping with shuffled keys
    final newOptions = <String, String>{};
    String newCorrectOptionKey = '';

    for (int i = 0; i < availableKeys.length; i++) {
      newOptions[shuffledKeys[i]] = options[availableKeys[i]];

      // Update correct option key if it's the one being replaced
      if (availableKeys[i] == correctOption) {
        newCorrectOptionKey = shuffledKeys[i];
      }
    }

    // Clear and update the original options map
    options
      ..clear()
      ..addAll(newOptions);

    return newCorrectOptionKey;
  }

  Future<void> saveTxt(String filePath) async {
    final content = responseController.text;

    final file = File(filePath);
    await file.writeAsString(content);
  }

  Future<void> savePdf(String filePath) async {
    final pdf = pw.Document();
    String userVisibleText = responseController.text;

    // Add newline before "Answers:"
    final parts = userVisibleText.split('\nAnswers:');
    if (parts.length > 1) {
      userVisibleText = '${parts[0]}\n\nAnswers:${parts[1]}';
    }

    final lines = userVisibleText.split('\n'); // Split by newlines

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: lines
                .map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 12)))
                .toList(),
          ),
        ],
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
  }

  Future<void> saveFile() async {
    if (folderPath == "None") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a folder to save the file.')),
      );
      return;
    }

    if (!saveAsDocx && !saveAsPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select at least one file format to save.')),
      );
      return;
    }

    if (fileNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a file name.')),
      );
      return;
    }

    try {
      if (saveAsDocx) {
        // Save as .txt instead of .docx
        String txtFilePath = '$folderPath/${fileNameController.text}.txt';
        await saveTxt(txtFilePath);
        print('Saved as .txt at $txtFilePath');
      }

      if (saveAsPdf) {
        String pdfFilePath = '$folderPath/${fileNameController.text}.pdf';
        await savePdf(pdfFilePath);
        print('Saved as .pdf at $pdfFilePath');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File(s) saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generated Questions',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple,
                Colors.blue
              ], // Define your gradient colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors
            .transparent, // Make AppBar background transparent to show gradient
        elevation: 0, // Optional: Remove shadow for a cleaner look
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bgImage4.jpg',
              fit: BoxFit.cover, // Cover the entire screen
            ),
          ),
          // Existing Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.apiResponse.isNotEmpty)
                  Text(
                    'Response:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(
                            255, 0, 0, 0)), // White text for better visibility
                  ),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: responseController,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'The response will appear here...',
                        filled: true,
                        fillColor: const Color.fromARGB(255, 255, 246, 246)
                            .withOpacity(
                                0.85), // Slightly transparent white background
                      ),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.multiline,
                      readOnly: false,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: saveAsDocx,
                          onChanged: (value) {
                            setState(() {
                              saveAsDocx = value ?? false;
                            });
                          },
                        ),
                        Text('Save as .txt',
                            style: TextStyle(
                                fontSize: 16,
                                color: const Color.fromARGB(255, 0, 0,
                                    0))), // White text for better visibility
                      ],
                    ),
                    SizedBox(width: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: saveAsPdf,
                          onChanged: (value) {
                            setState(() {
                              saveAsPdf = value ?? false;
                            });
                          },
                        ),
                        Text('Save as .pdf',
                            style: TextStyle(
                                fontSize: 16,
                                color: const Color.fromARGB(255, 0, 0,
                                    0))), // White text for better visibility
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text('Folder Path:',
                        style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 0, 0,
                                0))), // White text for better visibility
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        String? selectedFolder =
                            await FilePicker.platform.getDirectoryPath();
                        setState(() {
                          folderPath = selectedFolder ?? "None";
                        });
                      },
                      child: Text('Select Folder'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Tooltip(
                        message: folderPath,
                        child: Text(
                          folderPath,
                          style: TextStyle(
                              fontSize: 16,
                              color: const Color.fromARGB(255, 0, 0,
                                  0)), // White text for better visibility
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('File Name:',
                        style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 8, 7,
                                7))), // White text for better visibility
                    SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: fileNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter file name',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(
                                  0.8), // Slightly transparent white background
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: saveFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                          fontSize: 16,
                          color: const Color.fromARGB(255, 255, 255, 255)),
                    ),
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
