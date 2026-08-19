import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:cryptography/cryptography.dart';
import 'package:wave/storage/model/goal_model.dart';
import 'package:wave/storage/model/money_goal_model.dart';
import 'package:wave/storage/model/money_history_goal_model.dart';
import 'package:wave/storage/model/planner_model.dart';
import 'package:wave/storage/secure.dart';
import 'package:wave/storage/secure_goals.dart';
import 'package:wave/storage/secure_money_goals.dart';
import 'package:wave/storage/secure_planner.dart';
import 'package:wave/pages/homepage/goals/regulargoal/regulargoalPage.dart';

class CryptoEngine {
  static const _storage = FlutterSecureStorage();
  static const _dekStorageKey = 'ws_1_0_clean_dek';
  static enc.Key? _cachedKey;

  static Future<bool> initLocalKey() async {
    try {
      final base64Key = await _storage.read(key: _dekStorageKey);
      if (base64Key != null) {
        _cachedKey = enc.Key.fromBase64(base64Key);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveLocalKey(Uint8List dekBytes) async {
    _cachedKey = enc.Key(dekBytes);
    await _storage.write(key: _dekStorageKey, value: _cachedKey!.base64);
  }

  static Future<Uint8List> deriveMasterKey(String password, String saltBase64) async {
    final saltBytes = base64Decode(saltBase64);
    
    final algorithm = Argon2id(
      memory: 32768,
      iterations: 3,
      parallelism: 2,
      hashLength: 32,
    );

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: saltBytes,
    );

    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  static Map<String, String> encryptString(String plainText) {
    if (_cachedKey == null) throw Exception('Encryption key not initialized!');

    final textToEncrypt = plainText.isEmpty ? " " : plainText;
    final iv = enc.IV.fromSecureRandom(12); 
    final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(textToEncrypt, iv: iv);

    return {
      'ciphertext': encrypted.base64,
      'iv': iv.base64,
    };
  }

  static String decryptString(String ciphertextBase64, String ivBase64) {
    if (_cachedKey == null) throw Exception('Encryption key not initialized!');
    if (ciphertextBase64.isEmpty || ivBase64.isEmpty) return '';
    
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
    
    final decrypted = encrypter.decrypt64(ciphertextBase64, iv: iv);
    return decrypted == " " ? "" : decrypted;
  }
}

class DataSyncService {
  static final _supabase = Supabase.instance.client;
  static final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void startInternetListener() {
    print('Automated internet listener started.');
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        if (await CryptoEngine.initLocalKey()) {
          await sendAllDataToServer();
        }
      }
    });
  }

  static Future<void> uploadSingleRegularGoal(GoalModel goal) async {
    if (!await _hasInternet()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final localUsername = await SecureStorageService.getMail() ?? '';
      final tasks = await SecureGoalsStorageService.getGoalTasks(goal.id);
      final tasksJson = tasks.map((t) => t.toJson()).toList();
      final tasksRawString = jsonEncode(tasksJson);

      final encName = CryptoEngine.encryptString(goal.name);
      final encTasks = CryptoEngine.encryptString(tasksRawString);
      final encEmoji = CryptoEngine.encryptString(goal.emoji);
      final encDate = CryptoEngine.encryptString(goal.date);
      final encProgress = CryptoEngine.encryptString(goal.progress.toString());
      final encPinned = CryptoEngine.encryptString(goal.pinned.toString());

      final goalMap = goal.toSupabaseJson(user.id, localUsername);
      
      goalMap['name'] = encName['ciphertext'];
      goalMap['tasks'] = encTasks['ciphertext'];
      goalMap['emoji'] = encEmoji['ciphertext'];
      goalMap['date'] = encDate['ciphertext'];
      goalMap['progress'] = encProgress['ciphertext'];
      goalMap['pinned'] = encPinned['ciphertext'];
      
      goalMap['iv'] = '${encName['iv']}:${encTasks['iv']}:${encEmoji['iv']}:${encDate['iv']}:${encProgress['iv']}:${encPinned['iv']}'; 
      goalMap['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('regular_goals').upsert(goalMap);
      print('Standard goal ${goal.id} has been successfully synchronized individually.');
    } catch (e) {
      print('Point-targeting error for a standard target: $e');
    }
  }

  static Future<void> uploadSingleMoneyGoal(MoneyGoalModel mGoal) async {
    if (!await _hasInternet()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final localUsername = await SecureStorageService.getMail() ?? '';
      final history = await SecureMoneyGoalsStorageService.getHistory(mGoal.id);
      final historyJson = history.map((e) => e.toJson()).toList();
      final historyRawString = jsonEncode(historyJson);

      final encCurrent = CryptoEngine.encryptString(mGoal.currentAmount.toString());
      final encTarget = CryptoEngine.encryptString(mGoal.targetAmount.toString());
      final encProgress = CryptoEngine.encryptString(mGoal.progress.toString());
      final encHistory = CryptoEngine.encryptString(historyRawString);
      final encCurrency = CryptoEngine.encryptString(mGoal.currency);
      final encTargetDate = CryptoEngine.encryptString(mGoal.targetDate);
      final encPinned = CryptoEngine.encryptString(mGoal.pinned.toString());

      final mGoalMap = mGoal.toSupabaseJson(user.id, localUsername, history); 
      
      mGoalMap['current_amount'] = encCurrent['ciphertext'];
      mGoalMap['target_amount'] = encTarget['ciphertext'];
      mGoalMap['progress'] = encProgress['ciphertext'];
      mGoalMap['history'] = encHistory['ciphertext'];
      mGoalMap['currency'] = encCurrency['ciphertext'];
      mGoalMap['target_date'] = encTargetDate['ciphertext'];
      mGoalMap['pinned'] = encPinned['ciphertext'];
      
      mGoalMap['iv'] = '${encCurrent['iv']}:${encTarget['iv']}:${encProgress['iv']}:${encHistory['iv']}:${encCurrency['iv']}:${encTargetDate['iv']}:${encPinned['iv']}';
      mGoalMap['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('money_goals').upsert(mGoalMap);
      print('Financial goal ${mGoal.id} has been successfully synchronized individually.');
    } catch (e) {
      print('Error in targeted money transfer: $e');
    }
  }

  static Future<bool> setupCryptoForNewUser(String password) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      print('Generating a crypto profile for a new user...');
      final secureRandom = enc.IV.fromSecureRandom(16);
      final saltBase64 = secureRandom.base64;
      final randomDek = enc.Key.fromSecureRandom(32);
      final dekBytes = randomDek.bytes;

      final masterKeyBytes = await CryptoEngine.deriveMasterKey(password, saltBase64);
      final masterKey = enc.Key(masterKeyBytes);

      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(masterKey, mode: enc.AESMode.gcm));
      final encryptedDek = encrypter.encryptBytes(dekBytes, iv: iv);

      final encryptedDekPayload = '${iv.base64}:${encryptedDek.base64}';

      await _supabase.from('user_crypto_profiles').insert({
        'user_id': user.id,
        'crypto_salt': saltBase64,
        'encrypted_dek': encryptedDekPayload,
      });

      await CryptoEngine.saveLocalKey(Uint8List.fromList(dekBytes));
      return true;
    } catch (e) {
      print('Failed to configure encryption during registration: $e');
      return false;
    }
  }

  static Future<bool> restoreCryptoForExistingUser(String password) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      print('Restoring user crypto-profile...');
      final cryptoResponse = await _supabase
        .from('user_crypto_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

      if (cryptoResponse == null) return false;

      final String saltBase64 = cryptoResponse['crypto_salt'];
      final String encryptedDekPayload = cryptoResponse['encrypted_dek'];

      final payloadParts = encryptedDekPayload.split(':');
      if (payloadParts.length != 2) throw Exception('Invalid crypto-packet format');
      
      final ivBase64 = payloadParts[0];
      final ciphertextBase64 = payloadParts[1];

      final masterKeyBytes = await CryptoEngine.deriveMasterKey(password, saltBase64);
      final masterKey = enc.Key(masterKeyBytes);

      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(masterKey, mode: enc.AESMode.gcm));
      final decryptedDekBytes = encrypter.decryptBytes(enc.Encrypted.fromBase64(ciphertextBase64), iv: iv);

      await CryptoEngine.saveLocalKey(Uint8List.fromList(decryptedDekBytes));
      return true;
    } catch (e) {
      print('Failed to decrypt the data: $e');
      return false;
    }
  }

  static Future<bool> changePasswordCryptoAndAuth({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final username = await SecureStorageService.getMail();
      if (username == null || username.isEmpty) throw Exception('Saved username not found.');
      final fakeEmail = '$username@mygoalsapp.com';

      await _supabase.auth.signInWithPassword(email: fakeEmail, password: oldPassword);

      final cryptoResponse = await _supabase
          .from('user_crypto_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (cryptoResponse == null) return false;

      final String saltBase64 = cryptoResponse['crypto_salt'];
      if (CryptoEngine._cachedKey == null) throw Exception('Current DEK cache is missing.');
      final dekBytes = CryptoEngine._cachedKey!.bytes;

      final newMasterKeyBytes = await CryptoEngine.deriveMasterKey(newPassword, saltBase64);
      final newMasterKey = enc.Key(newMasterKeyBytes);

      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(newMasterKey, mode: enc.AESMode.gcm));
      final encryptedDek = encrypter.encryptBytes(dekBytes, iv: iv);

      final newEncryptedDekPayload = '${iv.base64}:${encryptedDek.base64}';

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      await _supabase.from('user_crypto_profiles').update({
        'encrypted_dek': newEncryptedDekPayload,
      }).eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Failed to change password: $e');
      return false;
    }
  }

  static Future<bool> isUsernameTaken(String username) async {
    if (!await _hasInternet()) return false;
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', currentUser.id)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProfileData(String newName, String newUsername) async {
    if (!await _hasInternet()) return false;

    try {
      await _supabase.auth.refreshSession();
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final encryptedNameData = CryptoEngine.encryptString(newName.trim());

      await _supabase.rpc(
        'change_user_login_direct',
        params: {
          'new_username': newUsername.trim(),
          'new_name': '${encryptedNameData['iv']}:${encryptedNameData['ciphertext']}',
        },
      );

      await _supabase.auth.refreshSession();
      await sendAllDataToServer();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> uploadAvatar(File avatarFile) async {
    if (!await _hasInternet()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final fileBytes = await avatarFile.readAsBytes();
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(CryptoEngine._cachedKey!, mode: enc.AESMode.gcm));
      final encryptedBytes = encrypter.encryptBytes(fileBytes, iv: iv).bytes;
      
      final combinedBytes = BytesBuilder();
      combinedBytes.add(iv.bytes);
      combinedBytes.add(encryptedBytes);

      await _supabase.storage.from('avatars').uploadBinary(
        user.id, 
        combinedBytes.toBytes(),
        fileOptions: const FileOptions(upsert: true),
      );
    } catch (e) {
      print('Avatar upload error: $e');
    }
  }

  static Future<File?> downloadAvatar() async {
    if (!await _hasInternet()) return null;
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final List<int> downloadedBytes = await _supabase.storage.from('avatars').download(user.id);
      if (downloadedBytes.length < 12) return null;

      final ivBytes = downloadedBytes.sublist(0, 12);
      final ciphertextBytes = downloadedBytes.sublist(12);
      
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(CryptoEngine._cachedKey!, mode: enc.AESMode.gcm));
      
      final decryptedList = encrypter.decryptBytes(enc.Encrypted(Uint8List.fromList(ciphertextBytes)), iv: iv);
      
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File('${directory.path}/avatar.png');
      await localFile.writeAsBytes(decryptedList);
      return localFile;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteProfileImage(File? localFile) async {
    try {
      if (!await _hasInternet()) return false;
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      isSyncing.value = true;
      try { await _supabase.auth.refreshSession(); } catch (_) {}

      try {
        await _supabase.storage.from('avatars').remove([user.id]);
      } catch (_) {}

      try {
        await _supabase.from('profiles').update({'avatar_url': null}).eq('id', user.id); 
      } catch (_) {}

      if (localFile != null && await localFile.exists()) {
        await localFile.delete();
      }
      
      await SecureStorageService.deleteLocalAvatar(); 
      return true;
    } catch (e) {
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  static Future<void> sendAllDataToServer() async {
    if (!await _hasInternet()) return; 
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isSyncing.value = true;

    try {
      try { await _supabase.auth.refreshSession(); } catch (_) {}

      final localAvatar = await SecureStorageService.getLocalAvatar();
      if (localAvatar != null) await uploadAvatar(localAvatar);

      final localName = await SecureStorageService.getName() ?? '';
      final localUsername = await SecureStorageService.getMail() ?? '';
      
      final encryptedNameData = CryptoEngine.encryptString(localName);

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': localUsername, 
        'name': '${encryptedNameData['iv']}:${encryptedNameData['ciphertext']}', 
        'updated_at': DateTime.now().toIso8601String(),
      });

      final regularGoals = await SecureGoalsStorageService.getGoals();
      final List<Map<String, dynamic>> regularGoalsData = [];

      for (var goal in regularGoals) {
        final tasks = await SecureGoalsStorageService.getGoalTasks(goal.id);
        final tasksJson = tasks.map((t) => t.toJson()).toList();
        final tasksRawString = jsonEncode(tasksJson);

        final encName = CryptoEngine.encryptString(goal.name);
        final encTasks = CryptoEngine.encryptString(tasksRawString);
        final encEmoji = CryptoEngine.encryptString(goal.emoji);
        final encDate = CryptoEngine.encryptString(goal.date);
        final encProgress = CryptoEngine.encryptString(goal.progress.toString());
        final encPinned = CryptoEngine.encryptString(goal.pinned.toString());

        final goalMap = goal.toSupabaseJson(user.id, localUsername);
        
        goalMap['name'] = encName['ciphertext'];
        goalMap['tasks'] = encTasks['ciphertext'];
        goalMap['emoji'] = encEmoji['ciphertext'];
        goalMap['date'] = encDate['ciphertext'];
        goalMap['progress'] = encProgress['ciphertext'];
        goalMap['pinned'] = encPinned['ciphertext'];
        
        goalMap['iv'] = '${encName['iv']}:${encTasks['iv']}:${encEmoji['iv']}:${encDate['iv']}:${encProgress['iv']}:${encPinned['iv']}'; 
        goalMap['updated_at'] = DateTime.now().toIso8601String();
        
        regularGoalsData.add(goalMap);
      }

      if (regularGoalsData.isNotEmpty) {
        await _supabase.from('regular_goals').upsert(regularGoalsData);
      }

      final moneyGoals = await SecureMoneyGoalsStorageService.getGoals();
      final List<Map<String, dynamic>> moneyGoalsData = [];

      for (var mGoal in moneyGoals) {
        final history = await SecureMoneyGoalsStorageService.getHistory(mGoal.id);
        final historyJson = history.map((e) => e.toJson()).toList();
        final historyRawString = jsonEncode(historyJson);

        final encCurrent = CryptoEngine.encryptString(mGoal.currentAmount.toString());
        final encTarget = CryptoEngine.encryptString(mGoal.targetAmount.toString());
        final encProgress = CryptoEngine.encryptString(mGoal.progress.toString());
        final encHistory = CryptoEngine.encryptString(historyRawString);
        final encCurrency = CryptoEngine.encryptString(mGoal.currency);
        final encTargetDate = CryptoEngine.encryptString(mGoal.targetDate);
        final encPinned = CryptoEngine.encryptString(mGoal.pinned.toString());

        final mGoalMap = mGoal.toSupabaseJson(user.id, localUsername, history); 
        
        mGoalMap['current_amount'] = encCurrent['ciphertext'];
        mGoalMap['target_amount'] = encTarget['ciphertext'];
        mGoalMap['progress'] = encProgress['ciphertext'];
        mGoalMap['history'] = encHistory['ciphertext'];
        mGoalMap['currency'] = encCurrency['ciphertext'];
        mGoalMap['target_date'] = encTargetDate['ciphertext'];
        mGoalMap['pinned'] = encPinned['ciphertext'];
        
        mGoalMap['iv'] = '${encCurrent['iv']}:${encTarget['iv']}:${encProgress['iv']}:${encHistory['iv']}:${encCurrency['iv']}:${encTargetDate['iv']}:${encPinned['iv']}';
        mGoalMap['updated_at'] = DateTime.now().toIso8601String();
        
        moneyGoalsData.add(mGoalMap);
      }

      if (moneyGoalsData.isNotEmpty) {
        await _supabase.from('money_goals').upsert(moneyGoalsData);
      }
      final plannerTasks = await SecurePlannerStorageService.getTasks();
      final plannerTasksJson = plannerTasks.map((t) => t.toJson()).toList();
      final plannerTasksRawString = jsonEncode(plannerTasksJson);
      final encPlannerTasks = CryptoEngine.encryptString(plannerTasksRawString);

      await _supabase.from('planner_data').upsert({
        'user_id': user.id,
        'username': localUsername,
        'tasks': encPlannerTasks['ciphertext'],
        'iv': encPlannerTasks['iv'],
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Sending error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  static Future<void> downloadAllDataFromServer() async {
    if (!await _hasInternet()) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isSyncing.value = true;

    try {
      final profileResponse = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profileResponse != null && profileResponse['name'] != null) {
        final String nameField = profileResponse['name'];
        final parts = nameField.split(':');
        
        if (parts.length == 2) {
          final decryptedName = CryptoEngine.decryptString(parts[1], parts[0]);
          await SecureStorageService.saveName(decryptedName);
        }
        await SecureStorageService.saveMail(profileResponse['username'] ?? '');
      }

      final regularResponse = await _supabase.from('regular_goals').select().eq('user_id', user.id);
      if (regularResponse != null && regularResponse.isNotEmpty) {
        for (var item in regularResponse) {
          List? savedTasksList;
          if (item['iv'] != null) {
            final ivParts = (item['iv'] as String).split(':');
            
            if (ivParts.length == 6) {
              final decName = CryptoEngine.decryptString(item['name'], ivParts[0]);
              final decTasksRaw = CryptoEngine.decryptString(item['tasks'], ivParts[1]);
              final decEmoji = CryptoEngine.decryptString(item['emoji'] ?? '', ivParts[2]);
              final decDate = CryptoEngine.decryptString(item['date'] ?? '', ivParts[3]);
              final decProgress = CryptoEngine.decryptString(item['progress'] ?? '0.0', ivParts[4]);
              final decPinned = CryptoEngine.decryptString(item['pinned'] ?? 'false', ivParts[5]);

              item['name'] = decName;
              savedTasksList = jsonDecode(decTasksRaw) as List?;
              item['tasks'] = savedTasksList;
              item['emoji'] = decEmoji;
              item['date'] = decDate;
              item['progress'] = double.tryParse(decProgress) ?? 0.0;
              item['pinned'] = decPinned == 'true';
            } 
            else if (ivParts.length == 2) {
              final decName = CryptoEngine.decryptString(item['name'], ivParts[0]);
              final decTasksRaw = CryptoEngine.decryptString(item['tasks'], ivParts[1]);
              item['name'] = decName;
              savedTasksList = jsonDecode(decTasksRaw) as List?;
              item['tasks'] = savedTasksList;
              item['emoji'] = '';
              item['date'] = '';
              item['progress'] = 0.0;
              item['pinned'] = false;
            }
          }

          final goal = GoalModel.fromJson(item);
          await SecureGoalsStorageService.saveGoal(goal);
          if (savedTasksList != null) {

            final List<TaskModel> parsedTasks = [];
            for (var taskJson in savedTasksList) {
              try {
                parsedTasks.add(TaskModel.fromJson(taskJson));
              } catch (e) {
                print('Error parsing TaskModel: $e');
              }
            }
            await SecureGoalsStorageService.replaceGoalTasks(goal.id, parsedTasks);
          }
        }
      }

      final moneyResponse = await _supabase.from('money_goals').select().eq('user_id', user.id);
      if (moneyResponse != null && moneyResponse.isNotEmpty) {
        for (var item in moneyResponse) {
          List? fetchedHistoryList;
          if (item['iv'] != null) {
            final ivParts = (item['iv'] as String).split(':');
            
            if (ivParts.length == 7) {
              final decCurrent = CryptoEngine.decryptString(item['current_amount'], ivParts[0]);
              final decTarget = CryptoEngine.decryptString(item['target_amount'], ivParts[1]);
              final decProgress = CryptoEngine.decryptString(item['progress'], ivParts[2]);
              final decHistoryRaw = CryptoEngine.decryptString(item['history'], ivParts[3]);
              final decCurrency = CryptoEngine.decryptString(item['currency'] ?? '', ivParts[4]);
              final decTargetDate = CryptoEngine.decryptString(item['target_date'] ?? '', ivParts[5]);
              final decPinned = CryptoEngine.decryptString(item['pinned'] ?? 'false', ivParts[6]);

              item['current_amount'] = double.tryParse(decCurrent) ?? 0.0;
              item['target_amount'] = double.tryParse(decTarget) ?? 0.0;
              item['progress'] = double.tryParse(decProgress) ?? 0.0;
              
              fetchedHistoryList = jsonDecode(decHistoryRaw) as List?;
              item['history'] = fetchedHistoryList;
              item['currency'] = decCurrency;
              item['target_date'] = decTargetDate;
              item['pinned'] = decPinned == 'true';
            } 
            else if (ivParts.length == 4) {
              final decCurrent = CryptoEngine.decryptString(item['current_amount'], ivParts[0]);
              final decTarget = CryptoEngine.decryptString(item['target_amount'], ivParts[1]);
              final decProgress = CryptoEngine.decryptString(item['progress'], ivParts[2]);
              final decHistoryRaw = CryptoEngine.decryptString(item['history'], ivParts[3]);

              item['current_amount'] = double.tryParse(decCurrent) ?? 0.0;
              item['target_amount'] = double.tryParse(decTarget) ?? 0.0;
              item['progress'] = double.tryParse(decProgress) ?? 0.0;
              
              fetchedHistoryList = jsonDecode(decHistoryRaw) as List?;
              item['history'] = fetchedHistoryList;
              item['currency'] = '';
              item['target_date'] = '';
              item['pinned'] = false;
            }
          }

          final mGoal = MoneyGoalModel.fromJson(item);
          await SecureMoneyGoalsStorageService.saveGoal(mGoal);
          if (fetchedHistoryList != null) {
            final fetchedHistory = fetchedHistoryList.map((e) => MoneyHistoryEntry.fromJson(e)).toList();

            await const FlutterSecureStorage().write(
              key: 'money_history_${mGoal.id}', 
              value: jsonEncode(fetchedHistory.map((e) => e.toJson()).toList()),
            );
          }
        }
      }

      final plannerResponse = await _supabase
          .from('planner_data')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (plannerResponse != null &&
          plannerResponse['tasks'] != null &&
          plannerResponse['iv'] != null) {
        final decPlannerRaw = CryptoEngine.decryptString(
          plannerResponse['tasks'],
          plannerResponse['iv'],
        );
        final List decodedPlannerList = jsonDecode(decPlannerRaw);
        final restoredTasks = decodedPlannerList
            .map((e) => PlannerTask.fromJson(e))
            .toList();

        await SecurePlannerStorageService.replaceAllTasks(restoredTasks);
      }

      await downloadAvatar();
    } catch (e) {
      print('Decryption error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  static Future<void> deleteRegularGoalFromServer(String goalId) async {
    if (!await _hasInternet()) return;
    try {
      await _supabase.from('regular_goals').delete().eq('id', goalId);
    } catch (e) {
      print('Failed to delete the standard target from the server: $e');
    }
  }

  static Future<void> deleteMoneyGoalFromServer(String goalId) async {
    if (!await _hasInternet()) return;
    try {
      await _supabase.from('money_goals').delete().eq('id', goalId);
    } catch (e) {
      print('Failed to delete the financial goal from the server: $e');
    }
  }
}

// this code was written by maksy