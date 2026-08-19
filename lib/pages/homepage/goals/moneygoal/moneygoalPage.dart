import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/storage/model/money_goal_model.dart';
import 'package:wave/storage/model/money_history_goal_model.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:wave/storage/secure_money_goals.dart';

class MoneyGoalPage extends StatefulWidget {
  final MoneyGoalModel goal;

  const MoneyGoalPage({super.key, required this.goal});

  @override
  State<MoneyGoalPage> createState() => _MoneyGoalPageState();
}

class _MoneyGoalPageState extends State<MoneyGoalPage> {
  late MoneyGoalModel goal;
  List<MoneyHistoryEntry> history = [];

  bool _isDateExpired(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length != 3) return false;
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      return date.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    goal = widget.goal;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final loaded = await SecureMoneyGoalsStorageService.getHistory(goal.id);
    if (!mounted) return;
    setState(() {
      history = loaded;
    });
  }

  String _formatAmount(double amount) {
    return amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return S.of(context).seg;
    if (entryDate == yesterday) return S.of(context).vhr;

    final months = [
      '',
      S.of(context).jan,
      S.of(context).feb,
      S.of(context).mar,
      S.of(context).apr,
      S.of(context).may,
      S.of(context).jun,
      S.of(context).jul,
      S.of(context).aug,
      S.of(context).sep,
      S.of(context).oct,
      S.of(context).nov,
      S.of(context).dec,
    ];
    return '${date.day} ${months[date.month]}';
  }

  void _showAmountDialog({required bool isAdding}) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          isAdding ? S.of(context).pop : S.of(context).otnt,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: S.of(context).vvedsum,
            hintStyle: const TextStyle(
              color: Color.fromARGB(255, 110, 110, 110),
            ),
            prefixText: '${goal.currency} ',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(34),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.4),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(34),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              S.of(context).ot,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context);
                _updateAmount(value, isAdding: isAdding);
              }
            },
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateAmount(double value, {required bool isAdding}) async {
    final newCurrent = isAdding
        ? (goal.currentAmount + value).clamp(0.0, goal.targetAmount)
        : (goal.currentAmount - value).clamp(0.0, goal.targetAmount);

    final newProgress = goal.targetAmount > 0
        ? (newCurrent / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final entry = MoneyHistoryEntry(
      amount: value,
      isAdding: isAdding,
      date: DateTime.now(),
      currency: goal.currency,
    );

    setState(() {
      goal = goal.copyWith(
        currentAmount: newCurrent,
        progress: newProgress,
      );
      history.insert(0, entry);
      if (history.length > 5) history = history.take(5).toList();
    });

    try {
      await SecureMoneyGoalsStorageService.updateGoal(goal);
      await SecureMoneyGoalsStorageService.addHistory(goal.id, entry);
    } catch (e) {
      print('Error updating goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = goal.progress >= 1.0;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 160),
              padding: const EdgeInsets.only(left: 30, right: 30),
              decoration: inset.BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  inset.BoxShadow(
                    color: Theme.of(context).shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                    inset: true,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 5),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${goal.currency}${_formatAmount(goal.currentAmount)}',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      decorationColor: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '/${goal.currency}${_formatAmount(goal.targetAmount)}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(
                                          255, 110, 110, 110),
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      decorationColor: const Color.fromARGB(
                                          255, 110, 110, 110),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(goal.progress * 100).toStringAsFixed(0)}%',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 110, 110, 110),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 110, 110, 110),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              S.of(context).dd,
                              style: TextStyle(
                                fontSize: 16,
                                color: _isDateExpired(goal.targetDate)
                                    ? Colors.red
                                    : const Color.fromARGB(
                                        255, 110, 110, 110),
                              ),
                            ),
                            Text(
                              goal.targetDate,
                              style: TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 16,
                                color: _isDateExpired(goal.targetDate)
                                    ? Colors.red
                                    : const Color.fromARGB(
                                        255, 110, 110, 110),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showAmountDialog(isAdding: true),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        S.of(context).pop,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(34),
                      ),
                      child: const Center(
                        child: Text(
                          '+',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              color: Colors.grey.withOpacity(0.3),
              thickness: 1,
              height: 16,
            ),
            GestureDetector(
              onTap: () => _showAmountDialog(isAdding: false),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        S.of(context).otnt,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(34),
                      ),
                      child: const Center(
                        child: Text(
                          '−',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              color: Colors.grey.withOpacity(0.3),
              thickness: 1,
              height: 16,
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.only(
                  top: 15, bottom: 10, left: 20, right: 20),
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
                  Center(
                    child: Text(
                      S.of(context).istr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: Colors.grey.withOpacity(0.3),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  history.isEmpty
                      ? Center(
                          child: Text(
                            S.of(context).netpop,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 110, 110, 110),
                            ),
                          ),
                        )
                      : Column(
                          children: history.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_formatDate(entry.date)}:',
                                      style:
                                          const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Text(
                                    '${entry.isAdding ? '+' : '−'}${_formatAmount(entry.amount)}${entry.currency}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: entry.isAdding
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// this code was written by maksy