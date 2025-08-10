# Flutter Gemini App

A Flutter application that integrates with Google's Gemini AI to provide cooking assistance, recipe suggestions, and voice-controlled shopping features.

## Features

- 🤖 **AI-Powered Recipe Suggestions**: Get personalized recipe recommendations based on available ingredients
- 🗣️ **Voice Shopping**: Voice-controlled shopping list management
- 🌤️ **Weather-Based Suggestions**: Daily meal suggestions based on weather conditions
- 🌍 **Multi-Country Support**: Country-specific recipe recommendations
- 🎨 **Dynamic Theming**: Light and dark theme support

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Google Gemini API Key

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd gemini_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the root directory and add your API keys:
```
GEMINI_API_KEY=your_gemini_api_key_here
WEATHER_API_KEY=your_weather_api_key_here
```

4. Run the application:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── components/              # Reusable UI components
│   ├── country_selector.dart
│   ├── daily_card.dart
│   ├── product_input_card.dart
│   ├── recipe_card.dart
│   └── theme_button.dart
├── models/                  # Data models
│   ├── daily_suggestion.dart
│   ├── recipe.dart
│   └── urun.dart
├── screens/                 # Application screens
│   ├── daily_assistant_screen.dart
│   ├── home_screen.dart
│   ├── recipe_finder.dart
│   └── voice_shopping_screen.dart
├── services/               # External services
│   └── weather_service.dart
└── theme/                  # Theme configuration
    ├── theme_provider.dart
    └── theme.dart
```

## Configuration

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
GEMINI_API_KEY=your_gemini_api_key
WEATHER_API_KEY=your_weather_api_key
```

### API Keys

1. **Gemini API Key**: Get from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. **Weather API Key**: Get from [OpenWeatherMap](https://openweathermap.org/api)

## Usage

1. **Home Screen**: Navigate between different features
2. **Recipe Finder**: Enter ingredients to get AI-powered recipe suggestions
3. **Voice Shopping**: Use voice commands to manage your shopping list
4. **Daily Assistant**: Get weather-based meal recommendations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemini AI for recipe generation
- Flutter team for the amazing framework
- OpenWeatherMap for weather data
