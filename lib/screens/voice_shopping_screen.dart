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
import 'package:flutter_gemini/services/shopping_list_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:permission_handler/permission_handler.dart';

class VoiceShoppingScreen extends StatefulWidget {
  const VoiceShoppingScreen({super.key});

  @override
  State<VoiceShoppingScreen> createState() => _VoiceShoppingScreenState();
}

class _VoiceShoppingScreenState extends State<VoiceShoppingScreen> {
  List<Urun> _urunler = [];
  final ShoppingListService _service = ShoppingListService();
  String? _listId; // default list id
  Stream<List<ItemRecord>>? _itemsStream;
  String? _listError;
  bool _offlineMode = false;

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

    // Ensure default Firestore list
    _initList();
  }

  Future<void> _initList() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
      final id = await _service.ensureDefaultList(uid);
      setState(() {
        _listId = id;
        _itemsStream = _service.watchItemsWithIds(id);
        _listError = null;
        _offlineMode = false;
      });
    } catch (e) {
      setState(() {
        _listError = 'Firestore listesi başlatılamadı: $e';
        _offlineMode = true; // Yerel liste modu
      });
    }
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
          // Persist to Firestore
          if (!_offlineMode && _listId != null) {
            try {
              for (final u in _urunler) {
                await _service.addItem(_listId!, u);
              }
            } catch (e) {
              setState(() {
                _listError = 'Firestore ekleme hatası: $e';
                _offlineMode = true;
              });
            }
          }
          setState(() {});
          log('${_urunler.length} ürün eklendi');
        } catch (jsonError) {
          log('JSON Parse Hatası: $jsonError');
          // Fallback: Basit string parsing ile ürün ekleme
          await _parseSimpleText(message);
        }
      }
    } catch (e) {
      log('Hata: $e');
      // Fallback: Basit string parsing ile ürün ekleme
  await _parseSimpleText(message);
    }
  }

  Future<void> _parseSimpleText(String message) async {
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
      // Persist parsed items
  if (!_offlineMode && _listId != null) {
        try {
          for (final u in newUrunler) {
    await _service.addItem(_listId!, u);
          }
        } catch (e) {
          setState(() {
            _listError = 'Firestore ekleme hatası: $e';
            _offlineMode = true;
          });
        }
      }
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
            if (_listError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _listError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
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
  if (!_offlineMode && _listId == null) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  if (_offlineMode) {
    // Yerel tablo modu (tek tablo)
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
                    'Alışveriş Listesi (Yerel) — ${_urunler.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _urunler.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Ürün')),
                    DataColumn(label: Text('Miktar')),
                    DataColumn(label: Text('Birim')),
                    DataColumn(label: Text('İşlem')),
                  ],
                  rows: [
                    for (int i = 0; i < _urunler.length; i++)
                      DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(_urunler[i].isim)),
                        DataCell(Text(_urunler[i].miktar.toString())),
                        DataCell(Text(_urunler[i].miktarTuru)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _urunler.removeAt(i);
                              });
                            },
                          ),
                        ),
                      ])
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                const Text(
                  'Alışveriş Listesi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.red),
                  onPressed: _listId == null
                      ? null
                      : () async {
                          await _service.clearItems(_listId!);
                        },
                  tooltip: 'Tümünü Temizle',
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ItemRecord>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Liste yüklenirken hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Henüz bir ürün eklenmedi.\nMikrofon butonuna basarak ürün ekleyin!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Ürün')),
                      DataColumn(label: Text('Miktar')),
                      DataColumn(label: Text('Birim')),
                      DataColumn(label: Text('İşlem')),
                    ],
                    rows: [
                      for (int i = 0; i < items.length; i++)
                        DataRow(cells: [
                          DataCell(Text('${i + 1}')),
                          DataCell(Text(items[i].urun.isim)),
                          DataCell(Text(items[i].urun.miktar.toString())),
                          DataCell(Text(items[i].urun.miktarTuru)),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                if (_listId != null) {
                                  await _service.removeItem(_listId!, items[i].id);
                                }
                              },
                            ),
                          ),
                        ])
                    ],
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
