import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/models/urun.dart';
import 'package:flutter_gemini/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_gemini/components/theme_button.dart';
// import 'package:permission_handler/permission_handler.dart';

class VoiceShoppingScreen extends StatefulWidget {
  const VoiceShoppingScreen({super.key});

  @override
  State<VoiceShoppingScreen> createState() => _VoiceShoppingScreenState();
}

class _VoiceShoppingScreenState extends State<VoiceShoppingScreen> {
  List<Urun> _urunler = [];

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false; // _Listening -> _isListening

  // google generative ai
  late final GenerativeModel _generativeModel;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((value) {
      setState(() => _speechAvailable = true);
    });
    
    // API anahtarını kontrol et
    String? apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      log('API_KEY bulunamadı!');
      return;
    }
    
    log('API Key yüklendi: ${apiKey.substring(0, 10)}...'); // İlk 10 karakteri göster
    
    _generativeModel = GenerativeModel(
      apiKey: apiKey,
      model: 'gemini-1.5-flash-8b', // Daha hızlı ve az yüklü model
    );
    _startGeminiSession();
  }

  void _startListening() {
    setState(() => _isListening = true); // _Listening -> _isListening
    _speech.listen(
      onResult: (result){
        if(result.finalResult){
         _sendMessage(result.recognizedWords);
        }
      }
    );
  }

  void _stopListening() {
    _speech.stop().then((value) {
      setState(() => _isListening = false); // _Listening -> _isListening
    });
  }

  void _startGeminiSession(){
   _chatSession = _generativeModel.startChat(
    history: [Content("user", [
      TextPart("Vereceğim cümlede geçen alışveriş listesini JSON Formatına döndür:{isim,miktar,miktarTuru(kilo,adet veya litre)}"),
    ])]
   );
  }

  void _sendMessage(String message) async {
    try {
      final GenerateContentResponse response = await _chatSession.sendMessage(Content.text(message));
      if (response.text case final String text) {
        log('AI Yanıtı: $text');
        
        // JSON temizleme
        String cleanedText = text.trim();
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
          final List urunlerData = jsonDecode(cleanedText);
          _urunler = urunlerData.map((e) => Urun.fromMap(e)).toList();
          setState(() {});
          log('${_urunler.length} ürün eklendi');
        } catch (jsonError) {
          log('JSON Parse Hatası: $jsonError');
          // Fallback: Basit string parsing ile ürün ekleme
          _parseSimpleText(message);
        }
      }
    } catch (e) {
      log('Hata: $e');
      // Fallback: Basit string parsing ile ürün ekleme
      _parseSimpleText(message);
    }
  }

  void _parseSimpleText(String message) {
    // Basit kelime bazlı parsing
    List<String> words = message.toLowerCase().split(' ');
    List<Urun> newUrunler = [];
    
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isNotEmpty) {
        // Sayı varsa miktar olarak kullan
        double miktar = 1.0;
        String miktarTuru = 'adet';
        
        if (i > 0) {
          double? parsedMiktar = double.tryParse(words[i-1]);
          if (parsedMiktar != null) {
            miktar = parsedMiktar;
          }
        }
        
        // Bilinen birimler
        if (word.contains('kilo') || word.contains('kg')) {
          miktarTuru = 'kilo';
        } else if (word.contains('litre') || word.contains('lt')) {
          miktarTuru = 'litre';
        }
        
        // Basit ürün isimleri
        if (!word.contains(RegExp(r'[0-9]')) && 
            word.length > 2 && 
            !['bir', 'iki', 'üç', 'kilo', 'adet', 'litre', 'kg', 'lt'].contains(word)) {
          newUrunler.add(Urun(word, miktar, miktarTuru));
        }
      }
    }
    
    if (newUrunler.isNotEmpty) {
      setState(() {
        _urunler.addAll(newUrunler);
      });
      log('${newUrunler.length} ürün basit parsing ile eklendi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Sesli Alışveriş Listesi"),
        backgroundColor: Colors.green [700],
        actions: [
          MyThemeButton(
            color: Colors.red[300],
            onTap: () {
              Provider.of<ThemeProvider>(context, listen: false).toogleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _urunlerList(),
            const SizedBox(height: 20),
            
            // Mikrofon kontrol bölümü
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _isListening 
                        ? 'Dinleniyor... Konuşun!' 
                        : 'Alışveriş listesi eklemek için konuşun',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isListening ? Colors.red : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton.large(
                          onPressed: _speechAvailable 
                            ? (_isListening ? _stopListening : _startListening)
                            : null,
                          backgroundColor: _isListening ? Colors.red : Colors.green,
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    Text(
                      _speechAvailable 
                        ? (_isListening ? 'Durdurmak için tıklayın' : 'Başlamak için tıklayın')
                        : 'Mikrofon erişimi bekleniyor...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
 Widget _urunlerList() {
  if (_urunler.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Text(
        "Henüz bir ürün eklenmedi.\nMikrofon butonuna basarak ürün ekleyin!",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  } else {
    return Flexible(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Alışveriş Listesi (${_urunler.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _urunler.clear();
                      });
                    },
                    tooltip: 'Tümünü Temizle',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _urunler.length,
                itemBuilder: (context, index) {
                  final Urun urun = _urunler[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        urun.isim,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${urun.miktar} ${urun.miktarTuru}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _urunler.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
 }
}
}
