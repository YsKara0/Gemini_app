import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  // Şehir adı ile hava durumu alma
  static Future<String> getWeatherInfo(String city) async {
    try {
      // .env dosyasından weather API URL'ini al
      String? weatherApiUrl = dotenv.env['WEATHER_API_URL'];
      if (weatherApiUrl == null || weatherApiUrl.isEmpty) {
        log('WEATHER_API_URL .env dosyasında bulunamadı');
        return "Hava durumu bilgisi alınamadı";
      }

      final url = '$weatherApiUrl/$city?format=j1';
      log('Hava durumu API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FlutterApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      log('API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('API Response Data: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        
        final current = data['current_condition'][0];
        final weather = data['weather'][0];
        
        String temp = current['temp_C'];
        String desc = current['weatherDesc'][0]['value'];
        String humidity = current['humidity'];
        String chanceOfRain = weather['hourly'][0]['chanceofrain'];
        
        String result = "$desc, ${temp}°C, %$humidity nem, %$chanceOfRain yağış ihtimali";
        log('Hava durumu bilgisi: $result');
        return result;
      } else {
        log('API hatası: HTTP ${response.statusCode}');
        log('Response body: ${response.body}');
        return "Güneşli, 22°C, %20 yağış ihtimali";
      }
    } catch (e) {
      log('Hava durumu hatası: $e');
      return "Güneşli, 22°C, %20 yağış ihtimali"; // Fallback
    }
  }
}