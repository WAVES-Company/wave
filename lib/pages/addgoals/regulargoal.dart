import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/addgoals/general/made.dart';
import 'package:wave/storage/model/goal_model.dart';
import 'package:wave/storage/secure_goals.dart';

class RegularGoal extends StatefulWidget {
  final GoalModel? existingGoal;

  const RegularGoal({super.key, this.existingGoal});

  bool get isEditing => existingGoal != null;

  @override
  State<RegularGoal> createState() => _RegularGoalState();
}

class _RegularGoalState extends State<RegularGoal> {
  bool isEditingGoalName = false;
  int currentStep = 0;
  String goalName = "";
  final TextEditingController goalNameController = TextEditingController();

  String goalEmoji = "";
  bool isEditingEmoji = false;
  final TextEditingController goalEmojiController = TextEditingController();

  String goalDate = "";

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      goalName = existing.name;
      goalEmoji = existing.emoji;
      goalDate = existing.date;
      goalNameController.text = goalName;
      goalEmojiController.text = goalEmoji;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goBack() {
    if (currentStep == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        currentStep--;
      });
    }
  }

  void _skipStep() {
    if (currentStep == 2) {
      setState(() {
        goalDate = "";
      });
      _saveAndFinish();
    }
  }

  Future<void> _saveAndFinish() async {
    final existing = widget.existingGoal;
    if (existing != null) {
      await SecureGoalsStorageService.updateGoal(
        existing.copyWith(
          name: goalName,
          emoji: goalEmoji,
          date: goalDate,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    await SecureGoalsStorageService.saveGoal(
      GoalModel(
        name: goalName,
        emoji: goalEmoji,
        date: goalDate,
        progress: 0.0,
      ),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Made()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String title1;

    switch (currentStep) {
      case 0:
        title = S.of(context).naz;
        title1 = S.of(context).vvpv;
        break;

      case 1:
        title = S.of(context).em;
        title1 = S.of(context).kbrsn;
        break;

      case 2:
        title = S.of(context).vbdt;
        title1 = S.of(context).dkhk;
        break;

      default:
        title = "";
        title1 = "";
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: currentStep == 2
            ? [
                TextButton(
                  onPressed: _skipStep,
                  child: Text(
                    S.of(context).skip,
                    style: TextStyle(
                      color: Color.fromARGB(255, 110, 110, 110),
                      fontSize: 16,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 110, 110, 110),
                ),
              ),
              const SizedBox(height: 50),
              if (currentStep == 0)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isEditingGoalName = true;
                      goalNameController.text = goalName;
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 60,
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
                      child: isEditingGoalName
                          ? TextField(
                              controller: goalNameController,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                goalName = value;
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  isEditingGoalName = false;
                                });
                              },
                            )
                          : Text(
                              goalName.isEmpty
                                  ? S.of(context).vdnz
                                  : goalName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(255, 110, 110, 110),
                              ),
                            ),
                    ),
                  ),
                ),
              if (currentStep == 1)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 50),
                  constraints: const BoxConstraints(minHeight: 120),
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
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditingEmoji = true;
                        goalEmojiController.text = goalEmoji;
                      });
                    },
                    child: Center(
                      child: isEditingEmoji
                          ? TextField(
                              showCursor: false,
                              controller: goalEmojiController,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 80,
                              ),
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  final emoji = value.characters.first;
                                  goalEmojiController.text = emoji;
                                  goalEmojiController.selection =
                                      TextSelection.collapsed(
                                    offset: emoji.length,
                                  );
                                  goalEmoji = emoji;
                                }
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  isEditingEmoji = false;
                                });
                              },
                            )
                          : Text(
                              goalEmoji.isEmpty
                                  ? S.of(context).zbve
                                  : goalEmoji,
                              style: TextStyle(
                                fontSize: goalEmoji.isEmpty ? 18 : 80,
                                color: goalEmoji.isEmpty
                                    ? const Color.fromARGB(255, 110, 110, 110)
                                    : null,
                              ),
                            ),
                    ),
                  ),
                ),
              if (currentStep == 2)
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        goalDate =
                            "${pickedDate.day.toString().padLeft(2, '0')}."
                            "${pickedDate.month.toString().padLeft(2, '0')}."
                            "${pickedDate.year}";
                      });
                    }
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 60,
                    ),
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
                        goalDate.isEmpty ? S.of(context).nhv : goalDate,
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 110, 110, 110),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () async {
                  if (currentStep == 0) {
                    final name = goalNameController.text.trim();
                    if (name.isEmpty) {
                      _showError(S.of(context).vvedznach);
                      return;
                    }
                    setState(() {
                      goalName = name;
                      isEditingGoalName = false;
                      currentStep++;
                    });
                    return;
                  }

                  if (currentStep == 1) {
                    if (goalEmoji.trim().isEmpty) {
                      _showError(S.of(context).vvedznach);
                      return;
                    }
                    setState(() {
                      isEditingEmoji = false;
                      currentStep++;
                    });
                    return;
                  }

                  if (currentStep == 2) {
                    if (goalDate.isEmpty) {
                      _showError(S.of(context).vvedznach);
                      return;
                    }
                    await _saveAndFinish();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 120),
                  constraints: const BoxConstraints(minHeight: 50),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                        child: Text(
                          S.of(context).pro,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// this code was written by maksy