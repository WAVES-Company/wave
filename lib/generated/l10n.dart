// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `My Goals`
  String get goals {
    return Intl.message('My Goals', name: 'goals', desc: '', args: []);
  }

  /// `Your goals will be here`
  String get hr {
    return Intl.message(
      'Your goals will be here',
      name: 'hr',
      desc: '',
      args: [],
    );
  }

  /// `Goals`
  String get pn1 {
    return Intl.message('Goals', name: 'pn1', desc: '', args: []);
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `App settings`
  String get sttapp {
    return Intl.message('App settings', name: 'sttapp', desc: '', args: []);
  }

  /// `Help`
  String get hlp {
    return Intl.message('Help', name: 'hlp', desc: '', args: []);
  }

  /// `Profile photo`
  String get ptpr {
    return Intl.message('Profile photo', name: 'ptpr', desc: '', args: []);
  }

  /// `What's your name?`
  String get yrnm {
    return Intl.message('What\'s your name?', name: 'yrnm', desc: '', args: []);
  }

  /// `Your username`
  String get eml {
    return Intl.message('Your username', name: 'eml', desc: '', args: []);
  }

  /// `Delete account`
  String get dlt {
    return Intl.message('Delete account', name: 'dlt', desc: '', args: []);
  }

  /// `Enter name`
  String get vdtyrnm {
    return Intl.message('Enter name', name: 'vdtyrnm', desc: '', args: []);
  }

  /// `Enter your username`
  String get vdteml {
    return Intl.message(
      'Enter your username',
      name: 'vdteml',
      desc: '',
      args: [],
    );
  }

  /// `No name`
  String get nnm {
    return Intl.message('No name', name: 'nnm', desc: '', args: []);
  }

  /// `No username`
  String get nml {
    return Intl.message('No username', name: 'nml', desc: '', args: []);
  }

  /// `Edit`
  String get rdkt {
    return Intl.message('Edit', name: 'rdkt', desc: '', args: []);
  }

  /// `Ask a question\nand we will answer\nas soon as possible`
  String get zadvop {
    return Intl.message(
      'Ask a question\nand we will answer\nas soon as possible',
      name: 'zadvop',
      desc: '',
      args: [],
    );
  }

  /// `Choose the option\nby which\nyou will contact us`
  String get msngr {
    return Intl.message(
      'Choose the option\nby which\nyou will contact us',
      name: 'msngr',
      desc: '',
      args: [],
    );
  }

  /// `In case of problems with the internet and requests,\nor with a very large number of requests,\nthe answer to your question\nmay take from 5 to 30 days or more.`
  String get intrnt {
    return Intl.message(
      'In case of problems with the internet and requests,\nor with a very large number of requests,\nthe answer to your question\nmay take from 5 to 30 days or more.',
      name: 'intrnt',
      desc: '',
      args: [],
    );
  }

  /// `Customize the app`
  String get nstrt {
    return Intl.message('Customize the app', name: 'nstrt', desc: '', args: []);
  }

  /// `for yourself`
  String get pdcb {
    return Intl.message('for yourself', name: 'pdcb', desc: '', args: []);
  }

  /// `Design`
  String get ofrv {
    return Intl.message('Design', name: 'ofrv', desc: '', args: []);
  }

  /// `Notifications`
  String get uvedv {
    return Intl.message('Notifications', name: 'uvedv', desc: '', args: []);
  }

  /// `Security`
  String get bezv {
    return Intl.message('Security', name: 'bezv', desc: '', args: []);
  }

  /// `About the app`
  String get prilv {
    return Intl.message('About the app', name: 'prilv', desc: '', args: []);
  }

  /// `Email`
  String get pcht {
    return Intl.message('Email', name: 'pcht', desc: '', args: []);
  }

  /// `waveofgoals@hotmail.com`
  String get supportEmail {
    return Intl.message(
      'waveofgoals@hotmail.com',
      name: 'supportEmail',
      desc: '',
      args: [],
    );
  }

  /// `Hello,`
  String get emailBody {
    return Intl.message('Hello,', name: 'emailBody', desc: '', args: []);
  }

  /// `Telegram channel wave`
  String get tgw {
    return Intl.message(
      'Telegram channel wave',
      name: 'tgw',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get pltknf {
    return Intl.message('Privacy Policy', name: 'pltknf', desc: '', args: []);
  }

  /// `Terms of Service`
  String get usl {
    return Intl.message('Terms of Service', name: 'usl', desc: '', args: []);
  }

  /// `Version {version}`
  String ver(Object version) {
    return Intl.message(
      'Version $version',
      name: 'ver',
      desc: '',
      args: [version],
    );
  }

  /// `Language`
  String get lngv {
    return Intl.message('Language', name: 'lngv', desc: '', args: []);
  }

  /// `App theme`
  String get tmv {
    return Intl.message('App theme', name: 'tmv', desc: '', args: []);
  }

  /// `Text size`
  String get rzmrv {
    return Intl.message('Text size', name: 'rzmrv', desc: '', args: []);
  }

  /// `App icon`
  String get ikn {
    return Intl.message('App icon', name: 'ikn', desc: '', args: []);
  }

  /// `Russian`
  String get rus {
    return Intl.message('Russian', name: 'rus', desc: '', args: []);
  }

  /// `English`
  String get en {
    return Intl.message('English', name: 'en', desc: '', args: []);
  }

  /// `System`
  String get s {
    return Intl.message('System', name: 's', desc: '', args: []);
  }

  /// `White`
  String get w {
    return Intl.message('White', name: 'w', desc: '', args: []);
  }

  /// `Dark`
  String get d {
    return Intl.message('Dark', name: 'd', desc: '', args: []);
  }

  /// `Bold Text`
  String get jir {
    return Intl.message('Bold Text', name: 'jir', desc: '', args: []);
  }

  /// `Password`
  String get prl {
    return Intl.message('Password', name: 'prl', desc: '', args: []);
  }

  /// `Passcode Lock`
  String get kod {
    return Intl.message('Passcode Lock', name: 'kod', desc: '', args: []);
  }

  /// `Passkeys`
  String get key {
    return Intl.message('Passkeys', name: 'key', desc: '', args: []);
  }

  /// `What is this? This is our proprietary ws1.0 encryption system, protecting your personal data from prying eyes.`
  String get ws {
    return Intl.message(
      'What is this? This is our proprietary ws1.0 encryption system, protecting your personal data from prying eyes.',
      name: 'ws',
      desc: '',
      args: [],
    );
  }

  /// `For more information click here`
  String get pdrbn {
    return Intl.message(
      'For more information click here',
      name: 'pdrbn',
      desc: '',
      args: [],
    );
  }

  /// `Sound`
  String get zv {
    return Intl.message('Sound', name: 'zv', desc: '', args: []);
  }

  /// `Vibration`
  String get vib {
    return Intl.message('Vibration', name: 'vib', desc: '', args: []);
  }

  /// `Show text`
  String get tx {
    return Intl.message('Show text', name: 'tx', desc: '', args: []);
  }

  /// `Select a goal type`
  String get tpcl {
    return Intl.message('Select a goal type', name: 'tpcl', desc: '', args: []);
  }

  /// `click the desired option`
  String get ng {
    return Intl.message(
      'click the desired option',
      name: 'ng',
      desc: '',
      args: [],
    );
  }

  /// `Regular goal`
  String get ob {
    return Intl.message('Regular goal', name: 'ob', desc: '', args: []);
  }

  /// `Money goal`
  String get den {
    return Intl.message('Money goal', name: 'den', desc: '', args: []);
  }

  /// `Continue`
  String get pro {
    return Intl.message('Continue', name: 'pro', desc: '', args: []);
  }

  /// `How much do you want to save?`
  String get clol {
    return Intl.message(
      'How much do you want to save?',
      name: 'clol',
      desc: '',
      args: [],
    );
  }

  /// `How much have you already accumulated?`
  String get ckolnak {
    return Intl.message(
      'How much have you already accumulated?',
      name: 'ckolnak',
      desc: '',
      args: [],
    );
  }

  /// `enter the amount`
  String get vps {
    return Intl.message('enter the amount', name: 'vps', desc: '', args: []);
  }

  /// `Enter the amount`
  String get vvedsum {
    return Intl.message(
      'Enter the amount',
      name: 'vvedsum',
      desc: '',
      args: [],
    );
  }

  /// `Enter the amount and click '$'\nto select the currency`
  String get vpsum {
    return Intl.message(
      'Enter the amount and click \'\$\'\nto select the currency',
      name: 'vpsum',
      desc: '',
      args: [],
    );
  }

  /// `Select the date`
  String get vbdt {
    return Intl.message('Select the date', name: 'vbdt', desc: '', args: []);
  }

  /// `until which you want to save`
  String get dkhk {
    return Intl.message(
      'until which you want to save',
      name: 'dkhk',
      desc: '',
      args: [],
    );
  }

  /// `Goal created!`
  String get md {
    return Intl.message('Goal created!', name: 'md', desc: '', args: []);
  }

  /// `Do you want to create another one?`
  String get wnt {
    return Intl.message(
      'Do you want to create another one?',
      name: 'wnt',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Enter your goal name`
  String get naz {
    return Intl.message(
      'Enter your goal name',
      name: 'naz',
      desc: '',
      args: [],
    );
  }

  /// `enter in the field below`
  String get vvpv {
    return Intl.message(
      'enter in the field below',
      name: 'vvpv',
      desc: '',
      args: [],
    );
  }

  /// `Select an emoji`
  String get em {
    return Intl.message('Select an emoji', name: 'em', desc: '', args: []);
  }

  /// `which will appear next to the name`
  String get kbrsn {
    return Intl.message(
      'which will appear next to the name',
      name: 'kbrsn',
      desc: '',
      args: [],
    );
  }

  /// `Enter name`
  String get vdnz {
    return Intl.message('Enter name', name: 'vdnz', desc: '', args: []);
  }

  /// `Your emoji goes here`
  String get zbve {
    return Intl.message(
      'Your emoji goes here',
      name: 'zbve',
      desc: '',
      args: [],
    );
  }

  /// `Click to select`
  String get nhv {
    return Intl.message('Click to select', name: 'nhv', desc: '', args: []);
  }

  /// ` Until `
  String get dd {
    return Intl.message(' Until ', name: 'dd', desc: '', args: []);
  }

  /// `Tasks`
  String get zad {
    return Intl.message('Tasks', name: 'zad', desc: '', args: []);
  }

  /// `Add task`
  String get dob {
    return Intl.message('Add task', name: 'dob', desc: '', args: []);
  }

  /// `No tasks`
  String get nz {
    return Intl.message('No tasks', name: 'nz', desc: '', args: []);
  }

  /// `Add the first task\nfor your goal`
  String get dobpz {
    return Intl.message(
      'Add the first task\nfor your goal',
      name: 'dobpz',
      desc: '',
      args: [],
    );
  }

  /// `Delete task?`
  String get udlz {
    return Intl.message('Delete task?', name: 'udlz', desc: '', args: []);
  }

  /// `Cancel`
  String get ot {
    return Intl.message('Cancel', name: 'ot', desc: '', args: []);
  }

  /// `Delete`
  String get udalit {
    return Intl.message('Delete', name: 'udalit', desc: '', args: []);
  }

  /// `New task`
  String get nvzad {
    return Intl.message('New task', name: 'nvzad', desc: '', args: []);
  }

  /// `Task Name`
  String get nzzad {
    return Intl.message('Task Name', name: 'nzzad', desc: '', args: []);
  }

  /// `Select a time`
  String get vvnap {
    return Intl.message('Select a time', name: 'vvnap', desc: '', args: []);
  }

  /// `Add`
  String get db {
    return Intl.message('Add', name: 'db', desc: '', args: []);
  }

  /// `An error occurred. Please try again later`
  String get err {
    return Intl.message(
      'An error occurred. Please try again later',
      name: 'err',
      desc: '',
      args: [],
    );
  }

  /// `Task added`
  String get add {
    return Intl.message('Task added', name: 'add', desc: '', args: []);
  }

  /// `Task deleted`
  String get delete {
    return Intl.message('Task deleted', name: 'delete', desc: '', args: []);
  }

  /// `Today at`
  String get tdy {
    return Intl.message('Today at', name: 'tdy', desc: '', args: []);
  }

  /// `Tomorrow at`
  String get tmrw {
    return Intl.message('Tomorrow at', name: 'tmrw', desc: '', args: []);
  }

  /// `No reminder`
  String get bznp {
    return Intl.message('No reminder', name: 'bznp', desc: '', args: []);
  }

  /// `Accumulate`
  String get nak {
    return Intl.message('Accumulate', name: 'nak', desc: '', args: []);
  }

  /// `Add`
  String get pop {
    return Intl.message('Add', name: 'pop', desc: '', args: []);
  }

  /// `Withdraw`
  String get otnt {
    return Intl.message('Withdraw', name: 'otnt', desc: '', args: []);
  }

  /// `Replenishment history`
  String get istr {
    return Intl.message(
      'Replenishment history',
      name: 'istr',
      desc: '',
      args: [],
    );
  }

  /// `No top-ups`
  String get netpop {
    return Intl.message('No top-ups', name: 'netpop', desc: '', args: []);
  }

  /// `Today`
  String get seg {
    return Intl.message('Today', name: 'seg', desc: '', args: []);
  }

  /// `Yesterday`
  String get vhr {
    return Intl.message('Yesterday', name: 'vhr', desc: '', args: []);
  }

  /// `Jan`
  String get jan {
    return Intl.message('Jan', name: 'jan', desc: '', args: []);
  }

  /// `Feb`
  String get feb {
    return Intl.message('Feb', name: 'feb', desc: '', args: []);
  }

  /// `Mar`
  String get mar {
    return Intl.message('Mar', name: 'mar', desc: '', args: []);
  }

  /// `Apr`
  String get apr {
    return Intl.message('Apr', name: 'apr', desc: '', args: []);
  }

  /// `May`
  String get may {
    return Intl.message('May', name: 'may', desc: '', args: []);
  }

  /// `Jun`
  String get jun {
    return Intl.message('Jun', name: 'jun', desc: '', args: []);
  }

  /// `Jul`
  String get jul {
    return Intl.message('Jul', name: 'jul', desc: '', args: []);
  }

  /// `Aug`
  String get aug {
    return Intl.message('Aug', name: 'aug', desc: '', args: []);
  }

  /// `Sep`
  String get sep {
    return Intl.message('Sep', name: 'sep', desc: '', args: []);
  }

  /// `Oct`
  String get oct {
    return Intl.message('Oct', name: 'oct', desc: '', args: []);
  }

  /// `Nov`
  String get nov {
    return Intl.message('Nov', name: 'nov', desc: '', args: []);
  }

  /// `Dec`
  String get dec {
    return Intl.message('Dec', name: 'dec', desc: '', args: []);
  }

  /// `Allow notifications in system settings`
  String get razuved {
    return Intl.message(
      'Allow notifications in system settings',
      name: 'razuved',
      desc: '',
      args: [],
    );
  }

  /// `Reminders`
  String get nap {
    return Intl.message('Reminders', name: 'nap', desc: '', args: []);
  }

  /// `Task Notifications`
  String get uvedozad {
    return Intl.message(
      'Task Notifications',
      name: 'uvedozad',
      desc: '',
      args: [],
    );
  }

  /// `Reminder`
  String get srttkst {
    return Intl.message('Reminder', name: 'srttkst', desc: '', args: []);
  }

  /// `Task reminder`
  String get napozad {
    return Intl.message('Task reminder', name: 'napozad', desc: '', args: []);
  }

  /// `Skip`
  String get skip {
    return Intl.message('Skip', name: 'skip', desc: '', args: []);
  }

  /// `Enter a value`
  String get vvedznach {
    return Intl.message('Enter a value', name: 'vvedznach', desc: '', args: []);
  }

  /// `Saved more than needed`
  String get nakbols {
    return Intl.message(
      'Saved more than needed',
      name: 'nakbols',
      desc: '',
      args: [],
    );
  }

  /// `Unpin`
  String get otkrp {
    return Intl.message('Unpin', name: 'otkrp', desc: '', args: []);
  }

  /// `Pin`
  String get zakrp {
    return Intl.message('Pin', name: 'zakrp', desc: '', args: []);
  }

  /// `Edit`
  String get izmen {
    return Intl.message('Edit', name: 'izmen', desc: '', args: []);
  }

  /// `Share`
  String get pod {
    return Intl.message('Share', name: 'pod', desc: '', args: []);
  }

  /// `🎯 Goal:`
  String get sg {
    return Intl.message('🎯 Goal:', name: 'sg', desc: '', args: []);
  }

  /// `📈 Progress:`
  String get sp {
    return Intl.message('📈 Progress:', name: 'sp', desc: '', args: []);
  }

  /// `📅 Deadline:`
  String get sd {
    return Intl.message('📅 Deadline:', name: 'sd', desc: '', args: []);
  }

  /// `💰 Goal to accumulate`
  String get smg {
    return Intl.message(
      '💰 Goal to accumulate',
      name: 'smg',
      desc: '',
      args: [],
    );
  }

  /// `💵 Already accumulated`
  String get sumg {
    return Intl.message(
      '💵 Already accumulated',
      name: 'sumg',
      desc: '',
      args: [],
    );
  }

  /// `Verify identity`
  String get pdtlic {
    return Intl.message('Verify identity', name: 'pdtlic', desc: '', args: []);
  }

  /// `Turn On Passcode`
  String get turnOnPasscode {
    return Intl.message(
      'Turn On Passcode',
      name: 'turnOnPasscode',
      desc: '',
      args: [],
    );
  }

  /// `Turn Off Passcode`
  String get turnOffPasscode {
    return Intl.message(
      'Turn Off Passcode',
      name: 'turnOffPasscode',
      desc: '',
      args: [],
    );
  }

  /// `Change Passcode`
  String get changePasscode {
    return Intl.message(
      'Change Passcode',
      name: 'changePasscode',
      desc: '',
      args: [],
    );
  }

  /// `Auto-Lock`
  String get autoLock {
    return Intl.message('Auto-Lock', name: 'autoLock', desc: '', args: []);
  }

  /// `Immediately`
  String get autoLockInstant {
    return Intl.message(
      'Immediately',
      name: 'autoLockInstant',
      desc: '',
      args: [],
    );
  }

  /// `After 1 minute`
  String get autoLockOneMinute {
    return Intl.message(
      'After 1 minute',
      name: 'autoLockOneMinute',
      desc: '',
      args: [],
    );
  }

  /// `After 5 minutes`
  String get autoLockFiveMinutes {
    return Intl.message(
      'After 5 minutes',
      name: 'autoLockFiveMinutes',
      desc: '',
      args: [],
    );
  }

  /// `After 1 hour`
  String get autoLockOneHour {
    return Intl.message(
      'After 1 hour',
      name: 'autoLockOneHour',
      desc: '',
      args: [],
    );
  }

  /// `After 5 hours`
  String get autoLockFiveHours {
    return Intl.message(
      'After 5 hours',
      name: 'autoLockFiveHours',
      desc: '',
      args: [],
    );
  }

  /// `Touch ID / Face ID`
  String get useBiometrics {
    return Intl.message(
      'Touch ID / Face ID',
      name: 'useBiometrics',
      desc: '',
      args: [],
    );
  }

  /// `Turn Off Passcode?`
  String get turnOffPasscodeTitle {
    return Intl.message(
      'Turn Off Passcode?',
      name: 'turnOffPasscodeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to turn off the passcode? This will reduce the app's security.`
  String get turnOffPasscodeMessage {
    return Intl.message(
      'Are you sure you want to turn off the passcode? This will reduce the app\'s security.',
      name: 'turnOffPasscodeMessage',
      desc: '',
      args: [],
    );
  }

  /// `Enable Biometrics?`
  String get enableBiometricsTitle {
    return Intl.message(
      'Enable Biometrics?',
      name: 'enableBiometricsTitle',
      desc: '',
      args: [],
    );
  }

  /// `You can use Touch ID or Face ID instead of entering your passcode.`
  String get enableBiometricsMessage {
    return Intl.message(
      'You can use Touch ID or Face ID instead of entering your passcode.',
      name: 'enableBiometricsMessage',
      desc: '',
      args: [],
    );
  }

  /// `Turn Off`
  String get turnOff {
    return Intl.message('Turn Off', name: 'turnOff', desc: '', args: []);
  }

  /// `Not Now`
  String get notNow {
    return Intl.message('Not Now', name: 'notNow', desc: '', args: []);
  }

  /// `Enable`
  String get enable {
    return Intl.message('Enable', name: 'enable', desc: '', args: []);
  }

  /// `Wrong PIN`
  String get wrongPin {
    return Intl.message('Wrong PIN', name: 'wrongPin', desc: '', args: []);
  }

  /// `PINs don't match, try again`
  String get pinMismatch {
    return Intl.message(
      'PINs don\'t match, try again',
      name: 'pinMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Set PIN`
  String get setPin {
    return Intl.message('Set PIN', name: 'setPin', desc: '', args: []);
  }

  /// `Repeat PIN`
  String get repeatPin {
    return Intl.message('Repeat PIN', name: 'repeatPin', desc: '', args: []);
  }

  /// `Enter PIN`
  String get enterPin {
    return Intl.message('Enter PIN', name: 'enterPin', desc: '', args: []);
  }

  /// `*A username is a unique, easy-to-remember name used instead of an email address.`
  String get usrname {
    return Intl.message(
      '*A username is a unique, easy-to-remember name used instead of an email address.',
      name: 'usrname',
      desc: '',
      args: [],
    );
  }

  /// `Registration successful!`
  String get uspeshnreg {
    return Intl.message(
      'Registration successful!',
      name: 'uspeshnreg',
      desc: '',
      args: [],
    );
  }

  /// `Registration`
  String get reg {
    return Intl.message('Registration', name: 'reg', desc: '', args: []);
  }

  /// `Log in to your account`
  String get voivsv {
    return Intl.message(
      'Log in to your account',
      name: 'voivsv',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Username`
  String get usrnm {
    return Intl.message('Username', name: 'usrnm', desc: '', args: []);
  }

  /// `The @ symbol is not required`
  String get ntreb {
    return Intl.message(
      'The @ symbol is not required',
      name: 'ntreb',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 6 characters long`
  String get prlot {
    return Intl.message(
      'Password must be at least 6 characters long',
      name: 'prlot',
      desc: '',
      args: [],
    );
  }

  /// `Create account`
  String get creat {
    return Intl.message('Create account', name: 'creat', desc: '', args: []);
  }

  /// `Log in`
  String get vti {
    return Intl.message('Log in', name: 'vti', desc: '', args: []);
  }

  /// `Already have an account?\nClick to log in`
  String get uject {
    return Intl.message(
      'Already have an account?\nClick to log in',
      name: 'uject',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?\nClick to create one`
  String get netsoz {
    return Intl.message(
      'Don\'t have an account?\nClick to create one',
      name: 'netsoz',
      desc: '',
      args: [],
    );
  }

  /// `Log out`
  String get viti {
    return Intl.message('Log out', name: 'viti', desc: '', args: []);
  }

  /// `If you confirm this action, all your data will be deleted.`
  String get potverudal {
    return Intl.message(
      'If you confirm this action, all your data will be deleted.',
      name: 'potverudal',
      desc: '',
      args: [],
    );
  }

  /// `If you confirm this action, you will log out of this account. The account will not be deleted, and no data will be lost.`
  String get potverviti {
    return Intl.message(
      'If you confirm this action, you will log out of this account. The account will not be deleted, and no data will be lost.',
      name: 'potverviti',
      desc: '',
      args: [],
    );
  }

  /// `This username is already taken, please choose another one!`
  String get zan {
    return Intl.message(
      'This username is already taken, please choose another one!',
      name: 'zan',
      desc: '',
      args: [],
    );
  }

  /// `Data protected`
  String get danzah {
    return Intl.message('Data protected', name: 'danzah', desc: '', args: []);
  }

  /// `All your data is protected by ws1.0 end-to-end encryption.\n\nEncryption takes place locally on your device before transmission to the cloud. The wave server sees only a random string of characters.`
  String get opiszah {
    return Intl.message(
      'All your data is protected by ws1.0 end-to-end encryption.\n\nEncryption takes place locally on your device before transmission to the cloud. The wave server sees only a random string of characters.',
      name: 'opiszah',
      desc: '',
      args: [],
    );
  }

  /// `Current password`
  String get tekprl {
    return Intl.message('Current password', name: 'tekprl', desc: '', args: []);
  }

  /// `New password`
  String get novprl {
    return Intl.message('New password', name: 'novprl', desc: '', args: []);
  }

  /// `The new password must not match the old one`
  String get ndlsvsstr {
    return Intl.message(
      'The new password must not match the old one',
      name: 'ndlsvsstr',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get smen {
    return Intl.message('Change', name: 'smen', desc: '', args: []);
  }

  /// `User not found`
  String get polnn {
    return Intl.message('User not found', name: 'polnn', desc: '', args: []);
  }

  /// `Incorrect password`
  String get nevprl {
    return Intl.message(
      'Incorrect password',
      name: 'nevprl',
      desc: '',
      args: [],
    );
  }

  /// `Write down your username and password; \nif you lose this information, you will \nnot be able to access your account.`
  String get pred1 {
    return Intl.message(
      'Write down your username and password; \nif you lose this information, you will \nnot be able to access your account.',
      name: 'pred1',
      desc: '',
      args: [],
    );
  }

  /// `Have you written down your \nusername and password?`
  String get pred2 {
    return Intl.message(
      'Have you written down your \nusername and password?',
      name: 'pred2',
      desc: '',
      args: [],
    );
  }

  /// `If you lose your username, password, or both, you will not be able to log back into your account or recover your data; therefore, we recommend writing down your password and username to avoid losing access. By clicking the button, you confirm that you accept responsibility for safeguarding your data and ensuring you can access it at any time.`
  String get pred3 {
    return Intl.message(
      'If you lose your username, password, or both, you will not be able to log back into your account or recover your data; therefore, we recommend writing down your password and username to avoid losing access. By clicking the button, you confirm that you accept responsibility for safeguarding your data and ensuring you can access it at any time.',
      name: 'pred3',
      desc: '',
      args: [],
    );
  }

  /// `Yes, I have written it down`
  String get yesido {
    return Intl.message(
      'Yes, I have written it down',
      name: 'yesido',
      desc: '',
      args: [],
    );
  }

  /// `Attention!`
  String get permIntroTitle {
    return Intl.message(
      'Attention!',
      name: 'permIntroTitle',
      desc: '',
      args: [],
    );
  }

  /// `The system is about to ask you for three permissions. They're needed so that task reminders arrive on time and work correctly.`
  String get permIntroDesc {
    return Intl.message(
      'The system is about to ask you for three permissions. They\'re needed so that task reminders arrive on time and work correctly.',
      name: 'permIntroDesc',
      desc: '',
      args: [],
    );
  }

  /// `Notification permission — so you can receive reminders.`
  String get permIntroNotif {
    return Intl.message(
      'Notification permission — so you can receive reminders.',
      name: 'permIntroNotif',
      desc: '',
      args: [],
    );
  }

  /// `Exact reminders permission — so notifications arrive exactly when you set them.`
  String get permIntroAlarm {
    return Intl.message(
      'Exact reminders permission — so notifications arrive exactly when you set them.',
      name: 'permIntroAlarm',
      desc: '',
      args: [],
    );
  }

  /// `Background activity permission — on some devices, reminders may not work without this.`
  String get permIntroBattery {
    return Intl.message(
      'Background activity permission — on some devices, reminders may not work without this.',
      name: 'permIntroBattery',
      desc: '',
      args: [],
    );
  }

  /// `We don't use these permissions for anything bad — they're only needed for reminders to work properly.`
  String get permIntroFooter {
    return Intl.message(
      'We don\'t use these permissions for anything bad — they\'re only needed for reminders to work properly.',
      name: 'permIntroFooter',
      desc: '',
      args: [],
    );
  }

  /// `Got it`
  String get permIntroOk {
    return Intl.message('Got it', name: 'permIntroOk', desc: '', args: []);
  }

  /// `Planner`
  String get planner {
    return Intl.message('Planner', name: 'planner', desc: '', args: []);
  }

  /// `Priority`
  String get importance {
    return Intl.message('Priority', name: 'importance', desc: '', args: []);
  }

  /// `High`
  String get high {
    return Intl.message('High', name: 'high', desc: '', args: []);
  }

  /// `Medium`
  String get medium {
    return Intl.message('Medium', name: 'medium', desc: '', args: []);
  }

  /// `Low`
  String get low {
    return Intl.message('Low', name: 'low', desc: '', args: []);
  }

  /// `Tomorrow`
  String get tomorrow {
    return Intl.message('Tomorrow', name: 'tomorrow', desc: '', args: []);
  }

  /// `Select date and time`
  String get selectTime {
    return Intl.message(
      'Select date and time',
      name: 'selectTime',
      desc: '',
      args: [],
    );
  }

  /// `Select priority`
  String get selectImportance {
    return Intl.message(
      'Select priority',
      name: 'selectImportance',
      desc: '',
      args: [],
    );
  }

  /// `Leave empty if there is no priority`
  String get noImportanceHint {
    return Intl.message(
      'Leave empty if there is no priority',
      name: 'noImportanceHint',
      desc: '',
      args: [],
    );
  }

  /// `No tasks this week`
  String get noTasks {
    return Intl.message(
      'No tasks this week',
      name: 'noTasks',
      desc: '',
      args: [],
    );
  }

  /// `Task: `
  String get zadach {
    return Intl.message('Task: ', name: 'zadach', desc: '', args: []);
  }

  /// `Date: `
  String get dat {
    return Intl.message('Date: ', name: 'dat', desc: '', args: []);
  }

  /// `Time: `
  String get vrem {
    return Intl.message('Time: ', name: 'vrem', desc: '', args: []);
  }

  /// `Past days`
  String get prochl {
    return Intl.message('Past days', name: 'prochl', desc: '', args: []);
  }

  /// `Edit task`
  String get izmenzad {
    return Intl.message('Edit task', name: 'izmenzad', desc: '', args: []);
  }

  /// `Save`
  String get sox {
    return Intl.message('Save', name: 'sox', desc: '', args: []);
  }

  /// `Duplicate`
  String get dup {
    return Intl.message('Duplicate', name: 'dup', desc: '', args: []);
  }

  /// `Duplicate to next day`
  String get duptond {
    return Intl.message(
      'Duplicate to next day',
      name: 'duptond',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
