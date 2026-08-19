import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/homepage/profile/settingapp/design/apptheme.dart';
import 'package:wave/pages/homepage/profile/settingapp/design/fontsize.dart';
import 'package:wave/pages/homepage/profile/settingapp/design/language.dart';

class Design extends StatelessWidget {
  const Design({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Text(
                S.of(context).ofrv,
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
                  minHeight: 130,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
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
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LanguagePage()),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            isDark ? 'assets/icons/sectionicons/black/languageblack.png' : 'assets/icons/sectionicons/white/languagewhite.png',
                            width: 30, height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).lngv,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withOpacity(0.4),
                      thickness: 1,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AppThemePage()),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            isDark ? 'assets/icons/sectionicons/black/themeblack.png' : 'assets/icons/sectionicons/white/themewhite.png',
                            width: 30, height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).tmv,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withOpacity(0.4),
                      thickness: 1,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FontSizePage()),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            isDark ? 'assets/icons/sectionicons/black/textsizeblack.png' : 'assets/icons/sectionicons/white/textsizewhite.png',
                            width: 30, height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).rzmrv,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
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