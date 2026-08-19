import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/authpage/write.dart';
import 'package:wave/pages/homepage.dart';
import 'package:wave/services/data_sync_service.dart';
import 'package:wave/storage/secure.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignUp = false; 
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final fakeEmail = '$username@mygoalsapp.com';

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: fakeEmail,
          password: password,
        );
        
        if (response.user != null) {
          await SecureStorageService.saveName(name);
          await SecureStorageService.saveMail(username);

          final cryptoSuccess = await DataSyncService.setupCryptoForNewUser(password);
          if (!cryptoSuccess) {
            throw Exception('Critical cryptography initialization error');
          }

          await DataSyncService.sendAllDataToServer();

          messenger.showSnackBar(SnackBar(content: Text(S.of(context).uspeshnreg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.black));
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const WritePage()),
          );
        }
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: fakeEmail,
          password: password,
        );

        if (response.user != null) {
          final cryptoRestoreSuccess = await DataSyncService.restoreCryptoForExistingUser(password);
          if (!cryptoRestoreSuccess) {
            await Supabase.instance.client.auth.signOut();
            throw Exception('Crypto-key decryption error. Check the password.');
          }

          await DataSyncService.downloadAllDataFromServer();

          navigator.pushReplacement(MaterialPageRoute(builder: (context) => const Homepage()));
        }
      }
    } on AuthException catch (authError) {
      print('[Supabase Auth Error] ${authError.message} (Status: ${authError.statusCode})');
      
      String errorText = S.of(context).err;

      if (_isSignUp) {
        if (authError.message.contains('already registered') || authError.message.contains('exists')) {
          errorText = S.of(context).zan;
        }
      } else {
        if (authError.message.contains('Invalid login credentials')) {
          errorText = S.of(context).nevprl; 
        }
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorText, style: const TextStyle(color: Colors.white)), 
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.fixed,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            duration: const Duration(seconds: 3),
          )
        );
      }
    } catch (e) {
      print('[System Auth Error] $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(S.of(context).err, style: const TextStyle(color: Colors.white)), 
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.fixed,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 50),
                          const Spacer(),
                          Text(
                            "wave",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 40,
                              fontFamily: 'Nunito',
                              fontVariations: [
                                FontVariation('wdth', 115),
                                FontVariation('wght', 750),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _isSignUp ? S.of(context).reg : S.of(context).voivsv,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 110, 110, 110),
                            ),
                          ),
                          const SizedBox(height: 50),

                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(overflow: TextOverflow.ellipsis),
                              decoration: _inputDecoration(label: S.of(context).name, isDarkMode: isDarkMode),
                              validator: (val) => val == null || val.trim().isEmpty ? S.of(context).vdtyrnm : null,
                            ),
                            const SizedBox(height: 20),
                          ],

                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(overflow: TextOverflow.ellipsis),
                            decoration: _inputDecoration(label: S.of(context).usrnm, isDarkMode: isDarkMode),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return S.of(context).vdteml;
                              if (val.contains('@')) return S.of(context).ntreb;
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(overflow: TextOverflow.ellipsis),
                            decoration: _inputDecoration(label: S.of(context).prl, isDarkMode: isDarkMode),
                            validator: (val) => val == null || val.trim().length < 6 ? S.of(context).prlot : null,
                          ),
                          const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
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
                                    _isSignUp ? S.of(context).creat : S.of(context).vti,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() => _isSignUp = !_isSignUp),
                            child: Text(
                              _isSignUp ? S.of(context).uject : S.of(context).netsoz,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700, 
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_isSignUp)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 10,
                              ),
                              child: Text(
                                S.of(context).pred1,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 20,
                            ),
                            child: Text(
                              S.of(context).usrname,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 110, 110, 110),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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