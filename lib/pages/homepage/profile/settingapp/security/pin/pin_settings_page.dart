import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/main.dart';
import 'package:wave/pages/homepage/profile/settingapp/security/pin/lockscreen.dart';
import 'package:wave/pages/homepage/profile/settingapp/security/pin/autolock_page.dart';
import 'package:wave/storage/pin_service.dart';

class PinSettingsPage extends StatefulWidget {
  const PinSettingsPage({super.key});

  @override
  State<PinSettingsPage> createState() => _PinSettingsPageState();
}

class _PinSettingsPageState extends State<PinSettingsPage> {
  bool _loading = true;
  bool _pinEnabled = false;
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  AutoLockDuration _autoLock = AutoLockDuration.oneMinute;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pinEnabled = await PinService.isPinEnabled();
    final bioAvailable = await PinService.isBiometricsAvailable();
    final bioEnabled = await PinService.isBiometricsEnabled();
    final autoLock = await PinService.getAutoLockDuration();
    if (!mounted) return;
    setState(() {
      _pinEnabled = pinEnabled;
      _biometricsAvailable = bioAvailable;
      _biometricsEnabled = bioEnabled;
      _autoLock = autoLock;
      _loading = false;
    });
    pinEnabledNotifier.value = pinEnabled;
  }

  Future<void> _openSetup() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LockScreen(
          isSetup: true,
          onUnlocked: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (result == true) {
      await _load();
      if (_biometricsAvailable && mounted) {
        _offerBiometrics();
      }
    }
  }

  Future<void> _disablePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).turnOffPasscodeTitle),
        content: Text(S.of(context).turnOffPasscodeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              S.of(context).ot,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.of(context).turnOff,
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PinService.removePin();
      await _load();
    }
  }

  Future<void> _offerBiometrics() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).enableBiometricsTitle),
        content: Text(S.of(context).enableBiometricsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              S.of(context).notNow,
              style: TextStyle(
                color: Theme.of(context).brightness ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.of(context).enable,
              style: TextStyle(
                color: Theme.of(context).brightness ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PinService.setBiometricsEnabled(true);
      if (mounted) setState(() => _biometricsEnabled = true);
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final ok = await PinService.authenticateWithBiometrics();
      if (!ok) return;
    }
    await PinService.setBiometricsEnabled(value);
    setState(() => _biometricsEnabled = value);
  }

  String _autoLockLabel(AutoLockDuration value) {
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

  Future<void> _openAutoLock() async {
    final result = await Navigator.of(context).push<AutoLockDuration>(
      MaterialPageRoute(
        builder: (_) => AutoLockPage(initialValue: _autoLock),
      ),
    );
    if (result != null) {
      await PinService.setAutoLockDuration(result);
      setState(() => _autoLock = result);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Text(
                      S.of(context).kod,
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
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_pinEnabled) ...[
                          GestureDetector(
                            onTap: _disablePin,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    S.of(context).turnOffPasscode,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _openSetup,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    S.of(context).changePasscode,
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          GestureDetector(
                            onTap: _openSetup,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    S.of(context).turnOnPasscode,
                                    style: TextStyle(
                                      fontSize: 18,

                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_pinEnabled) ...[
                    const SizedBox(height: 20),

                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 50,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.only(left: 15,right: 5),
                      decoration: _cardDecoration(context),
                      child: GestureDetector(
                        onTap: _openAutoLock,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                S.of(context).autoLock,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            Text(
                              _autoLockLabel(_autoLock),
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 110, 110, 110),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_biometricsAvailable) ...[
                      const SizedBox(height: 20),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 50,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: _cardDecoration(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                S.of(context).useBiometrics,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            Switch(
                              value: _biometricsEnabled,
                              onChanged: _toggleBiometrics,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

// this code was written by maksy