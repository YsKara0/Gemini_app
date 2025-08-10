import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/models/recipe.dart';
import 'package:flutter_gemini/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_gemini/components/theme_button.dart';
import 'package:flutter_gemini/components/product_input_card.dart';
import 'package:flutter_gemini/components/country_selector.dart';
import 'package:flutter_gemini/components/recipe_card.dart';

class RecipeFinderScreen extends StatefulWidget {
  const RecipeFinderScreen({super.key});

  @override
  State<RecipeFinderScreen> createState() => _RecipeFinderScreenState();
}

class _RecipeFinderScreenState extends State<RecipeFinderScreen> {
  List<String> _products = [];
  List<Recipe> _recipes = [];
  String? _selectedCountry;
  bool _isLoading = false;
  
  final TextEditingController _productController = TextEditingController();

  // google generative ai
  late final GenerativeModel _generativeModel;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    
    // API anahtarını kontrol et
    String? apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      log('API_KEY bulunamadı!');
      return;
    }
    
    log('API Key yüklendi: ${apiKey.substring(0, 10)}...');
    
    _generativeModel = GenerativeModel(
      apiKey: apiKey,
      model: 'gemini-1.5-flash-8b',
    );
    _startGeminiSession();
  }

  void _startGeminiSession(){
    _chatSession = _generativeModel.startChat(
      history: [Content("user", [
        TextPart("Vereceğim malzemeler ve mutfak türü ile yemek tarifi öner,bilindik ve sevilen yemekleri öner. JSON formatında yanıt ver: [{\"name\":\"yemek adı\",\"ingredients\":\"malzemeler\",\"instructions\":\"yapılış\",\"cuisine\":\"mutfak türü\"}]"),
      ])]
    );
  }

  void _addProduct() {
    String product = _productController.text.trim();
    if (product.isNotEmpty && !_products.contains(product)) {
      setState(() {
        _products.add(product);
        _productController.clear();
      });
    }
  }

  void _removeProduct(String product) {
    setState(() {
      _products.remove(product);
    });
  }

  void _findRecipes() async {
    if (_products.isEmpty || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen malzemeler ekleyin ve mutfak seçin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String message = "Malzemeler: ${_products.join(', ')}\nMutfak: $_selectedCountry\nBu malzemelerle $_selectedCountry mutfağından yapılabilecek 2-3 yemek tarifi öner.";
      
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
          final List recipesData = jsonDecode(cleanedText);
          _recipes = recipesData.map((e) => Recipe.fromMap(e)).toList();
          setState(() {});
          log('${_recipes.length} tarif bulundu');
        } catch (jsonError) {
          log('JSON Parse Hatası: $jsonError');
        }
      }
    } catch (e) {
      log('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Tarif Bulucu"),
        backgroundColor: Colors.green[700],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün ekleme bölümü
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      labelText: 'Evde olan ürünleri ekleyin',
                      border: OutlineInputBorder(),
                      hintText: 'Örn: domates, soğan, et...',
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    enableSuggestions: true,
                    autocorrect: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZıİğĞüÜşŞöÖçÇ\s]')),
                    ],
                    onSubmitted: (_) => _addProduct(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addProduct,
                  child: const Text('Ekle'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Eklenen ürünler
            if (_products.isNotEmpty) ...[
              const Text(
                'Eklenen Ürünler:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _products.map((product) {
                  return ProductInputCard(
                    product: product,
                    onDelete: () => _removeProduct(product),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Ülke seçimi
            CountrySelector(
              selectedCountry: _selectedCountry,
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tarif bul butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _findRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Tarif Bul', style: TextStyle(fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bulunan tarifler
            if (_recipes.isNotEmpty) ...[
              const Text(
                'Önerilen Tarifler:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return RecipeCard(
                      recipeName: recipe.name,
                      ingredients: recipe.ingredients,
                      instructions: recipe.instructions,
                      onTap: () {
                        // Detay sayfasına gitmek için (ileriye dönük)
                        log('Tarif detayı: ${recipe.name}');
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }
}