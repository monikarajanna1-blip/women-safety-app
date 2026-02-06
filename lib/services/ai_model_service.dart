import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class AIModelService {
  late Interpreter _interpreter;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Load ANN risk model
  Future<void> loadANN() async {
    try{
    _interpreter = await Interpreter.fromAsset(
      'assets/models/ann_risk_model.tflite',
      options: InterpreterOptions()..threads = 2,
    );
    _loaded = true;
  } catch(e) { 
    debugPrint("ANN model load failed: $e");
    _loaded = false;
  }

  }

  /// Run ANN inference
  /// inputs = [time, motion, noise, location]
  double runANN(List<double> inputs) {
    if (!_loaded) {
      throw StateError("ANN model not loaded");
    }

    // Input tensor [1,4]
    final input =
        Float32List.fromList(inputs).reshape([1, 4]);

    // Output tensor [1,1]
    final output =
        Float32List(1).reshape([1, 1]);

    _interpreter.run(input, output);

    return output[0][0].clamp(0.0, 1.0);
  }

  void dispose() {
    if (_loaded) {
      _interpreter.close();
    }
  }
}
