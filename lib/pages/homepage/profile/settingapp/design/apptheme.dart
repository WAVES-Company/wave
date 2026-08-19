import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/main.dart';
import 'package:wave/storage/secure.dart';

class AppThemePage extends StatelessWidget {
  const AppThemePage({super.key});
  @override
  Widget build(BuildContext context) {
    final currentMode = themeNotifier.value;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Text(
                S.of(context).tmv,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 80),
            GestureDetector(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 185,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 10,
                      offset: Offset(0, 5), 
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (){
                        themeNotifier.value = ThemeMode.system;
                        SecureStorageService.saveTheme('system');
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).s,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          currentMode == ThemeMode.system
                              ? const Icon(Icons.check, size: 20)
                              : const SizedBox(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.grey.withOpacity(0.4),
                      thickness: 1,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (){
                        themeNotifier.value = ThemeMode.light;
                        SecureStorageService.saveTheme('light');
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).w,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          currentMode == ThemeMode.light
                              ? const Icon(Icons.check, size: 20)
                              : const SizedBox(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.grey.withOpacity(0.4),
                      thickness: 1,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (){
                        themeNotifier.value = ThemeMode.dark;
                        SecureStorageService.saveTheme('dark');
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).d,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          currentMode == ThemeMode.dark
                              ? const Icon(Icons.check, size: 20)
                              : const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 

// this code was written by maksy