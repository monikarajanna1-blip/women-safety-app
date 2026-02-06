
class AICore {
  // Risk values
  static double timeRisk = 0.0;
  static double noiseRisk = 0.0;
  static double motionRisk = 0.0;
  static double crimeRisk = 0.0;

  // 1️⃣ TIME BASED RISK
  static double computeTimeRisk() {
    int hour = DateTime.now().hour;

    if (hour >= 22 || hour <= 5) return 1.0;
    if (hour >= 19) return 0.6;
    return 0.2;
  }

  // 2️⃣ FUSION ENGINE
  static double computeFinalRisk() {
    return (0.3 * timeRisk) +
        (0.35 * motionRisk) +
        (0.35 * noiseRisk) +
        (0.30 * crimeRisk);
  }
}
