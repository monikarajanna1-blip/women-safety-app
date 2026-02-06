import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class VoiceAIService {
  late Interpreter _nlpInterpreter;
  late Map<String, int> _wordIndex;
  bool _loaded = false;

  static const int maxLen = 10;

  Future<void> loadModels() async {
    // Load tokenizer
    final jsonStr =
        await rootBundle.loadString('assets/tokenizer/tokenizer.json');
    final tokenizerData = json.decode(jsonStr);
    _wordIndex =
        Map<String, int>.from(tokenizerData['word_index']);

    // Load NLP model
    _nlpInterpreter = await Interpreter.fromAsset(
      'assets/models/nlp_distress_model.tflite',
    );

    _loaded = true;
  }

  double runNLP(String text) {
    if (!_loaded) return 0.0;

    final tokens = _tokenize(text);

    final input = Float32List.fromList(tokens).reshape([1, maxLen]);
    final output = Float32List(1).reshape([1, 1]);

    _nlpInterpreter.run(input, output);

    return output[0][0].clamp(0.0, 1.0);
  }

  List<double> _tokenize(String text) {
    final words = text.toLowerCase().split(" ");
    final List<double> tokens = List.filled(maxLen, 0);

    for (int i = 0; i < words.length && i < maxLen; i++) {
      tokens[i] = (_wordIndex[words[i]] ?? 1).toDouble();
    }

    return tokens;
  }


double runCRNN(List<double> audioFeatures) {
  if (audioFeatures.isEmpty) return 0.0;

  final avg =
      audioFeatures.reduce((a, b) => a + b) / audioFeatures.length;

  return min(1.0, avg * 1.2);
}
}