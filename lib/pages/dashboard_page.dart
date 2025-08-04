import 'package:flutter/material.dart';
import 'package:carebase/utils/base_page_layout.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BasePageLayout(
      title: 'CareBase – Gestão de Pacientes',
      showBackButton: false, // ❌ sem botão de voltar, mostra o menu
      child: Center(
        child: Text(
          'Bem-vindo ao CareBase – Gestão de Pacientes!',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
