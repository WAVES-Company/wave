import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wave/storage/secure_key.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveName(String name) async {
    await _storage.write(key: SecureKeys.wname, value: name);
  }
  static Future<void> saveMail(String mail) async {
    await _storage.write(key: SecureKeys.wmail, value: mail);
  }
  static Future<File?> saveLocalAvatar(String tempPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatar.png');

      if (await avatarFile.exists()) {
        await avatarFile.delete();
      }
      final savedFile = await File(tempPath).copy(avatarFile.path);
      print('The new avatar has been successfully saved to the following path: ${savedFile.path}');
      return savedFile;
    } catch (e) {
      print('[Error saving local avatar: $e');
      return null;
    }
  }

  static Future<String?> getName() async {
    return await _storage.read(key: SecureKeys.wname);
  }
  static Future<String?> getMail() async {
    return await _storage.read(key: SecureKeys.wmail);
  }
  static Future<File?> getLocalAvatar() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatar.png');
      if (await avatarFile.exists() && await avatarFile.length() > 0) {
        return avatarFile;
      }
    } catch (e) {
      print('Error validating local avatar: $e');
    }
    return null;
  }

  static Future<void> saveLanguage(String langCode) async {
    await _storage.write(key: SecureKeys.wlang, value: langCode);
  }

  static Future<String?> getLanguage() async {
    return await _storage.read(key: SecureKeys.wlang);
  }

  static Future<void> saveTheme(String themeMode) async {
    await _storage.write(key: SecureKeys.wtheme, value: themeMode);
  }

  static Future<String?> getTheme() async {
    return await _storage.read(key: SecureKeys.wtheme);
  }

  static Future<void> saveTextSize(double size) async {
    await _storage.write(key: SecureKeys.wtext, value: size.toString());
  }

  static Future<double?> getTextSize() async {
    final sizeStr = await _storage.read(key: SecureKeys.wtext);
    return sizeStr != null ? double.tryParse(sizeStr) : null;
  }

  static Future<void> saveBoldText(bool isBold) async {
    await _storage.write(key: SecureKeys.wbold, value: isBold.toString());
  }

  static Future<bool?> getBoldText() async {
    final boldStr = await _storage.read(key: SecureKeys.wbold);
    return boldStr != null ? boldStr == 'true' : null;
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
  static Future<void> deleteLocalAvatar() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarFile = File('${directory.path}/avatar.png');
      
      if (await avatarFile.exists()) {
        await avatarFile.delete();
        print('The local avatar has been successfully removed from the device.');
      }
    } catch (e) {
      print('Failed to delete the avatar file: $e');
    }
  }
}

// this code was written by maksy