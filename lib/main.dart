import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/homepage.dart';
import 'package:wave/pages/homepage/profile/settingapp/notifications.dart';
import 'package:wave/pages/homepage/profile/settingapp/security/pin/lockscreen.dart';
import 'package:wave/services/data_sync_service.dart';
import 'package:wave/storage/pin_service.dart';
import 'package:wave/storage/secure.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, 
    ),
  );
  print('Initializing crypto engine at startup...');
  final bool cryptoInitialized = await CryptoEngine.initLocalKey();

  if (cryptoInitialized) {
    print('Local encryption key (DEK) successfully loaded.');
  } else {
    print('Local key missing (user not authorized)');
  }
  DataSyncService.startInternetListener();

  final String? savedLang = await SecureStorageService.getLanguage();

  if (savedLang != null) {
    localeNotifier.value = Locale(savedLang);
  } else {
    final deviceLocale = PlatformDispatcher.instance.locale;
    
    if (deviceLocale.languageCode == 'ru') {
      localeNotifier.value = const Locale('ru');
    } else {
      localeNotifier.value = const Locale('en');
    }
  }
  final String? savedTheme = await SecureStorageService.getTheme();
  if (savedTheme != null) {
    if (savedTheme == 'light') themeNotifier.value = ThemeMode.light;
    if (savedTheme == 'dark') themeNotifier.value = ThemeMode.dark;
    if (savedTheme == 'system') themeNotifier.value = ThemeMode.system;
  }

  final double? savedSize = await SecureStorageService.getTextSize();
  if (savedSize != null) {
    textSizeNotifier.value = savedSize;
  }

  final bool? savedBold = await SecureStorageService.getBoldText();
  if (savedBold != null) {
    boldTextNotifier.value = savedBold;
    boldTextOverrideNotifier.value = true;
  }
  runApp(const MyApp());
}

final ValueNotifier<bool> isLockedNotifier = ValueNotifier(false);
final ValueNotifier<bool> pinEnabledNotifier = ValueNotifier(false);
DateTime? _backgroundTime;
final ValueNotifier<double> textSizeNotifier = ValueNotifier(16.0);
final ValueNotifier<bool> boldTextNotifier = ValueNotifier(false);
final ValueNotifier<bool> boldTextOverrideNotifier = ValueNotifier(false);
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en')); 
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: boldTextNotifier,
      builder: (context, isBold, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: textSizeNotifier,
                  builder: (context, textSize, _) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      locale: locale,
                      themeMode: mode,
                      theme: ThemeData(
                        useMaterial3: true,
                        brightness: Brightness.light,
                        scaffoldBackgroundColor: Colors.white,
                        cardColor: Colors.white,
                        shadowColor: Colors.black.withOpacity(0.25),
                        colorScheme: const ColorScheme.light(
                          background: Colors.white,
                          surface: Colors.white,
                          primary: Colors.black,
                          onPrimary: Colors.white,
                          secondary: Color(0xFF6E6E6E),
                          onSurface: Colors.black,
                          surfaceVariant: Color(0xFFF5F5F7),
                          onSurfaceVariant: Colors.black,
                        ),
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.white;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.green;
                            }
                            return Colors.grey.shade400;
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.all(Colors.transparent),
                        ),
                      ),
                      darkTheme: ThemeData(
                        useMaterial3: true,
                        brightness: Brightness.dark,
                        scaffoldBackgroundColor: Colors.black,
                        cardColor: const Color(0xFF1E1E1E),
                        shadowColor: Colors.black.withOpacity(0.5),
                        colorScheme: const ColorScheme.dark(
                          background: Colors.black,
                          surface: Colors.black,
                          primary: Colors.white,
                          onPrimary: Colors.black,
                          secondary: Color(0xFFB0B0B0),
                          onSurface: Colors.white,
                          surfaceVariant: Color(0xFF2A2A2A),
                          onSurfaceVariant: Colors.white,
                        ),
                        switchTheme: SwitchThemeData(
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.white;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.green;
                            }
                            return Colors.grey.shade700;
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.all(Colors.transparent),
                        ),
                      ),
                      localizationsDelegates: const [
                        S.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: S.delegate.supportedLocales,
                      builder: (context, child) {
                        final systemBold = MediaQuery.of(context).boldText;
                        if (!boldTextOverrideNotifier.value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (boldTextNotifier.value != systemBold) {
                              boldTextNotifier.value = systemBold;
                            }
                          });
                        }
                        final scaledChild = MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(textSize / 16.0),
                          ),
                          child: child!,
                        );
                        final theme = Theme.of(context);
                        final fontWeight = boldTextNotifier.value ? FontWeight.bold : FontWeight.normal;
                        final newTextTheme = TextTheme(
                          displayLarge:   theme.textTheme.displayLarge?.copyWith(fontWeight: fontWeight),
                          displayMedium:  theme.textTheme.displayMedium?.copyWith(fontWeight: fontWeight),
                          displaySmall:   theme.textTheme.displaySmall?.copyWith(fontWeight: fontWeight),
                          headlineLarge:  theme.textTheme.headlineLarge?.copyWith(fontWeight: fontWeight),
                          headlineMedium: theme.textTheme.headlineMedium?.copyWith(fontWeight: fontWeight),
                          headlineSmall:  theme.textTheme.headlineSmall?.copyWith(fontWeight: fontWeight),
                          titleLarge:     theme.textTheme.titleLarge?.copyWith(fontWeight: fontWeight),
                          titleMedium:    theme.textTheme.titleMedium?.copyWith(fontWeight: fontWeight),
                          titleSmall:     theme.textTheme.titleSmall?.copyWith(fontWeight: fontWeight),
                          bodyLarge:      theme.textTheme.bodyLarge?.copyWith(fontWeight: fontWeight),
                          bodyMedium:     theme.textTheme.bodyMedium?.copyWith(fontWeight: fontWeight),
                          bodySmall:      theme.textTheme.bodySmall?.copyWith(fontWeight: fontWeight),
                          labelLarge:     theme.textTheme.labelLarge?.copyWith(fontWeight: fontWeight),
                          labelMedium:    theme.textTheme.labelMedium?.copyWith(fontWeight: fontWeight),
                          labelSmall:     theme.textTheme.labelSmall?.copyWith(fontWeight: fontWeight),
                        );
                        return Theme(
                          data: theme.copyWith(textTheme: newTextTheme),
                          child: _AppLock(child: scaledChild),
                        );
                      },
                      home: const Homepage(),
                    );
                  }, 
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AppLock extends StatefulWidget {
  final Widget child;
  const _AppLock({required this.child});
  @override
  State<_AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<_AppLock> with WidgetsBindingObserver {
  static const _secureChannel = MethodChannel('wave/secure_flag');

  bool _locked = false;
  bool _pinEnabled = false;
  bool _initialized = false;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    pinEnabledNotifier.addListener(_onPinEnabledChanged);
  }

  void _onPinEnabledChanged() {
    setState(() => _pinEnabled = pinEnabledNotifier.value);
    _syncSecureFlag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pinEnabledNotifier.removeListener(_onPinEnabledChanged);
    super.dispose();
  }

  Future<void> _init() async {
    final enabled = await PinService.isPinEnabled();
    pinEnabledNotifier.value = enabled;
    setState(() {
      _pinEnabled = enabled;
      _locked = enabled;
      _initialized = true;
    });
    _syncSecureFlag();
  }

  Future<void> _syncSecureFlag() async {
    try {
      await _secureChannel.invokeMethod('setSecure', _pinEnabled);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundTime ??= DateTime.now();
        if (_pinEnabled && !_obscured) {
          setState(() => _obscured = true);
        }
        break;
      case AppLifecycleState.resumed:
        _handleResume();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _handleResume() async {
    final bgTime = _backgroundTime;
    _backgroundTime = null;

    if (_pinEnabled && bgTime != null) {
      final autoLock = await PinService.getAutoLockDuration();
      final diff = DateTime.now().difference(bgTime);
      if (diff >= autoLock.duration) {
        if (mounted) setState(() => _locked = true);
      }
    }
    if (mounted) setState(() => _obscured = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox();
    if (_locked) {
      return LockScreen(
        onUnlocked: () => setState(() {
          _locked = false;
          _obscured = false;
        }),
      );
    }
    return Stack(
      children: [
        widget.child,
        if (_obscured)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }
}

// this code was written by maksy