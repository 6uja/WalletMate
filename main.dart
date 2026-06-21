import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const WalletMateApp());
}

const Color mainPurple = Color(0xff7C5CFF);
const Color lightBg = Color(0xffF7F7FB);
const String appIconPath = 'images/app_icon.png';

class WalletMateApp extends StatefulWidget {
  const WalletMateApp({super.key});

  @override
  State<WalletMateApp> createState() => _WalletMateAppState();
}

class _WalletMateAppState extends State<WalletMateApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WalletMate',
      debugShowCheckedModeBanner: false,

      // 날짜 선택 / 달력 한국어 오류 해결
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: lightBg,
        colorSchemeSeed: mainPurple,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff111827),
        colorSchemeSeed: mainPurple,
      ),
      home: MainPage(
        isDark: isDark,
        onThemeToggle: () {
          setState(() {
            isDark = !isDark;
          });
        },
      ),
    );
  }
}

class MoneyItem {
  final String title;
  final int amount;
  final String category;
  final String emoji;
  final DateTime date;
  final bool isIncome;

  MoneyItem({
    required this.title,
    required this.amount,
    required this.category,
    required this.emoji,
    required this.date,
    required this.isIncome,
  });
}

String money(int value) {
  return NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
    decimalDigits: 0,
  ).format(value);
}

String shortDate(DateTime date) {
  return DateFormat('yyyy.MM.dd').format(date);
}

class MainPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;

  const MainPage({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<MoneyItem> items = [
    MoneyItem(
      title: '스타벅스',
      amount: 5200,
      category: '카페',
      emoji: '☕',
      date: DateTime.now(),
      isIncome: false,
    ),
    MoneyItem(
      title: '맥도날드',
      amount: 8900,
      category: '식비',
      emoji: '🍔',
      date: DateTime.now(),
      isIncome: false,
    ),
    MoneyItem(
      title: '지하철',
      amount: 1250,
      category: '교통',
      emoji: '🚇',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isIncome: false,
    ),
    MoneyItem(
      title: '알바비',
      amount: 150000,
      category: '알바',
      emoji: '💰',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isIncome: true,
    ),
  ];

  int get income {
    return items.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);
  }

  int get expense {
    return items.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);
  }

  int get balance => income - expense;

  void addItem(MoneyItem item) {
    setState(() {
      items.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        items: items,
        balance: balance,
        income: income,
        expense: expense,
        isDark: widget.isDark,
        onThemeToggle: widget.onThemeToggle,
        onGoOcr: () => setState(() => currentIndex = 4),
      ),
      CalendarScreen(items: items),
      ChartScreen(items: items),
      AddScreen(onAdd: addItem),
      OcrScreen(onAdd: addItem),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).cardColor,
        elevation: 12,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavIcon(
                icon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => setState(() => currentIndex = 0),
              ),
              NavIcon(
                icon: Icons.calendar_month_rounded,
                selected: currentIndex == 1,
                onTap: () => setState(() => currentIndex = 1),
              ),
              NavIcon(
                icon: Icons.add_rounded,
                selected: currentIndex == 3,
                onTap: () => setState(() => currentIndex = 3),
              ),
              NavIcon(
                icon: Icons.bar_chart_rounded,
                selected: currentIndex == 2,
                onTap: () => setState(() => currentIndex = 2),
              ),
              NavIcon(
                icon: Icons.receipt_long_rounded,
                selected: currentIndex == 4,
                onTap: () => setState(() => currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const NavIcon({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 25,
        color: selected ? mainPurple : Colors.grey,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppIconBox extends StatelessWidget {
  final double size;

  const AppIconBox({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        appIconPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: mainPurple,
            child: const Text(
              'W',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<MoneyItem> items;
  final int balance;
  final int income;
  final int expense;
  final bool isDark;
  final VoidCallback onThemeToggle;
  final VoidCallback onGoOcr;

  const HomeScreen({
    super.key,
    required this.items,
    required this.balance,
    required this.income,
    required this.expense,
    required this.isDark,
    required this.onThemeToggle,
    required this.onGoOcr,
  });

  @override
  Widget build(BuildContext context) {
    const budget = 1000000;
    final progress = expense / budget;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        children: [
          Row(
            children: [
              const AppIconBox(size: 38),
              const SizedBox(width: 12),
              const Text(
                'WalletMate',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: onThemeToggle,
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [mainPurple, Color(0xff6B4EFF)],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '총 잔액',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '이번 달 잔액',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const AppIconBox(size: 72),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  value: money(income),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  value: money(expense),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '이번 달 예산',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text('${money(expense)} / ${money(budget)}'),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(30),
                  backgroundColor: Colors.grey.withOpacity(0.18),
                  valueColor: const AlwaysStoppedAnimation(mainPurple),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${(progress * 100).toStringAsFixed(0)}%'),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onGoOcr,
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: mainPurple.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: mainPurple,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '영수증 스캔하기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '영수증을 찍어서 자동으로 입력해보세요',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                '최근 거래 내역',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Spacer(),
              Text(
                '전체보기',
                style: TextStyle(
                  color: mainPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.reversed.map((e) => MoneyTile(item: e)),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.13),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoneyTile extends StatelessWidget {
  final MoneyItem item;

  const MoneyTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final Color color = item.isIncome ? Colors.green : mainPurple;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withOpacity(0.14),
            child: Text(item.emoji, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  item.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.isIncome
                    ? '+${money(item.amount)}'
                    : '-${money(item.amount)}',
                style: TextStyle(
                  color: item.isIncome ? Colors.green : Colors.black87,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('MM월 dd일').format(item.date),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddScreen extends StatefulWidget {
  final Function(MoneyItem) onAdd;

  const AddScreen({super.key, required this.onAdd});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final amountController = TextEditingController();
  final titleController = TextEditingController();

  bool isIncome = false;
  DateTime selectedDate = DateTime.now();

  String selectedCategory = '식비';
  String selectedEmoji = '🍔';

  final expenseCategories = [
    ['식비', '🍔'],
    ['카페', '☕'],
    ['교통', '🚇'],
    ['쇼핑', '🛍️'],
    ['생활', '🏠'],
    ['영화', '🎬'],
    ['자동차', '🚗'],
    ['화장품', '💄'],
    ['통신', '📞'],
    ['여행', '✈️'],
    ['공부', '🎓'],
    ['책', '📚'],
    ['운동', '⚽'],
    ['반려동물', '🐶'],
  ];

  final incomeCategories = [
    ['월급', '💰'],
    ['알바', '🪙'],
    ['용돈', '🎁'],
    ['투자수익', '📈'],
    ['환급금', '💵'],
    ['기타수입', '🏦'],
  ];

  List<List<String>> get currentCategories {
    return isIncome ? incomeCategories : expenseCategories;
  }

  void changeType(bool value) {
    setState(() {
      isIncome = value;
      selectedCategory = currentCategories.first[0];
      selectedEmoji = currentCategories.first[1];
    });
  }

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('ko', 'KR'),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  void save() {
    final amount = int.tryParse(amountController.text.trim()) ?? 0;
    final title = titleController.text.trim().isEmpty
        ? selectedCategory
        : titleController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 입력해주세요.')),
      );
      return;
    }

    widget.onAdd(
      MoneyItem(
        title: title,
        amount: amount,
        category: selectedCategory,
        emoji: selectedEmoji,
        date: selectedDate,
        isIncome: isIncome,
      ),
    );

    titleController.clear();
    amountController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = currentCategories;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 90),
        children: [
          const Text(
            '내역 추가',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
          ),
          const SizedBox(height: 22),
          SegmentedButton<bool>(
            selected: {isIncome},
            segments: const [
              ButtonSegment(value: false, label: Text('지출')),
              ButtonSegment(value: true, label: Text('수입')),
            ],
            onSelectionChanged: (value) => changeType(value.first),
          ),
          const SizedBox(height: 24),
          const Text(
            '장르 선택',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final item = categories[index];
              final selected = selectedCategory == item[0];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = item[0];
                    selectedEmoji = item[1];
                  });
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                      selected ? mainPurple : Theme.of(context).cardColor,
                      child: Text(
                        item[1],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item[0],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? mainPurple : null,
                        fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: '내용을 입력해주세요',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '가격을 입력해주세요',
              suffixText: '₩',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text(
                    '날짜 선택',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    shortDate(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_month_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: mainPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: save,
              child: const Text('저장하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final List<MoneyItem> items;

  const CalendarScreen({super.key, required this.items});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  List<MoneyItem> get selectedItems {
    return widget.items.where((e) {
      return e.date.year == selectedDay.year &&
          e.date.month == selectedDay.month &&
          e.date.day == selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 90),
        children: [
          const Text(
            '달력',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime(2020),
              lastDay: DateTime(2035),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: mainPurple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xffC4B5FD),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${DateFormat('yyyy년 MM월 dd일').format(selectedDay)} 내역',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 12),
          if (selectedItems.isEmpty)
            const AppCard(child: Text('이 날짜에는 내역이 없습니다.')),
          ...selectedItems.map((e) => MoneyTile(item: e)),
        ],
      ),
    );
  }
}

class ChartScreen extends StatelessWidget {
  final List<MoneyItem> items;

  const ChartScreen({super.key, required this.items});

  Map<String, int> get categoryData {
    final Map<String, int> result = {};

    for (final item in items.where((e) => !e.isIncome)) {
      result[item.category] = (result[item.category] ?? 0) + item.amount;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = categoryData;
    final total = data.values.fold(0, (sum, value) => sum + value);

    final chartColors = [
      mainPurple,
      const Color(0xff3B82F6),
      const Color(0xff22C55E),
      const Color(0xffFFA726),
      const Color(0xffFF5C8A),
      const Color(0xff14B8A6),
      const Color(0xffF97316),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 90),
        children: [
          const Text(
            '통계',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '카테고리별 지출',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 270,
                  child: total == 0
                      ? const Center(child: Text('지출 데이터가 없습니다.'))
                      : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 70,
                          sectionsSpace: 3,
                          sections:
                          data.entries.toList().asMap().entries.map(
                                (entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final percent = item.value / total * 100;
                              final color =
                              chartColors[index % chartColors.length];

                              return PieChartSectionData(
                                value: item.value.toDouble(),
                                color: color,
                                radius: 78,
                                title: '${percent.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '총 지출',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            money(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
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
          ...data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percent = total == 0 ? 0.0 : item.value / total;
            final color = chartColors[index % chartColors.length];

            return AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.16),
                    child: Icon(Icons.category_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(money(item.value)),
                  const SizedBox(width: 12),
                  Text('${(percent * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class OcrScreen extends StatefulWidget {
  final Function(MoneyItem) onAdd;

  const OcrScreen({super.key, required this.onAdd});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? image;
  String text = '';
  int amount = 0;
  String store = '영수증 지출';

  Future<void> scanReceipt() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);

    if (picked == null) return;

    final file = File(picked.path);
    final inputImage = InputImage.fromFile(file);
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final result = await recognizer.processImage(inputImage);

    await recognizer.close();

    setState(() {
      image = file;
      text = result.text;
      amount = extractAmount(result.text);
      store = extractStore(result.text);
    });
  }

  int extractAmount(String value) {
    final regex = RegExp(r'([0-9]{1,3}(,[0-9]{3})+|[0-9]{4,})');
    final matches = regex.allMatches(value);

    int max = 0;

    for (final m in matches) {
      final number = int.tryParse(m.group(0)!.replaceAll(',', '')) ?? 0;

      if (number > max && number < 10000000) {
        max = number;
      }
    }

    return max;
  }

  String extractStore(String value) {
    final lines = value.split('\n').where((e) => e.trim().isNotEmpty).toList();

    if (lines.isEmpty) return '영수증 지출';

    return lines.first;
  }

  String autoCategory(String value) {
    if (value.contains('스타벅스') || value.contains('카페')) return '카페';
    if (value.contains('버거') || value.contains('식당')) return '식비';
    if (value.contains('GS25') || value.contains('CU')) return '생활';
    return '기타';
  }

  void save() {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인식된 금액이 없습니다.')),
      );
      return;
    }

    widget.onAdd(
      MoneyItem(
        title: store,
        amount: amount,
        category: autoCategory(text),
        emoji: '🧾',
        date: DateTime.now(),
        isIncome: false,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OCR 결과가 저장되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 90),
        children: [
          const Text(
            '영수증 OCR',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: scanReceipt,
            child: Container(
              height: 285,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: mainPurple.withOpacity(0.25)),
              ),
              child: image == null
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: mainPurple,
                      size: 54,
                    ),
                    SizedBox(height: 10),
                    Text('영수증 촬영하기'),
                  ],
                ),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.file(image!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '인식 결과',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                Text('가게명  $store'),
                const SizedBox(height: 8),
                Text('금액  ${money(amount)}'),
                const SizedBox(height: 8),
                Text('카테고리  ${autoCategory(text)}'),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: mainPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: save,
              child: const Text('가계부에 저장'),
            ),
          ),
        ],
      ),
    );
  }
}