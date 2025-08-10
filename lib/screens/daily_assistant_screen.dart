import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_gemini/components/theme_button.dart';
import 'package:flutter_gemini/components/daily_card.dart';
import 'package:flutter_gemini/services/weather_service.dart';

class DailyAssistantScreen extends StatefulWidget {
  const DailyAssistantScreen({super.key});

  @override
  State<DailyAssistantScreen> createState() => _DailyAssistantScreenState();
}

class _DailyAssistantScreenState extends State<DailyAssistantScreen> {
  bool _isLoading = false;
  String _greeting = '';
  String _weatherAdvice = '';
  String _motivationMessage = '';
  List<String> _recommendations = [];
  
  late final GenerativeModel _generativeModel;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _generateDailySuggestion();
  }

  void _initializeGemini() {
    String? apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      log('API_KEY bulunamadı!');
      return;
    }

    _generativeModel = GenerativeModel(
      apiKey: apiKey,
      model: 'gemini-1.5-flash-8b',
    );
    _startGeminiSession();
  }

  void _startGeminiSession() {
    _chatSession = _generativeModel.startChat(
      history: [Content("user", [
        TextPart("Günlük asistan olarak hava durumu ve zamana göre kişiselleştirilmiş öneriler ver. JSON formatında yanıt ver: {\"greeting\":\"selamlama\",\"weatherAdvice\":\"hava durumu tavsiyesi\",\"motivationMessage\":\"motivasyon mesajı\",\"recommendations\":[\"öneri1\",\"öneri2\",\"öneri3\"]}"),
      ])]
    );
  }

  Future<void> _generateDailySuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Basit tarih ve saat bilgileri
      DateTime now = DateTime.now();
      String currentDate = "${now.day}/${now.month}/${now.year}";
      String currentTime = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      
      // Gerçek hava durumu bilgisi al
      String weatherInfo = await _getRealWeather();
      
      String prompt = """
      Bugünün tarihi: $currentDate
      Şu anki saat: $currentTime
      Hava durumu: $weatherInfo
      
      Bu bilgilere göre günlük asistan önerisi oluştur. Türkçe ve samimi bir dille yaz.
      """;

      final response = await _chatSession.sendMessage(Content.text(prompt));
      
      if (response.text != null) {
        String cleanedText = response.text!.trim();
        
        // JSON temizleme
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText.substring(7);
        }
        if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText.substring(3);
        }
        if (cleanedText.endsWith('```')) {
          cleanedText = cleanedText.substring(0, cleanedText.length - 3);
        }
        cleanedText = cleanedText.trim();

        try {
          final Map<String, dynamic> suggestionData = jsonDecode(cleanedText);
          
          setState(() {
            _greeting = suggestionData['greeting'] ?? 'Günaydın!';
            _weatherAdvice = suggestionData['weatherAdvice'] ?? 'Bugün harika bir gün!';
            _motivationMessage = suggestionData['motivationMessage'] ?? 'Güzel bir gün seni bekliyor!';
            _recommendations = List<String>.from(suggestionData['recommendations'] ?? []);
          });
        } catch (jsonError) {
          log('JSON Parse Hatası: $jsonError');
          _setDefaultSuggestions();
        }
      }
    } catch (e) {
      log('Günlük öneri oluşturma hatası: $e');
      _setDefaultSuggestions();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getRealWeather() async {
    try {
      // Varsayılan olarak Ankara'nın hava durumunu al
      // İleride konum bilgisi eklenebilir
      String weatherInfo = await WeatherService.getWeatherInfo('Ankara');
      return weatherInfo;
    } catch (e) {
      log('Hava durumu API hatası: $e');
      // API hatası durumunda varsayılan veri döndür
      return "Güneşli, 22°C, %20 yağış ihtimali";
    }
  }

  void _setDefaultSuggestions() {
    setState(() {
      _greeting = 'Günaydın! Yeni bir güne merhaba 🌅';
      _weatherAdvice = 'Bugün dışarı çıkmadan önce hava durumunu kontrol etmeyi unutma!';
      _motivationMessage = 'Her yeni gün, yeni fırsatlar getirir. Bugün de harika şeyler yapacaksın! 💪';
      _recommendations = [
        'Güne bol su içerek başla',
        'Kahvaltını atlama',
        'Biraz nefes alma egzersizi yap',
        'Pozitif düşüncelere odaklan',
      ];
    });
  }

  String _getCurrentTimeGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 18) {
      return 'İyi öğlenler';
    } else {
      return 'İyi akşamlar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Günlük Asistanım"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            onPressed: _generateDailySuggestion,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
          MyThemeButton(
            color: Colors.red[300],
            onTap: () {
              Provider.of<ThemeProvider>(context, listen: false).toogleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Günlük önerileriniz hazırlanıyor...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih ve saat
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Selamlama
                  DailyCard(
                    title: _getCurrentTimeGreeting(),
                    content: _greeting,
                    icon: Icons.waving_hand,
                    color: Colors.orange,
                  ),
                  
                  // Hava durumu tavsiyesi
                  DailyCard(
                    title: 'Hava Durumu',
                    content: _weatherAdvice,
                    icon: Icons.wb_sunny,
                    color: Colors.blue,
                  ),
                  
                  // Motivasyon mesajı
                  DailyCard(
                    title: 'Günün Motivasyonu',
                    content: _motivationMessage,
                    icon: Icons.psychology,
                    color: Colors.purple,
                  ),
                  
                  // Öneriler
                  if (_recommendations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Bugün İçin Önerilerim',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._recommendations.map((recommendation) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.lightbulb_outline,
                          color: Colors.green[700],
                        ),
                        title: Text(recommendation),
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
    );
  }
}