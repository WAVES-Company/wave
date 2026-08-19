import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

class About extends StatelessWidget {
  const About({super.key});

  Future<String> getVersion(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    return S.of(context).ver(info.version);
  }

  Future<void> _openLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Text(
                S.of(context).prilv,
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
                  minHeight: 270,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "wave",
                      overflow: TextOverflow.ellipsis,
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
                      onTap: () {
                        _openLink("https://t.me/waveofgoals");
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).tgw,
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
                        _openLink("https://waves-company.github.io/about-wave/privacy.html");
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).pltknf,
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
                        _openLink("https://waves-company.github.io/about-wave/terms.html");
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context).usl,
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
                        _openLink("https://waves-company.github.io/about-wave/faq.html");
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "FAQ",
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
                        _openLink("https://waves-company.github.io/about-wave/wavesafe.html");
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "wavesafe",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Nunito',
                                fontVariations: const [
                                  FontVariation('wdth', 115),
                                  FontVariation('wght', 750),
                                ],
                              ),
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
                    FutureBuilder<String>(
                      future: getVersion(context),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();

                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                snapshot.data!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        );
                      },
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