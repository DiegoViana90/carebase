import 'package:flutter/material.dart';
import 'package:carebase/core/services/test_account_service.dart';
import 'package:carebase/utils/validators.dart';

class TestAccountModal extends StatefulWidget {
  const TestAccountModal({super.key});

  @override
  State<TestAccountModal> createState() => _TestAccountModalState();
}

class _TestAccountModalState extends State<TestAccountModal> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessTaxController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userCpfController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userNameController = TextEditingController();
  final Set<String> _touchedFields = {};

  bool _loading = false;
  String? _error;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await TestAccountService.createTestAccount(
        businessName: _businessNameController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        businessTax: _businessTaxController.text.trim(),
        userName: _userNameController.text.trim(),
        userEmail: _userEmailController.text.trim(),
        userCpf: _userCpfController.text.trim(),
        userPassword: _userPasswordController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta teste criada com sucesso!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(0),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth > 500 ? 500.0 : constraints.maxWidth;

          return Container(
            width: maxWidth,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Criar conta teste (3 dias)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dados da Empresa',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          _businessNameController,
                          'businessName', // fieldKey único
                          'Nome da empresa',
                          theme,
                          validator: validateName,
                        ),
                        _buildInputField(
                          _businessEmailController,
                          'businessEmail', // CORRIGIDO: fieldKey único
                          'Email da empresa',
                          theme,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        _buildInputField(
                          _businessTaxController,
                          'businessTax', // CORRIGIDO: fieldKey único
                          'CNPJ/CPF da empresa',
                          theme,
                          keyboardType: TextInputType.number,
                          validator: validateCpfOrCnpj,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: _showCnpjInfo,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dados do Usuário',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        // --- DADOS DO USUÁRIO ---
                        _buildInputField(
                          _userNameController,
                          'userName', // fieldKey único
                          'Nome do usuário',
                          theme,
                          validator: validateName,
                        ),
                        _buildInputField(
                          _userEmailController,
                          'userEmail', // fieldKey único
                          'Email do usuário',
                          theme,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        _buildInputField(
                          _userCpfController,
                          'userCpf', // fieldKey único
                          'CPF do usuário',
                          theme,
                          keyboardType: TextInputType.number,
                          validator: validateCpf,
                        ),
                        _buildInputField(
                          _userPasswordController,
                          'userPassword', // fieldKey único
                          'Senha',
                          theme,
                          obscureText: true,
                          validator: validatePassword,
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _handleSubmit,
                      icon:
                          _loading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.check, size: 18),
                      label: const Text('Criar conta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String fieldKey, // ← novo
    String label,
    ThemeData theme, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onTap: () {
          setState(() => _touchedFields.add(fieldKey));
        },
        validator: (value) {
          if (!_touchedFields.contains(fieldKey)) return null;
          return validator?.call(value) ??
              (value == null || value.isEmpty ? 'Obrigatório' : null);
        },
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor:
              theme.inputDecorationTheme.fillColor ??
              (theme.brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.grey[200]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showCnpjInfo() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Informação sobre CNPJ/CPF'),
            content: const Text(
              'Se a empresa ainda não possuir um CNPJ, você pode informar o CPF do responsável como identificador temporário.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
    );
  }
}
