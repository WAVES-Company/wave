import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/storage/pin_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool isSetup;

  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.isSetup = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeTryBiometrics());
    }
  }

  Future<void> _maybeTryBiometrics() async {
    final enabled = await PinService.isBiometricsEnabled();
    if (enabled) _tryBiometrics();
  }

  Future<void> _tryBiometrics() async {
    final success = await PinService.authenticateWithBiometrics();
    if (success && mounted) widget.onUnlocked();
  }

  void _onKeyTap(String val) {
    setState(() {
      _error = '';
      if (widget.isSetup) {
        if (!_isConfirming) {
          if (_pin.length < 4) _pin += val;
          if (_pin.length == 4) _isConfirming = true;
        } else {
          if (_confirmPin.length < 4) _confirmPin += val;
          if (_confirmPin.length == 4) _checkSetup();
        }
      } else {
        if (_pin.length < 4) _pin += val;
        if (_pin.length == 4) _checkPin();
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (widget.isSetup && _isConfirming) {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _checkPin() async {
    final ok = await PinService.checkPin(_pin);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _pin = '';
        _error = S.of(context).wrongPin;
      });
    }
  }

  Future<void> _checkSetup() async {
    if (_pin == _confirmPin) {
      await PinService.savePin(_pin);
      widget.onUnlocked();
    } else {
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
        _error = S.of(context).pinMismatch;
      });
    }
  }

  Widget _buildDots(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < pin.length ? Colors.blue : Colors.grey.withOpacity(0.4),
        ),
      )),
    );
  }

  Widget _buildKey(String val) {
    return GestureDetector(
      onTap: () => _onKeyTap(val),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.15),
        ),
        child: Center(
          child: Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = widget.isSetup && _isConfirming ? _confirmPin : _pin;
    final title = widget.isSetup
        ? (_isConfirming ? S.of(context).repeatPin : S.of(context).setPin)
        : S.of(context).enterPin;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildDots(currentPin),
            const SizedBox(height: 12),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red, fontSize: 14)),
            const Spacer(),
            for (var row in [['1','2','3'], ['4','5','6'], ['7','8','9']])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map(_buildKey).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!widget.isSetup)
                    GestureDetector(
                      onTap: _tryBiometrics,
                      child: Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.fingerprint, size: 32),
                      ),
                    )
                  else
                    const SizedBox(width: 75),
                  _buildKey('0'),
                  GestureDetector(
                    onTap: _onDelete,
                    child: Container(
                      width: 75, height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.backspace_outlined, size: 28),
                    ),
                  ),
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