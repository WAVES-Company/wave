import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/main.dart';
import 'package:wave/storage/secure.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final currentLang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Text(
                S.of(context).lngv,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 80),
            Container( 
              constraints: const BoxConstraints(
                minHeight: 125,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 5), 
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque, 
                    onTap: () async {
                      await SecureStorageService.saveLanguage('en');
                      localeNotifier.value = const Locale('en');
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.of(context).en,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        currentLang == 'en'
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
                    onTap: () async {
                      await SecureStorageService.saveLanguage('ru');
                      localeNotifier.value = const Locale('ru');
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.of(context).rus,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        currentLang == 'ru'
                            ? const Icon(Icons.check, size: 20)
                            : const SizedBox()
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// this code was written by maksy