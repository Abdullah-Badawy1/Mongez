import 'package:flutter/material.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';
import 'package:mongez/widgets/custom_button.dart';
import 'package:mongez/widgets/custom_text_form_field.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: lang.addService),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomFormField(
                controller: titleController,
                hintText: lang.serviceTitle,
              ),
              const SizedBox(height: 16),

              CustomFormField(
                controller: descriptionController,
                hintText: lang.serviceDescription,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: lang.addService,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();

                      // استخدم description بعد كده مع API/Firebase
                      debugPrint(description);

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(lang.serviceAdded),
                          content: Text(lang.serviceAddedMessage(title)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(lang.ok),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
