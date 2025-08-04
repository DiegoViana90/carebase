import 'package:flutter/material.dart';
import 'package:carebase/utils/base_page_layout.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BasePageLayout(
      title: 'Financeiro',
      showBackButton: false, // Mostra o botão de menu (Drawer)
      child: Center(
        child: Text('Aqui vão os dados financeiros.'),
      ),
    );
  }
}
