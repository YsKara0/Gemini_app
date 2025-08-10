import 'package:flutter/material.dart';
import 'package:flutter_gemini/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemini/components/theme_button.dart';
import 'package:flutter_gemini/screens/voice_shopping_screen.dart';
import 'package:flutter_gemini/screens/recipe_finder.dart';
import 'package:flutter_gemini/screens/daily_assistant_screen.dart'; // Import ekleyin

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GridView'daki children listesine ekleyin:
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  // Sesli Alışveriş Kartı
                  _buildFeatureCard(
                    context: context,
                    title: "Sesli Alışveriş",
                    subtitle: "Ses ile liste oluştur",
                    icon: Icons.mic,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoiceShoppingScreen(),
                        ),
                      );
                    },
                  ),

                  // Tarif Bulucu Kartı
                  _buildFeatureCard(
                    context: context,
                    title: "Tarif Bulucu",
                    subtitle: "Evdeki ürünlerle tarif bul",
                    icon: Icons.restaurant,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecipeFinderScreen(),
                        ),
                      );
                    },
                  ),

                  // Günlük Asistan Kartı (YENİ)
                  _buildFeatureCard(
                    context: context,
                    title: "Günlük Asistanım",
                    subtitle: "Kişisel öneriler al",
                    icon: Icons.assistant,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyAssistantScreen(),
                        ),
                      );
                    },
                  ),

                  // Ayarlar Kartı
                  _buildFeatureCard(
                    context: context,
                    title: "Ayarlar",
                    subtitle: "Uygulama ayarları",
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yakında eklenecek!")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}