import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:cryptography/cryptography.dart';
import 'package:wave/storage/model/goal_model.dart';
import 'package:wave/storage/model/money_goal_model.dart';
import 'package:wave/storage/model/money_history_goal_model.dart';
import 'package:wave/storage/secure.dart';
import 'package:wave/storage/secure_goals.dart';
import 'package:wave/storage/secure_money_goals.dart';
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
    
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return {
      'ciphertext': encrypted.base64,
      'iv': iv.base64,
    };
  }

  static String decryptString(String ciphertextBase64, String ivBase64) {
    if (_cachedKey == null) throw Exception('Encryption key not initialized!');
    
    final iv = enc.IV.fromBase64(ivBase64);
    final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
    
    return encrypter.decrypt64(ciphertextBase64, iv: iv);
  }
}

class DataSyncService {
  static final _supabase = Supabase.instance.client;

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
      print('Username validation error:$e');
      return false;
    }
  }

  static Future<bool> updateProfileData(String newName, String newUsername) async {
    if (!await _hasInternet()) return false;

    try {
      await _supabase.auth.refreshSession();
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      print('Forced account login change via RPC...');

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

      print('Account login successfully changed.');
      return true;
    } catch (e) {
      print('Forced update error: $e');
      return false;
    }
  }

  static Future<void> uploadAvatar(File avatarFile) async {
    if (!await _hasInternet()) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      print('Encrypting and uploading avatar to Storage...');
      
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

      print('The encrypted avatar has been successfully uploaded to the server.');
    } catch (e) {
      print('Avatar upload error: $e');
    }
  }

  static Future<File?> downloadAvatar() async {
    if (!await _hasInternet()) return null;

    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      print('Downloading and decrypting avatar...');
      
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
      
      print('Avatar successfully decrypted and saved locally.');
      return localFile;
    } catch (e) {
      print('Avatar not found on the server or an error occurred: $e');
      return null;
    }
  }

  static Future<bool> deleteProfileImage(File? localFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final storagePath = user.id; 
      print('Deleting an encrypted avatar by ID: $storagePath');

      try {
        await _supabase.storage.from('avatars').remove([storagePath]);
      } catch (storageError) {
        print('Error deleting from Storage: $storageError');
      }

      await _supabase.from('profiles').update({'avatar_url': null}).eq('id', user.id); 

      if (localFile != null && await localFile.exists()) {
        await localFile.delete();
      }

      return true;
    } catch (e) {
      print('DataSyncService Delete Error: $e');
      return false;
    }
  }

  static Future<void> sendAllDataToServer() async {
    if (!await _hasInternet()) return; 

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      print('Launching E2EE data synchronization in Supabase...');

      final localAvatar = await SecureStorageService.getLocalAvatar();
      if (localAvatar != null) {
        await uploadAvatar(localAvatar);
      }

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

        final goalMap = goal.toSupabaseJson(user.id, localUsername);
        
        goalMap['name'] = encName['ciphertext'];
        goalMap['tasks'] = encTasks['ciphertext'];
        goalMap['iv'] = '${encName['iv']}:${encTasks['iv']}'; 
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

        final mGoalMap = mGoal.toSupabaseJson(user.id, localUsername, history); 
        
        mGoalMap['current_amount'] = encCurrent['ciphertext'];
        mGoalMap['target_amount'] = encTarget['ciphertext'];
        mGoalMap['progress'] = encProgress['ciphertext'];
        mGoalMap['history'] = encHistory['ciphertext'];
        
        mGoalMap['iv'] = '${encCurrent['iv']}:${encTarget['iv']}:${encProgress['iv']}:${encHistory['iv']}';
        mGoalMap['updated_at'] = DateTime.now().toIso8601String();
        
        moneyGoalsData.add(mGoalMap);
      }

      if (moneyGoalsData.isNotEmpty) {
        await _supabase.from('money_goals').upsert(moneyGoalsData);
      }

      print('Data successfully encrypted and synchronized!');
    } catch (e) {
      print('Sending error: $e');
    }
  }

  static Future<void> downloadAllDataFromServer() async {
    if (!await _hasInternet()) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      print('Downloading and decrypting data for the new device...');

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
            if (ivParts.length == 2) {
              final decName = CryptoEngine.decryptString(item['name'], ivParts[0]);
              final decTasksRaw = CryptoEngine.decryptString(item['tasks'], ivParts[1]);
              
              item['name'] = decName;
              savedTasksList = jsonDecode(decTasksRaw) as List?;
              item['tasks'] = savedTasksList;
            }
          }

          final goal = GoalModel.fromJson(item);
          await SecureGoalsStorageService.saveGoal(goal);

          if (savedTasksList != null) {
            for (var taskJson in savedTasksList) {
              try {
                final dynamic taskObj = (TaskModel as dynamic).fromJson(taskJson);
                await SecureGoalsStorageService.saveGoalTask(goal.id, taskObj);
              } catch (_) {
                final dynamic taskObj = (TaskModel as dynamic).fromMap(taskJson);
                await SecureGoalsStorageService.saveGoalTask(goal.id, taskObj);
              }
            }
          }
        }
      }
      final moneyResponse = await _supabase.from('money_goals').select().eq('user_id', user.id);
      if (moneyResponse != null && moneyResponse.isNotEmpty) {
        for (var item in moneyResponse) {
          if (item['iv'] != null) {
            final ivParts = (item['iv'] as String).split(':');
            if (ivParts.length == 4) {
              final decCurrent = CryptoEngine.decryptString(item['current_amount'], ivParts[0]);
              final decTarget = CryptoEngine.decryptString(item['target_amount'], ivParts[1]);
              final decProgress = CryptoEngine.decryptString(item['progress'], ivParts[2]);
              final decHistoryRaw = CryptoEngine.decryptString(item['history'], ivParts[3]);

              item['current_amount'] = double.tryParse(decCurrent) ?? 0.0;
              item['target_amount'] = double.tryParse(decTarget) ?? 0.0;
              item['progress'] = double.tryParse(decProgress) ?? 0.0;
              item['history'] = jsonDecode(decHistoryRaw);
            }
          }

          final mGoal = MoneyGoalModel.fromJson(item);
          await SecureMoneyGoalsStorageService.saveGoal(mGoal);

          if (item['history'] != null) {
            final List historyList = item['history'];
            final fetchedHistory = historyList.map((e) => MoneyHistoryEntry.fromJson(e)).toList();
            
            await const FlutterSecureStorage().write(
              key: 'money_history_${mGoal.id}', 
              value: jsonEncode(fetchedHistory.map((e) => e.toJson()).toList()),
            );
          }
        }
      }
      
      await downloadAvatar();
      print('All data successfully decrypted and saved locally!');
    } catch (e) {
      print('Error downloading and decrypting data: $e');
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