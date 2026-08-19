import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/services/data_sync_service.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    final success = await DataSyncService.changePasswordCryptoAndAuth(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        messenger.showSnackBar(SnackBar(content: Text(S.of(context).uspeshnreg)));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(S.of(context).err, style: TextStyle(color: Colors.white)), backgroundColor: Colors.black));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Text(
                    S.of(context).prl,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  decoration: _inputDecoration(label: S.of(context).tekprl, isDarkMode: isDarkMode),
                  validator: (val) => val == null || val.trim().isEmpty ? S.of(context).prlot : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  decoration: _inputDecoration(label: S.of(context).novprl, isDarkMode: isDarkMode),
                  validator: (val) {
                    if (val == null || val.trim().length < 6) return S.of(context).prlot;
                    if (val.trim() == _oldPasswordController.text.trim()) {
                      return S.of(context).ndlsvsstr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordChange,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          S.of(context).smen,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required bool isDarkMode}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

// this code was written by maksy