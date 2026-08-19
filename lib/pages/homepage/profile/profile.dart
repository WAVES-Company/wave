import 'dart:io' show File;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/authpage.dart';
import 'package:wave/services/data_sync_service.dart';
import 'package:wave/storage/secure.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditingUsername = false;
  bool isEditingEmail = false;
  bool isPickingImage = false;
  String usrnm = "";
  String ml = "";
  
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  File? profileImage;

  @override
  void initState() {
    super.initState();
    loadData();
    usernameFocusNode.addListener(() {
      if (!usernameFocusNode.hasFocus && isEditingUsername) {
        _commitUsername(usernameController.text);
      }
    });
    emailFocusNode.addListener(() {
      if (!emailFocusNode.hasFocus && isEditingEmail) {
        _commitEmail(emailController.text);
      }
    });
  }

  @override
  void dispose() {
    if (isEditingUsername) {
      _commitUsername(usernameController.text, updateState: false);
    }
    if (isEditingEmail) {
      _commitEmail(emailController.text, updateState: false);
    }
    usernameFocusNode.dispose();
    emailFocusNode.dispose();
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _commitUsername(String value, {bool updateState = true}) async {
    final trimmed = value.trim();
    
    if (trimmed.isEmpty || trimmed == usrnm) {
      if (updateState && mounted) {
        setState(() {
          usernameController.text = usrnm;
          isEditingUsername = false;
        });
      } else {
        isEditingUsername = false;
      }
      return;
    }

    await SecureStorageService.saveName(trimmed);

    await DataSyncService.updateProfileData(trimmed, ml);

    if (updateState && mounted) {
      setState(() {
        usrnm = trimmed;
        isEditingUsername = false;
      });
    } else {
      usrnm = trimmed;
      isEditingUsername = false;
    }
  }

  Future<void> _commitEmail(String value, {bool updateState = true}) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == ml) {
      if (updateState && mounted) {
        setState(() {
          emailController.text = ml;
          isEditingEmail = false;
        });
      } else {
        isEditingEmail = false;
      }
      return;
    }

    final isTaken = await DataSyncService.isUsernameTaken(trimmed);
    if (isTaken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).zan,
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.fixed,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          emailController.text = ml; 
          isEditingEmail = false;
        });
      }
      return; 
    }

    await SecureStorageService.saveMail(trimmed);

    await DataSyncService.updateProfileData(usrnm, trimmed);

    if (updateState && mounted) {
      setState(() {
        ml = trimmed;
        isEditingEmail = false;
      });
    } else {
      ml = trimmed;
      isEditingEmail = false;
    }
  }
  Future<void> pickImage() async {
    if (isPickingImage) return;
    setState(() => isPickingImage = true);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        setState(() => isPickingImage = false);
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: S.of(context).rdkt,
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.black,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );
      
      if (croppedFile == null) {
        setState(() => isPickingImage = false);
        return;
      }
      final savedAvatar = await SecureStorageService.saveLocalAvatar(croppedFile.path);

      if (savedAvatar != null) {
        await DataSyncService.uploadAvatar(savedAvatar);

        if (!mounted) return;
        await FileImage(savedAvatar).evict();
        setState(() {
          profileImage = savedAvatar;
        });
      }
      
    } catch (e) {
      debugPrint("Error selecting/cropping the image: $e");
    } finally {
      if (mounted) {
        setState(() => isPickingImage = false);
      }
    }
  }

  Future<void> loadData() async {
    final name = await SecureStorageService.getName();
    final mail = await SecureStorageService.getMail();

    final avatarFile = await SecureStorageService.getLocalAvatar();

    setState(() {
      usrnm = name ?? '';
      ml = mail ?? '';
      usernameController.text = usrnm;
      emailController.text = ml;
      profileImage = avatarFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    key: ValueKey(profileImage != null ? profileImage!.lengthSync() : 0),
                    width: 200,
                    height: 200,
                    decoration: inset.BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      image: profileImage != null
                          ? DecorationImage(
                              image: FileImage(profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        inset.BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                          inset: true,
                        ),
                      ],
                    ),
                    child: profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 100,
                            color: Color.fromARGB(255, 110, 110, 110),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 50,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.only(left: 15, right: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            isDark 
                                ? 'assets/icons/sectionicons/black/photoprofileblack.png'
                                : 'assets/icons/sectionicons/white/photoprofilewhite.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).ptpr,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 22),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 100,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 50,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Row(
                                children: [
                                  Image.asset(
                                    isDark 
                                        ? 'assets/icons/sectionicons/black/nameblack.png'
                                        : 'assets/icons/sectionicons/white/namewhite.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    S.of(context).yrnm,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isEditingUsername = true;
                              usernameController.text = usrnm;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              usernameFocusNode.requestFocus();
                            });
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 50,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: isEditingUsername
                                  ? TextField(
                                      controller: usernameController,
                                      focusNode: usernameFocusNode,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (value) {
                                        _commitUsername(value);
                                      },
                                    )
                                  : Text(
                                      usrnm.isEmpty ? S.of(context).vdtyrnm : usrnm,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 110, 110, 110),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 100,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 50,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Row(
                                children: [
                                  Image.asset(
                                    isDark 
                                        ? 'assets/icons/sectionicons/black/usernameblack.png'
                                        : 'assets/icons/sectionicons/white/usernamewhite.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    S.of(context).eml,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isEditingEmail = true;
                              emailController.text = ml;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              emailFocusNode.requestFocus();
                            });
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 50,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: isEditingEmail
                                  ? TextField(
                                      controller: emailController,
                                      focusNode: emailFocusNode,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (value) {
                                        _commitEmail(value);
                                      },
                                    )
                                  : Text(
                                      ml.isEmpty ? S.of(context).vdteml : ml,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 110, 110, 110),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(34),
                    onTap: () => _showConfirmDialog(
                      title: S.of(context).viti,
                      content: S.of(context).potverviti,
                      onConfirm: () async {
                        try {
                          await Supabase.instance.client.auth.signOut();
                        } catch (e) {
                          debugPrint("Error logging out of Supabase: $e");
                        }
                        await SecureStorageService.clear();
                        await SecureStorageService.deleteLocalAvatar();
                        
                        if (mounted) {
                          setState(() {
                            usernameController.clear();
                            emailController.clear();
                            profileImage = null;
                            usrnm = "";
                            ml = "";
                          });
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          S.of(context).viti,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 110, 110, 110),
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(34),
                    onTap: () => _showConfirmDialog(
                      title: S.of(context).dlt,
                      content: S.of(context).potverudal,
                      onConfirm: () async {
                        try {
                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;

                          if (user != null) {
                            final userId = user.id; 
                            try {
                              print('Deleting avatar: $userId');
                              final List<FileObject> response = await supabase.storage.from('avatars').remove([userId]); 
                              
                              if (response.isNotEmpty) {
                                print('The server confirmed the file deletion: ${response.first.name}');
                              } else {
                                print('The file was not deleted; an error occurred.');
                              }
                            } catch (storageError) {
                              debugPrint("Critical error executing request: $storageError");
                            }

                            await Future.delayed(const Duration(milliseconds: 500));

                            print('Call delete_user_account');
                            await supabase.rpc('delete_user_account');
                            await supabase.auth.signOut();
                          }
                        } catch (e) {
                          debugPrint("Error deleting account on the server: $e");
                        }

                        await SecureStorageService.clear();
                        await SecureStorageService.deleteLocalAvatar();
                        
                        if (mounted) {
                          setState(() { 
                            usernameController.clear();
                            emailController.clear();
                            profileImage = null;
                            usrnm = "";
                            ml = "";
                          });
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          S.of(context).dlt,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                S.of(context).ot,
                style: TextStyle(
                  color: Theme.of(context).brightness ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
                  fontSize: 18,
                )
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(S.of(context).yes, style: TextStyle(color: Colors.red, fontSize: 18)),
            ),
          ],
        );
      },
    );
  }
}

// this code was written by maksy