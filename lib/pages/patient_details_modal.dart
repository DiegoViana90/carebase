import 'package:carebase/pages/patient_consultations_modal.dart';
import 'package:flutter/material.dart';

class PatientDetailsModal extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsModal({super.key, required this.patient});

  @override
  State<PatientDetailsModal> createState() => _PatientDetailsModalState();
}

class _PatientDetailsModalState extends State<PatientDetailsModal> {
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController professionController;

  bool isEditingEmail = false;
  bool isEditingPhone = false;
  bool isEditingProfession = false;
  bool hasChanges = false;

  late String originalEmail;
  late String originalPhone;
  late String originalProfession;

  @override
  void initState() {
    super.initState();
    originalEmail = widget.patient['email'] ?? '';
    originalPhone = widget.patient['phone'] ?? '';
    originalProfession = widget.patient['profession'] ?? '';

    emailController = TextEditingController(text: originalEmail);
    phoneController = TextEditingController(text: originalPhone);
    professionController = TextEditingController(text: originalProfession);

    emailController.addListener(_checkForChanges);
    phoneController.addListener(_checkForChanges);
    professionController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final changed =
        emailController.text != originalEmail ||
        phoneController.text != originalPhone ||
        professionController.text != originalProfession;
    if (changed != hasChanges) {
      setState(() {
        hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    professionController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (hasChanges) {
      return await _showUnsavedChangesDialog();
    }
    return true;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Alterações não salvas'),
                content: const Text('Deseja sair sem salvar as alterações?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sair sem salvar'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Widget buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required bool otherEditing,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: !isEditing,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: otherEditing ? null : onEditToggle,
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          color: otherEditing ? Colors.grey : null,
          tooltip: isEditing ? 'Salvar campo' : 'Editar',
        ),
      ],
    );
  }

  void _saveAll() {
    setState(() {
      originalEmail = emailController.text;
      originalPhone = phoneController.text;
      originalProfession = professionController.text;
      isEditingEmail = false;
      isEditingPhone = false;
      isEditingProfession = false;
      hasChanges = false;
    });
    // TODO: Salvar no backend se necessário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alterações salvas com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = widget.patient['name'] ?? '---';
    final String cpf = widget.patient['cpf'] ?? '---';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhes do Paciente',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: name,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Nome',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: cpf,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'CPF',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                buildEditableField(
                  label: 'Email',
                  controller: emailController,
                  isEditing: isEditingEmail,
                  onEditToggle: () {
                    setState(() {
                      isEditingEmail = !isEditingEmail;
                      isEditingPhone = false;
                      isEditingProfession = false;
                    });
                  },
                  otherEditing: isEditingPhone || isEditingProfession,
                ),
                const SizedBox(height: 16),
                buildEditableField(
                  label: 'Telefone',
                  controller: phoneController,
                  isEditing: isEditingPhone,
                  onEditToggle: () {
                    setState(() {
                      isEditingPhone = !isEditingPhone;
                      isEditingEmail = false;
                      isEditingProfession = false;
                    });
                  },
                  otherEditing: isEditingEmail || isEditingProfession,
                ),
                const SizedBox(height: 16),
                buildEditableField(
                  label: 'Profissão',
                  controller: professionController,
                  isEditing: isEditingProfession,
                  onEditToggle: () {
                    setState(() {
                      isEditingProfession = !isEditingProfession;
                      isEditingEmail = false;
                      isEditingPhone = false;
                    });
                  },
                  otherEditing: isEditingEmail || isEditingPhone,
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => PatientConsultationsModal(
                            patientId: widget.patient['patientId'],
                            patientName: widget.patient['name'],
                          ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Verificar consultas do paciente'),
                ),

                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (hasChanges) {
                          final confirm = await _showUnsavedChangesDialog();
                          if (!confirm) return;
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Fechar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: hasChanges ? _saveAll : null,
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
