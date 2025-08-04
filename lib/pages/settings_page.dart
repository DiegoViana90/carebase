import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carebase/core/theme/theme_provider.dart';
import 'package:carebase/utils/base_page_layout.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return BasePageLayout(
      title: 'Configurações',
      showBackButton: false, // Drawer habilitado
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferências', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tema Escuro'),
              Switch(
                value: themeProvider.isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
