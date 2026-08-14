import 'package:lifeos_ai/services/api_service.dart';

class WeatherService {
  static Future<Map<String, dynamic>?> getWeather(
    double lat,
    double lon,
  ) async {
    return await ApiService.getWeather(lat, lon);
  }
}
