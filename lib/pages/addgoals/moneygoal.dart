import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/addgoals/general/made.dart';
import 'package:wave/storage/model/money_goal_model.dart';
import 'package:wave/storage/secure_money_goals.dart';

class MoneyGoal extends StatefulWidget {
  final MoneyGoalModel? existingGoal;

  const MoneyGoal({super.key, this.existingGoal});

  bool get isEditing => existingGoal != null;

  @override
  State<MoneyGoal> createState() => _MoneyGoalState();
}

class _MoneyGoalState extends State<MoneyGoal> {
  int currentStep = 0;
  bool isEditingMoneyGoalTarAmount = false;
  bool isEditingMoneyGoalCurAmount = false;
  String goalTargetAmount = "";
  String goalCurrentAmount = "";
  final TextEditingController goalTarAmountController = TextEditingController();
  final TextEditingController goalCurAmountController = TextEditingController();
  String MoneyGoalDate = "";

  String selectedCurrency = '\$';
  static const List<String> currencies = ['\$', '₽', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      goalTargetAmount = _formatAmount(existing.targetAmount);
      goalCurrentAmount = _formatAmount(existing.currentAmount);
      selectedCurrency = existing.currency;
      MoneyGoalDate = existing.targetDate;
      goalTarAmountController.text = goalTargetAmount;
      goalCurAmountController.text = goalCurrentAmount;
    }
  }

  String _formatAmount(double amount) {
    return amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...currencies.map((c) => ListTile(
                    title: Text(c, style: const TextStyle(fontSize: 18)),
                    trailing: c == selectedCurrency
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () {
                      setState(() => selectedCurrency = c);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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

  Future<void> _skipStep() async {
    if (currentStep == 1) {
      setState(() {
        goalCurrentAmount = "";
        goalCurAmountController.clear();
        isEditingMoneyGoalCurAmount = false;
        currentStep++;
      });
      return;
    }

    if (currentStep == 2) {
      MoneyGoalDate = "";
      await _saveAndFinish();
    }
  }

  Future<void> _saveAndFinish() async {
    final targetAmount = double.tryParse(goalTargetAmount) ?? 0;
    final currentAmount = double.tryParse(goalCurrentAmount) ?? 0;
    final progress = targetAmount > 0
        ? (currentAmount / targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final existing = widget.existingGoal;
    if (existing != null) {
      await SecureMoneyGoalsStorageService.updateGoal(
        existing.copyWith(
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          currency: selectedCurrency,
          targetDate: MoneyGoalDate,
          progress: progress,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    await SecureMoneyGoalsStorageService.saveGoal(
      MoneyGoalModel(
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        currency: selectedCurrency,
        targetDate: MoneyGoalDate,
        progress: progress,
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Made(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String title1;

    switch (currentStep) {
      case 0:
        title = S.of(context).clol;
        title1 = S.of(context).vpsum;
        break;

      case 1:
        title = S.of(context).ckolnak;
        title1 = S.of(context).vps;
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
        actions: (currentStep == 1 || currentStep == 2)
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
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isEditingMoneyGoalTarAmount = true;
                          goalTarAmountController.text = goalTargetAmount;
                        });
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 70),
                          child: Center(
                            child: isEditingMoneyGoalTarAmount
                                ? TextField(
                                    controller: goalTarAmountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    autofocus: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    onChanged: (value) => goalTargetAmount = value,
                                    onSubmitted: (value) {
                                      setState(() => isEditingMoneyGoalTarAmount = false);
                                    },
                                  )
                                : Text(
                                    goalTargetAmount.isEmpty ? S.of(context).vvedsum : goalTargetAmount,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 110, 110, 110),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _showCurrencyPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Center(
                            child: Text(
                              selectedCurrency,
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (currentStep == 1)
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isEditingMoneyGoalCurAmount = true;
                          goalCurAmountController.text = goalCurrentAmount;
                        });
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 70),
                          child: Center(
                            child: isEditingMoneyGoalCurAmount
                                ? TextField(
                                    controller: goalCurAmountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    autofocus: true,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    onChanged: (value) => goalCurrentAmount = value,
                                    onSubmitted: (value) {
                                      setState(() => isEditingMoneyGoalCurAmount = false);
                                    },
                                  )
                                : Text(
                                    goalCurrentAmount.isEmpty ? S.of(context).vvedsum : goalCurrentAmount,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 110, 110, 110),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Text(
                            selectedCurrency,
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
                        MoneyGoalDate =
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
                        MoneyGoalDate.isEmpty ? S.of(context).nhv : MoneyGoalDate,
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
                    final target = goalTarAmountController.text.trim();
                    if (target.isEmpty || (double.tryParse(target) ?? 0) <= 0) {
                      _showError(S.of(context).vvedznach);
                      return;
                    }
                    setState(() {
                      goalTargetAmount = target;
                      isEditingMoneyGoalTarAmount = false;
                      currentStep++;
                    });
                    return;
                  }

                  if (currentStep == 1) {
                    final target = double.tryParse(goalTarAmountController.text) ?? 0;
                    final current = double.tryParse(goalCurAmountController.text) ?? 0;
                    if (current > target) {
                      _showError(S.of(context).nakbols);
                      return;
                    }
                    setState(() {
                      goalCurrentAmount = goalCurAmountController.text;
                      isEditingMoneyGoalCurAmount = false;
                      currentStep++;
                    });
                    return;
                  }

                  if (currentStep == 2) {
                    if (MoneyGoalDate.isEmpty) {
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