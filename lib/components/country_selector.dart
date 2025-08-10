import 'package:flutter/material.dart';

class CountrySelector extends StatelessWidget {
  final String? selectedCountry;
  final Function(String?) onChanged;
  final List<String> countries = const [
    'Türk',
    'İtalyan',
    'Çin',
    'Hint',
    'Meksika',
    'Fransız',
    'Japon',
    'Yunan',
    'Tayland',
    'Kore',
    'Amerika',
    'İspanyol',
  ];

  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          value: selectedCountry,
          decoration: const InputDecoration(
            labelText: 'Hangi ülkenin yemeğini yapmak istiyorsunuz?',
            border: InputBorder.none,
          ),
          items: countries.map((String country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text('$country Mutfağı'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
