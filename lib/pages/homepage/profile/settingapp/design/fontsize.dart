import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/main.dart';
import 'package:wave/storage/secure.dart';

class FontSizePage extends StatefulWidget {
  const FontSizePage({super.key});
  @override
  State<FontSizePage> createState() => _FontSizePageState();
}
  class _FontSizePageState extends State<FontSizePage> {
    bool isBold = false;

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
                S.of(context).rzmrv,
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
                  minHeight: 60,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                padding: const EdgeInsets.only(left: 30, right: 30),
                decoration: BoxDecoration(
                  color:  Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: const Text(
                        "A",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double availableWidth = constraints.maxWidth;
                            const double thumbRadius = 10.0;
                            const double minSize = 12.0, maxSize = 24.0, defaultValue = 16.0;
                            final double trackWidth = availableWidth - 2 * thumbRadius;
                            final double fraction = (defaultValue - minSize) / (maxSize - minSize);
                            final double defaultPosition = thumbRadius + fraction * trackWidth + 2.25;
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ValueListenableBuilder<double>(
                                  valueListenable: textSizeNotifier,
                                  builder: (context, textSize, _) {
                                    return SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: thumbRadius,
                                        ),
                                        overlayShape: const RoundSliderOverlayShape(
                                          overlayRadius: 18,
                                        ),
                                        activeTrackColor: Colors.grey,
                                        inactiveTrackColor: Colors.grey.withOpacity(0.5),
                                        thumbColor: Colors.white.withOpacity(0.9),
                                        overlayColor: Colors.grey.withOpacity(0.2),
                                      ),
                                      child: Slider(
                                        min: minSize,
                                        max: maxSize,
                                        divisions: 12,
                                        value: textSize,
                                        onChanged: (value) {
                                          if ((value - defaultValue).abs() < 1) {
                                            value = defaultValue;
                                          }
                                          textSizeNotifier.value = value;
                                          SecureStorageService.saveTextSize(value);
                                        },
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 7,
                                  left: defaultPosition,
                                  child: Container(
                                    width: 2,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: const Text(
                        "A",
                        style: TextStyle(
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 50,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.only(left: 15, right: 15),
                decoration: BoxDecoration(
                  color:  Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: boldTextNotifier,
                        builder: (context, isBold, _) {
                          return Text(
                            S.of(context).jir,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          );
                        },
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: boldTextNotifier,
                      builder: (context, isBold, _) {
                        return Switch(
                          value: boldTextNotifier.value,
                          onChanged: (value) {
                            boldTextOverrideNotifier.value = true;
                            boldTextNotifier.value = value;
                            SecureStorageService.saveBoldText(value);
                          },
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