import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

class RecognizerScreen extends StatefulWidget {
  final File image;
  const RecognizerScreen(this.image, {super.key});

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {
  late TextRecognizer _textRecognizer;
  String _results = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _recognizeText();
  }

  Future<void> _recognizeText() async {
    try {
      final inputImage = InputImage.fromFile(widget.image);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        _results = recognizedText.text.trim();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = 'Failed to recognize text.';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_results.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _results));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  void _shareText() {
    if (_results.isNotEmpty) {
      Share.share(_results);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Recognizer'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(onPressed: _copyToClipboard, icon: const Icon(Icons.copy)),
          IconButton(onPressed: _shareText, icon: const Icon(Icons.share)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.image),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.grey[100],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _results.isEmpty ? 'No text found.' : _results,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}