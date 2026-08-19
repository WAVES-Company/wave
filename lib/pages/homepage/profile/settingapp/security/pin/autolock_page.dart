import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/storage/pin_service.dart';

class AutoLockPage extends StatefulWidget {
  final AutoLockDuration initialValue;

  const AutoLockPage({super.key, required this.initialValue});

  @override
  State<AutoLockPage> createState() => _AutoLockPageState();
}

class _AutoLockPageState extends State<AutoLockPage> {
  late AutoLockDuration _selected = widget.initialValue;

  String _label(AutoLockDuration value) {
    switch (value) {
      case AutoLockDuration.instant:
        return S.of(context).autoLockInstant;
      case AutoLockDuration.oneMinute:
        return S.of(context).autoLockOneMinute;
      case AutoLockDuration.fiveMinutes:
        return S.of(context).autoLockFiveMinutes;
      case AutoLockDuration.oneHour:
        return S.of(context).autoLockOneHour;
      case AutoLockDuration.fiveHours:
        return S.of(context).autoLockFiveHours;
    }
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(34),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor,
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
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
                S.of(context).autoLock,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 80),
            Container(
              constraints: const BoxConstraints(
                minHeight: 50,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: _cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final value in AutoLockDuration.values) ...[
                    if (value != AutoLockDuration.values.first) ...[
                      Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
                    ],
                    GestureDetector(
                      onTap: () {
                        setState(() => _selected = value);
                        Navigator.of(context).pop(value);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _label(value),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            if (_selected == value)
                              Icon(
                                Icons.check,
                                size: 20
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// this code was written by maksy