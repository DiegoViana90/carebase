import 'package:flutter/material.dart';
import 'package:carebase/utils/validators.dart';
import 'package:carebase/core/services/patient_service.dart';

class AddPatientModal extends StatefulWidget {
  final VoidCallback onSuccess;
  const AddPatientModal({super.key, required this.onSuccess});

  @override
  State<AddPatientModal> createState() => _AddPatientModalState();
}

class _AddPatientModalState extends State<AddPatientModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _professionController = TextEditingController();

  final Set<String> _touchedFields = {};
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await PatientService.createPatient(
        name: _nameController.text.trim(),
        cpf: _cpfController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        profession: _professionController.text.trim(),
      );

      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
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
                  'Novo Paciente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInputField(
                          _nameController,
                          'name',
                          'Nome',
                          theme,
                          validator: validateName,
                        ),
                        _buildInputField(
                          _cpfController,
                          'cpf',
                          'CPF',
                          theme,
                          keyboardType: TextInputType.number,
                          validator: validateCpf,
                        ),
                        _buildInputField(
                          _phoneController,
                          'phone',
                          'Telefone',
                          theme,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildInputField(
                          _emailController,
                          'email',
                          'Email',
                          theme,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        _buildInputField(
                          _professionController,
                          'profession',
                          'Profissão',
                          theme,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
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
                      onPressed: _loading ? null : _submit,
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
                      label: const Text('Salvar'),
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
    String fieldKey,
    String label,
    ThemeData theme, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onTap: () => _touchedFields.add(fieldKey),
        validator: (value) {
          if (!_touchedFields.contains(fieldKey)) return null;
          return validator?.call(value);
        },
        decoration: InputDecoration(
          labelText: label,
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
}
