import 'dart:convert';
import 'package:http/http.dart' as http;

class OsmRiskService {
  static Future<double> policeDistanceRisk(
      double lat, double lon) async {
    try {
      final query = '''
      [out:json];
      node["amenity"="police"](around:1500,$lat,$lon);
      out body;
      ''';

      final url = Uri.parse(
        'https://overpass-api.de/api/interpreter',
      );

      final response = await http.post(
        url,
        body: {'data': query},
      );

      if (response.statusCode != 200) {
        return 0.3; // unknown → medium risk
      }

      final data = json.decode(response.body);
      final elements = data['elements'] as List;

      if (elements.isEmpty) {
        // No police nearby
        return 0.8;
      }

      // Police found nearby → safer
      return 0.2;
    } catch (_) {
      return 0.3; // fallback
    }
  }
}
