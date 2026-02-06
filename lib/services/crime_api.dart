import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CrimeAPI {
  static Future<double> getCrimeRisk() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final query = """
      [out:json];
      (
        node["amenity"="police"](around:500, ${pos.latitude}, ${pos.longitude});
        node["amenity"="cctv"](around:500, ${pos.latitude}, ${pos.longitude});
        node["highway"="street_lamp"](around:500, ${pos.latitude}, ${pos.longitude});
      );
      out;
      """;

      final response = await http.post(
        Uri.parse("https://overpass-api.de/api/interpreter"),
        body: {"data": query},
      );

      int count = jsonDecode(response.body)["elements"].length;

      if (count == 0) return 1.0;
      if (count < 3) return 0.8;
      if (count < 7) return 0.5;
      return 0.2;
    } catch (e) {
      return 0.5;
    }
  }
}
