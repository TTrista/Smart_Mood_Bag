import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final Color themeColor;
  final List<Map<String, dynamic>> themeOptions;
  final ValueChanged<Color> onThemeChanged;
  final VoidCallback? onLanguageTap;

  const SettingsPage({
    super.key,
    required this.themeColor,
    required this.themeOptions,
    required this.onThemeChanged,
    this.onLanguageTap,
  });

  Widget _buildThemeColorModule() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children:
                  themeOptions.map((option) {
                    return GestureDetector(
                      onTap: () => onThemeChanged(option['color']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: option['color'],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                themeColor == option['color']
                                    ? Colors.black
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child:
                            themeColor == option['color']
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageModule() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: const Text(
          'Language',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Tap to change language'),
        trailing: const Icon(Icons.language),
        onTap: onLanguageTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildThemeColorModule(),
        _buildLanguageModule(),
        Card(
          child: const ListTile(
            title: Text(
              'More settings coming soon...',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
