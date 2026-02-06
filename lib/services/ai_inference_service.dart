class AiInferenceService {
  /// ANN inference (risk prediction)
  static double predictRiskANN(List<double> features) {
    // Placeholder for TensorFlow Lite ANN
    // features = [time, motion, noise, crime]
    double sum = features.reduce((a, b) => a + b);
    return (sum / features.length).clamp(0.0, 1.0);
  }

  /// RNN inference (trend smoothing)
  static double smoothWithRNN(List<double> history) {
    if (history.isEmpty) return 0.2;
    return history.reduce((a, b) => a + b) / history.length;
  }
}
