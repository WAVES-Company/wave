import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/homepage/profile/settingapp/security/password.dart';
import 'package:wave/pages/homepage/profile/settingapp/security/pin.dart';

class Security extends StatelessWidget {
  const Security({super.key});

  Future<void> _openLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

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
                S.of(context).bezv,
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
                  minHeight: 80,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                          MaterialPageRoute(builder: (context) => const PasswordPage()),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            isDark ? 'assets/icons/sectionicons/black/passwordblack.png' : 'assets/icons/sectionicons/white/passwordwhite.png',
                            width: 30, height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).prl,
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
                          MaterialPageRoute(builder: (context) => const PinPage()),
                        );
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            isDark ? 'assets/icons/sectionicons/black/securityandpasscodeblack.png' : 'assets/icons/sectionicons/white/securityandpasscodewhite.png',
                            width: 30, height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).kod,
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
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _openLink("https://waves-company.github.io/about-wave/wavesafe.html");
              },
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 150,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 10,
                      offset: Offset(0, 5), 
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "wavesafe",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Nunito',
                        fontVariations: const [
                          FontVariation('wdth', 115),
                          FontVariation('wght', 750),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withOpacity(0.4),
                      thickness: 1,
                    ),
                    GestureDetector(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).ws,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).pdrbn,
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 110, 110, 110),
                              ),
                            ),
                          ),
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