import 'dart:io' show File;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/addgoals.dart';
import 'package:wave/storage/model/goal_model.dart';
import 'package:wave/storage/model/money_goal_model.dart';
import 'package:wave/pages/addgoals/moneygoal.dart';
import 'package:wave/pages/homepage/goals/moneygoal/moneygoalPage.dart';
import 'package:wave/pages/addgoals/regulargoal.dart';
import 'package:wave/pages/homepage/goals/regulargoal/regulargoalPage.dart';
import 'package:wave/pages/authpage.dart';
import 'package:wave/pages/homepage/planner/planner.dart';
import 'package:wave/pages/homepage/profile/help.dart';
import 'package:wave/pages/homepage/profile/profile.dart';
import 'package:wave/pages/homepage/profile/settingsapp.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:wave/services/data_sync_service.dart';
import 'package:wave/storage/secure.dart';
import 'package:wave/storage/secure_goals.dart';
import 'package:wave/storage/secure_money_goals.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  File? profileImage;
  int currentPageIndex = 0;
  String usrnm = "";
  String ml = "";
  Key avatarKey = UniqueKey();
  List<GoalModel> goals = [];
  List<MoneyGoalModel> moneyGoals = [];
  List<dynamic> allGoals = [];
  final GlobalKey<PlannerPageState> _plannerKey = GlobalKey<PlannerPageState>();

  String formatAmount(double amount) {
    return amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

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
    loadUser();
  }

  Future<void> _togglePinGoal(GoalModel goal) async {
    final updatedGoal = goal.copyWith(pinned: !goal.pinned);
    
    setState(() {
      int idx = allGoals.indexWhere((g) => g is GoalModel && g.id == goal.id);
      if (idx != -1) {
        allGoals[idx] = updatedGoal;
        allGoals.sort((a, b) => a.pinned == b.pinned ? 0 : (a.pinned ? -1 : 1));
      }
    });

    await SecureGoalsStorageService.updateGoal(updatedGoal);

    await DataSyncService.uploadSingleRegularGoal(updatedGoal);
  }

  Future<void> _togglePinMoneyGoal(MoneyGoalModel goal) async {
    final updatedGoal = goal.copyWith(pinned: !goal.pinned);
    
    setState(() {
      int idx = allGoals.indexWhere((g) => g is MoneyGoalModel && g.id == goal.id);
      if (idx != -1) {
        allGoals[idx] = updatedGoal;
        allGoals.sort((a, b) => a.pinned == b.pinned ? 0 : (a.pinned ? -1 : 1));
      }
    });

    await SecureMoneyGoalsStorageService.updateGoal(updatedGoal);
    await DataSyncService.uploadSingleMoneyGoal(updatedGoal);
  }

  void _runBackgroundSync() {
    DataSyncService.downloadAllDataFromServer().then((_) {
      if (mounted) {
        SecureGoalsStorageService.getGoals().then((loadedGoals) {
          SecureMoneyGoalsStorageService.getGoals().then((loadedMoneyGoals) {
            if (mounted) {
              setState(() {
                goals = loadedGoals;
                moneyGoals = loadedMoneyGoals;
                allGoals = [...loadedGoals, ...loadedMoneyGoals];
                allGoals.sort((a, b) => a.pinned == b.pinned ? 0 : (a.pinned ? -1 : 1));
              });
            }
          });
        });
      }
    }).catchError((e) {
      print('Background synchronization error: $e');
    });
  }

  Future<void> loadUser() async {

    final name = await SecureStorageService.getName();
    final mail = await SecureStorageService.getMail();
    final avatarFile = await SecureStorageService.getLocalAvatar();
    final loadedGoals = await SecureGoalsStorageService.getGoals();
    final loadedMoneyGoals = await SecureMoneyGoalsStorageService.getGoals();

    if (!mounted) return;
    if (avatarFile != null) {
      await FileImage(avatarFile).evict();
    }

    setState(() {
      usrnm = name ?? '';
      ml = mail ?? '';
      profileImage = avatarFile; 
      avatarKey = UniqueKey(); 
      goals = loadedGoals;
      moneyGoals = loadedMoneyGoals;
      allGoals = [...loadedGoals, ...loadedMoneyGoals];
      allGoals.sort((a, b) => a.pinned == b.pinned ? 0 : (a.pinned ? -1 : 1));
    });
  }

  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const AuthPage();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            currentPageIndex == 0
                ? S.of(context).goals
                : currentPageIndex == 1
                    ? S.of(context).planner
                    : S.of(context).profile,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: (currentPageIndex == 0 || currentPageIndex == 1)
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (currentPageIndex == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddGoals()),
                      );
                      loadUser();
                    }
                    if (currentPageIndex == 1) {
                      _plannerKey.currentState?.openAddTaskSheet();
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ]
          : null,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2F3238)
                  : const Color(0xFFE6E8EC),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          child: NavigationBar(
            height: 72,
            elevation: 0,
            backgroundColor: Theme.of(context).cardColor,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Colors.transparent,

            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,

            selectedIndex: currentPageIndex,

            onDestinationSelected: (index) {
              setState(() {
                currentPageIndex = index;
              });
            },

            destinations: [
              NavigationDestination(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Image.asset(
                    'assets/icons/pageicons/off/goalspage.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                selectedIcon: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Image.asset(
                    'assets/icons/pageicons/on/goalspage.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                label: S.of(context).pn1,
              ),

              NavigationDestination(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Image.asset(
                    'assets/icons/pageicons/off/plannerpage.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                selectedIcon: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Image.asset(
                    'assets/icons/pageicons/on/plannerpage.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                label: S.of(context).planner,
              ),

              NavigationDestination(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Image.asset(
                    'assets/icons/pageicons/off/profilepage.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                selectedIcon: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Image.asset(
                    'assets/icons/pageicons/on/profilepage.png',
                    width: 30,
                    height: 30,
                  ),
                ),
                label: S.of(context).profile,
              ),
            ],
          ),
        ),
      ),
      body: [
        RefreshIndicator(
          onRefresh: loadUser,
          child: allGoals.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              S.of(context).hr,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 110, 110, 110),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                // regular goal
              : ListView.builder(
                  itemCount: allGoals.length,
                  itemBuilder: (context, index) {
                    final item = allGoals[index];
                    if (item is GoalModel) {
                      final goal = item;
                      final isDone = goal.progress >= 1.0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: Dismissible(
                            key: Key('goal_${goal.id}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              await SecureGoalsStorageService.deleteGoal(goal.id);
                              await loadUser();
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 28),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            child: GestureDetector(
                              onLongPressStart: (details) async {
                                final selected = await showMenu(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(34),
                                  ),
                                  position: RelativeRect.fromLTRB(
                                    details.globalPosition.dx,
                                    details.globalPosition.dy,
                                    details.globalPosition.dx,
                                    details.globalPosition.dy,
                                  ),
                                  items: [
                                    PopupMenuItem(
                                      value: 'pin',
                                      child: Text(
                                        goal.pinned
                                            ? S.of(context).otkrp
                                            : S.of(context).zakrp,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        S.of(context).izmen,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'share',
                                      child: Text(
                                        S.of(context).pod,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                );

                                if (selected == 'pin') {
                                  await _togglePinGoal(goal);
                                }

                                if (selected == 'edit') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegularGoal(
                                        existingGoal: goal,
                                      ),
                                    ),
                                  );

                                  await loadUser();
                                }
                                if (selected == 'share') {
                                  await Share.share(
                                    '${S.of(context).sg} ${goal.name}\n'
                                    '${S.of(context).sp} ${(goal.progress * 100).toStringAsFixed(0)}%\n'
                                    '${S.of(context).sd} ${goal.date}',
                                  );
                                }
                              },
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RegularGoalPage(goal: goal)),
                                );
                                loadUser();
                              },
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 100),
                                padding: const EdgeInsets.only(left: 25, right: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                goal.emoji,
                                                style: const TextStyle(fontSize: 17),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        goal.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 17,
                                                          decoration: isDone
                                                              ? TextDecoration.lineThrough
                                                              : TextDecoration.none,
                                                        ),
                                                      ),
                                                    ),
                                                    if (goal.pinned)
                                                      const Padding(
                                                        padding: EdgeInsets.only(left: 3),
                                                        child: Icon(
                                                          Icons.push_pin,
                                                          size: 15,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 20),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: LinearProgressIndicator(
                                                value: goal.progress,
                                                minHeight: 6,
                                                backgroundColor:
                                                    Colors.grey.withOpacity(0.2),
                                                valueColor:
                                                    const AlwaysStoppedAnimation
                                                        <Color>(Colors.blue),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Text(
                                                '${(goal.progress * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color.fromARGB(
                                                      255, 110, 110, 110),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                "•",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Color.fromARGB(
                                                      255, 110, 110, 110),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                S.of(context).dd,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: _isDateExpired(goal.date)
                                                      ? Colors.red
                                                      : const Color.fromARGB(
                                                          255, 110, 110, 110),
                                                ),
                                              ),
                                              Text(
                                                goal.date,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: _isDateExpired(goal.date)
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
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: inset.BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).cardColor,
                                        boxShadow: [
                                          inset.BoxShadow(
                                            color: Theme.of(context).shadowColor,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                            inset: true,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '>',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // money goal
                      if (item is MoneyGoalModel) {
                        final moneyGoal = item;
                        final isDone = moneyGoal.progress >= 1.0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: Dismissible(
                              key: Key('money_${moneyGoal.id}'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) async {
                                await SecureMoneyGoalsStorageService.deleteGoal(moneyGoal.id);
                                await loadUser();
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 28),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                              ),
                              child: GestureDetector(
                                onLongPressStart: (details) async {
                                  final selected = await showMenu(
                                    context: context,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(34),
                                    ),
                                    position: RelativeRect.fromLTRB(
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                      details.globalPosition.dx,
                                      details.globalPosition.dy,
                                    ),
                                    items: [
                                      PopupMenuItem(
                                        value: 'pin',
                                        child: Text(
                                          moneyGoal.pinned
                                              ? S.of(context).otkrp
                                              : S.of(context).zakrp,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          S.of(context).izmen,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'share',
                                        child: Text(
                                          S.of(context).pod,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );

                                  if (selected == 'pin') {
                                    await _togglePinMoneyGoal(
                                      moneyGoal,
                                    );
                                  }

                                  if (selected == 'edit') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MoneyGoal(
                                          existingGoal: moneyGoal,
                                        ),
                                      ),
                                    );

                                    await loadUser();
                                  }
                                  if (selected == 'share') {
                                    await Share.share(
                                      '${S.of(context).smg} ${moneyGoal.currency}${formatAmount(moneyGoal.targetAmount)}\n'
                                      '${S.of(context).sumg} ${moneyGoal.currency}${formatAmount(moneyGoal.currentAmount)}\n'
                                      '${S.of(context).sp} ${(moneyGoal.progress * 100).toStringAsFixed(0)}%\n'
                                      '${S.of(context).sd} ${moneyGoal.targetDate}',
                                    );
                                  }
                                },
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => MoneyGoalPage(goal: moneyGoal)),
                                  );
                                  loadUser();
                                },
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 100),
                                  padding: const EdgeInsets.only(left: 25, right: 10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '💰',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  S.of(context).nak,
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    decoration: isDone
                                                        ? TextDecoration.lineThrough
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                '${moneyGoal.currency}${formatAmount(moneyGoal.targetAmount)}',
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  fontSize: 17,
                                                                  decoration: isDone
                                                                      ? TextDecoration.lineThrough
                                                                      : TextDecoration.none,
                                                                ),
                                                              ),
                                                            ),

                                                            if (moneyGoal.pinned)
                                                              const Padding(
                                                                padding: EdgeInsets.only(left: 3),
                                                                child: Icon(
                                                                  Icons.push_pin,
                                                                  size: 15,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(right: 20),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: LinearProgressIndicator(
                                                  value: moneyGoal.progress,
                                                  minHeight: 6,
                                                  backgroundColor:
                                                      Colors.grey.withOpacity(0.2),
                                                  valueColor:
                                                      const AlwaysStoppedAnimation
                                                          <Color>(Colors.blue),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Text(
                                                  '${(moneyGoal.progress * 100).toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Color.fromARGB(
                                                        255, 110, 110, 110),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                const Text(
                                                  "•",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color.fromARGB(
                                                        255, 110, 110, 110),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  S.of(context).dd,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: _isDateExpired(
                                                            moneyGoal.targetDate)
                                                        ? Colors.red
                                                        : const Color.fromARGB(
                                                            255, 110, 110, 110),
                                                  ),
                                                ),
                                                Text(
                                                  moneyGoal.targetDate,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: _isDateExpired(
                                                            moneyGoal.targetDate)
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
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: inset.BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context).cardColor,
                                          boxShadow: [
                                            inset.BoxShadow(
                                              color: Theme.of(context).shadowColor,
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                              inset: true,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '>',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    return const SizedBox.shrink();
                    }
                  }
                )
        ),

        PlannerPage(key: _plannerKey),
        
        Stack(
          children: [
            RefreshIndicator(
              onRefresh: loadUser,
              child: ListView(
                children: [

                  // profile
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                      if (context.mounted) {
                        loadUser(); 
                      }
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 100),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.only(left: 15, right: 10),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            key: avatarKey,
                            width: 70,
                            height: 70,
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
                                    size: 30,
                                    color: Color.fromARGB(255, 110, 110, 110),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  usrnm.isEmpty ? S.of(context).nnm : usrnm,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ml.isEmpty ? S.of(context).nml : ml,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Color.fromARGB(255, 110, 110, 110),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: inset.BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                inset.BoxShadow(
                                  color: Theme.of(context).shadowColor,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                  inset: true,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '>',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // settings
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsApp()),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            isDark
                                ? 'assets/icons/sectionicons/black/appsettingsblack.png'
                                : 'assets/icons/sectionicons/white/appsettingswhite.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).sttapp,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),

                  // help
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HelpForm()),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            isDark
                                ? 'assets/icons/sectionicons/black/helpblack.png'
                                : 'assets/icons/sectionicons/white/helpwhite.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.of(context).hlp,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 25, 
              child: ValueListenableBuilder<bool>(
                valueListenable: DataSyncService.isSyncing,
                builder: (context, isSyncing, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: InkWell(
                        onTap: () => _showEncryptionInfo(context),
                        borderRadius: BorderRadius.circular(34),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? const Color.fromARGB(255, 230, 230, 230).withOpacity(0.2) 
                                : const Color.fromARGB(255, 230, 230, 230).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.08) 
                                  : Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_rounded, 
                                color: Color.fromARGB(255, 110, 110, 110),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color.fromARGB(255, 110, 110, 110),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.cloud_done_rounded, 
                                      color: Color.fromARGB(255, 110, 110, 110), 
                                      size: 20, 
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ][currentPageIndex],
    );
  }
}
void _showEncryptionInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
    ),
    backgroundColor: Theme.of(context).cardColor,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 26),
                const SizedBox(width: 12),
                Text(
                  S.of(context).danzah,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).opiszah,
              style: TextStyle(color: Color.fromARGB(255, 110, 110, 110), fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

// this code was written by maksy