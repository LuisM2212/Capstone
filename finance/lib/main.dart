import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oeocmjidkyifbizxreij.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9lb2Ntamlka3lpZmJpenhyZWlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwODM4NDksImV4cCI6MjA3ODY1OTg0OX0.WGP2YacE_WkYpM6AHnqU25y13G0NMIfNcHqiFdj52OY',
  );

  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const AuthPage(),
    );
  }
}

/// Transaction model
class Transaction {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String type;

  Transaction({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.type = 'expense',
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'].toString(),
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'].toString()),
      type: map['type'] as String? ?? 'expense',
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id, 
      'user_id': userId,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}

/// Budget model
class Budget {
  final String id;
  final String category;
  final double amount;
  final String period;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    this.period = 'monthly',
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'].toString(),
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String? ?? 'monthly',
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'period': period,
    };
  }
}


/// Auth page

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password required')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await _supabase.auth.signUp(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      // On success, go to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://oeocmjidkyifbizxreij.supabase.co/auth/v1/callback',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox and spam folder.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Welcome Back' : 'Create Account';
    final subtitle = _isLogin ? 'Sign in to continue' : 'Start tracking your finances';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Finance Tracker',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _isLogin ? 'Sign In' : 'Sign Up',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() => _isLogin = !_isLogin);
                            },
                            child: Text(
                              _isLogin
                                  ? "Don't have an account? Sign up"
                                  : "Already have an account? Log in",
                            ),
                          ),
                          if (_isLogin)
                            TextButton(
                              onPressed: _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                        ],
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
}

/// Dashboard

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final List<Transaction> _transactions = [];
  final List<Budget> _budgets = [];
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedFilter;
  String _selectedPeriod = 'This Month';
  String _selectedType = 'expense';
  String _sortBy = 'date';
  bool _sortAscending = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _loadingTxns = false;
  bool _loadingBudgets = false;
  late TabController _tabController;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
    _loadBudgets();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('No logged in user');
    }
    // Ensure we return the UUID as a string
    final userId = user.id;
    // Check if it's valid UUID format
    if (userId.isEmpty) {
      throw StateError('User ID is empty');
    }
    return userId;
  }


  Future<void> _loadTransactions() async {
    setState(() => _loadingTxns = true);
    try {
      final rows = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', _userId)
          .order('date', ascending: false);

      final txns = (rows as List)
          .map((row) => Transaction.fromMap(row as Map<String, dynamic>))
          .toList();

      setState(() {
        _transactions
          ..clear()
          ..addAll(txns);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transactions: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingTxns = false);
    }
  }

  Future<void> _loadBudgets() async {
    setState(() => _loadingBudgets = true);
    try {
      final rows = await _supabase.from('budgets').select().eq('user_id', _userId);
      final budgets = (rows as List).map((row) => Budget.fromMap(row as Map<String, dynamic>)).toList();
      setState(() {
        _budgets..clear()..addAll(budgets);
      });
    } catch (e) {
    } finally {
      if (mounted) setState(() => _loadingBudgets = false);
    }
  }


  Future<void> _addTransaction() async {
    final category = _categoryController.text.trim();
    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);

    // Validation
    if (category.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (amountStr.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount (greater than 0)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final userId = _userId;
      
   
      final dataToInsert = <String, dynamic>{
        'user_id': userId, 
        'category': category,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'type': _selectedType,
      };
      
      await _supabase.from('transactions').insert(dataToInsert);

      // Reload transactions to get the latest from DB
      await _loadTransactions();

      _categoryController.clear();
      _amountController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType == 'income' ? 'Income' : 'Expense'} added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showBudgetDialog({Budget? budget}) async {
    final catCtrl = TextEditingController(text: budget?.category ?? '');
    final amtCtrl = TextEditingController(text: budget?.amount.toStringAsFixed(2) ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(budget == null ? "Set Budget" : "Edit Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: "Monthly Budget"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final cat = catCtrl.text.trim();
              final amt = double.tryParse(amtCtrl.text);
              if (cat.isEmpty || amt == null || amt <= 0) {
                Navigator.pop(context, false);
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != true) return;

    final cat = catCtrl.text.trim();
    final amt = double.tryParse(amtCtrl.text) ?? 0.0;

    try {
      if (budget == null) {
        final newBudget = Budget(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          category: cat,
          amount: amt,
        );
        await _supabase.from('budgets').insert(newBudget.toMap(_userId));
        setState(() => _budgets.add(newBudget));
      } else {
        final updated = Budget(id: budget.id, category: cat, amount: amt, period: budget.period);
        await _supabase.from('budgets').update(updated.toMap(_userId)).eq('id', budget.id).eq('user_id', _userId);
        setState(() {
          final idx = _budgets.indexWhere((b) => b.id == budget.id);
          if (idx != -1) _budgets[idx] = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${budget == null ? 'add' : 'update'} budget: $e')),
        );
      }
    }
  }

  Future<void> _addBudget() => _showBudgetDialog();

  Future<void> _editBudget(Budget budget) => _showBudgetDialog(budget: budget);

  Future<void> _deleteBudget(Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Delete budget for ${budget.category}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('budgets').delete().eq('id', budget.id).eq('user_id', _userId);
      setState(() => _budgets.removeWhere((b) => b.id == budget.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete budget: $e')),
        );
      }
    }
  }

  Future<void> _editTransaction(int index, Transaction t) async {
    final catCtrl = TextEditingController(text: t.category);
    final amtCtrl = TextEditingController(text: t.amount.toStringAsFixed(2));
    DateTime d = t.date;
    String selectedType = t.type;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setDialogState(() {
                    selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: amtCtrl,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final nd = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (nd != null) {
                    setDialogState(() => d = nd);
                  }
                },
                child: Text("Date: ${"${d.toLocal()}".split(" ")[0]}"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newCat = catCtrl.text.trim();
                final newAmt = double.tryParse(amtCtrl.text);
                if (newCat.isEmpty || newAmt == null || newAmt <= 0) return;

                final updated = Transaction(
                  id: t.id,
                  category: newCat,
                  amount: newAmt,
                  date: d,
                  type: selectedType,
                );

                try {
                  await _supabase
                      .from('transactions')
                      .update(updated.toMap(_userId))
                      .eq('id', t.id)
                      .eq('user_id', _userId);

                  setState(() {
                    _transactions[index] = updated;
                  });

                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete ${t.category}: \$${t.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('transactions').delete().eq('id', t.id).eq('user_id', _userId);
      setState(() => _transactions.removeWhere((x) => x.id == t.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Widget _buildExpenseLineChart(List<Transaction> expenses) {
    final dailyExpenses = <DateTime, double>{};
    for (final e in expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      dailyExpenses[d] = (dailyExpenses[d] ?? 0) + e.amount;
    }
    
    final sortedDates = dailyExpenses.keys.toList()..sort();
    if (sortedDates.isEmpty) return const Center(child: Text('No expense data available'));
    
    final maxExp = dailyExpenses.values.reduce((a, b) => a > b ? a : b);
    final minExp = dailyExpenses.values.reduce((a, b) => a < b ? a : b);
    final spots = sortedDates.asMap().entries.map((e) => FlSpot(e.key.toDouble(), dailyExpenses[e.value] ?? 0.0)).toList();
    final maxX = (sortedDates.length - 1).toDouble();
    final yRange = maxExp - minExp;
    final yPad = yRange > 0 ? yRange * 0.1 : maxExp * 0.1;
    final minY = (minExp - yPad).clamp(0.0, double.infinity);
    final maxY = maxExp + yPad;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: sortedDates.length > 7 ? (maxX / 6).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  final date = sortedDates[index];
                  // Show more detailed date format if there are many data points
                  if (sortedDates.length > 14) {
                    return Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 9),
                    );
                  } else {
                    return Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBgColor: Colors.grey[800]!,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx >= 0 && idx < sortedDates.length) {
                  final d = sortedDates[idx];
                  final amt = dailyExpenses[d] ?? 0.0;
                  return LineTooltipItem(
                    '\$${amt.toStringAsFixed(2)}\n${d.month}/${d.day}/${d.year}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red.shade700,
            barWidth: 3.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.red.shade700,
                  strokeWidth: 2.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.withValues(alpha: 0.3),
                  Colors.red.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildCategorySections(
      List<Transaction> txns, String type) {
    final totals = <String, double>{};
    for (final t in txns.where((t) => t.type == type)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    
    final total = totals.values.fold<double>(0.0, (sum, val) => sum + val);
    
    final colors = type == 'income' 
        ? [
            Colors.green.shade400,
            Colors.green.shade600,
            Colors.teal.shade400,
            Colors.teal.shade600,
            Colors.lightGreen.shade400,
            Colors.lightGreen.shade600,
            Colors.greenAccent.shade400,
            Colors.greenAccent.shade700,
            Colors.cyan.shade400,
            Colors.cyan.shade600,
          ]
        : [
            Colors.red.shade400,
            Colors.red.shade600,
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.deepOrange.shade400,
            Colors.deepOrange.shade600,
            Colors.pink.shade400,
            Colors.pink.shade600,
            Colors.amber.shade600,
            Colors.brown.shade400,
          ];
    
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    int colorIdx = 0;
    return sortedEntries.map((e) {
      final clr = colors[colorIdx % colors.length];
      colorIdx++;
      final pct = total > 0 ? (e.value / total * 100) : 0.0;
      
      return PieChartSectionData(
        value: e.value,
        title: pct >= 5.0 
            ? '${e.key}\n${pct.toStringAsFixed(1)}%\n\$${e.value.toStringAsFixed(0)}'
            : '',
        radius: 70,
        color: clr,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: pct < 5.0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: clr,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  e.key.length > 4 ? '${e.key.substring(0, 4)}...' : e.key,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }


  List<Transaction> _applyFilters() {
    Iterable<Transaction> result = _transactions;

    if (_selectedType != 'all') {
      result = result.where((t) => t.type == _selectedType);
    }

    final now = DateTime.now();
    if (_selectedPeriod == 'This Month') {
      result = result.where((t) => t.date.year == now.year && t.date.month == now.month);
    } else if (_selectedPeriod == 'Custom' && _customStartDate != null && _customEndDate != null) {
      result = result.where((t) => 
        t.date.isAfter(_customStartDate!.subtract(const Duration(days: 1))) && 
        t.date.isBefore(_customEndDate!.add(const Duration(days: 1)))
      );
    }

    if (_selectedFilter != null) {
      result = result.where((t) => t.category == _selectedFilter);
    }

    final sorted = result.toList();
    sorted.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'date':
        default:
          comparison = a.date.compareTo(b.date);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTxns = _applyFilters();
    final expenses = filteredTxns.where((t) => t.type == 'expense').toList();
    final income = filteredTxns.where((t) => t.type == 'income').toList();

    final totalExpenses = expenses.fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold<double>(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalIncome - totalExpenses;

    final expenseSections = _buildCategorySections(filteredTxns, 'expense');
    final incomeSections = _buildCategorySections(filteredTxns, 'income');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Finance Tracker",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTransactions();
              _loadBudgets();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (_) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
            Tab(icon: Icon(Icons.savings), text: 'Budgets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(
              filteredTxns, totalIncome, totalExpenses, netAmount, expenseSections, incomeSections),
          _buildTransactionsTab(filteredTxns),
          _buildBudgetsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildOverviewTab(List<Transaction> txns, double totalIncome,
      double totalExpenses, double netAmount, List<PieChartSectionData> expenseSections, List<PieChartSectionData> incomeSections) {
    final expenses = txns.where((t) => t.type == 'expense').toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Income',
                  totalIncome,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Expenses',
                  totalExpenses,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Net Amount',
            netAmount,
            netAmount >= 0 ? Colors.blue : Colors.orange,
            Icons.account_balance,
            isLarge: true,
          ),
          const SizedBox(height: 24),

          // Budget Progress
          if (_budgets.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget Progress',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final monthExpenses = _transactions
                        .where((t) => 
                            t.type == 'expense' && 
                            t.date.year == now.year && 
                            t.date.month == now.month)
                        .toList();
                    
                    double totalBudget = 0;
                    double totalSpent = 0;
                    
                    for (final b in _budgets) {
                      totalBudget += b.amount;
                      final spent = monthExpenses
                          .where((t) => t.category == b.category)
                          .fold<double>(0.0, (sum, t) => sum + t.amount);
                      totalSpent += spent;
                    }
                    
                    final overallPct = totalBudget > 0 
                        ? (totalSpent / totalBudget * 100).clamp(0.0, double.infinity)
                        : 0.0;
                    
                    return Chip(
                      label: Text(
                        '${overallPct.toStringAsFixed(1)}% used',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: overallPct > 100 
                              ? Colors.red.shade700 
                              : overallPct >= 80 
                                  ? Colors.orange.shade700 
                                  : Colors.green.shade700,
                        ),
                      ),
                      backgroundColor: overallPct > 100 
                          ? Colors.red.shade50 
                          : overallPct >= 80 
                              ? Colors.orange.shade50 
                              : Colors.green.shade50,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final budget in _budgets)
              Builder(
                builder: (context) {
                  final spent = expenses
                      .where((t) => t.category == budget.category)
                      .fold<double>(0.0, (sum, t) => sum + t.amount);
                  final percentage = (spent / budget.amount * 100).clamp(0.0, 100.0);
                  return _buildBudgetCard(budget, spent, percentage);
                },
              ),
            const SizedBox(height: 24),
          ],

          // Charts
          // Expense Trend Line Chart
          if (expenses.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Trend${_selectedPeriod == 'This Month' ? ' (This Month)' : _selectedPeriod == 'All' ? ' (All Time)' : ' ($_selectedPeriod)'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: _buildExpenseLineChart(expenses),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (expenseSections.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expenses by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: expenseSections,
                                centerSpaceRadius: 60,
                                sectionsSpace: 3,
                                pieTouchData: PieTouchData(
                                  enabled: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: expenseSections.take(5).map((section) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: section.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          section.title.split('\n')[0],
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (incomeSections.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Income by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: incomeSections,
                                centerSpaceRadius: 60,
                                sectionsSpace: 3,
                                pieTouchData: PieTouchData(
                                  enabled: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: incomeSections.take(5).map((section) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: section.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          section.title.split('\n')[0],
                                          style: const TextStyle(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon,
      {bool isLarge = false}) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isLarge ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Icon(icon, color: color, size: isLarge ? 28 : 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isLarge ? 28 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, double spent, double percentage) {
    final isOverBudget = spent > budget.amount;
    final isNearLimit = percentage >= 80 && percentage <= 100;
    final remaining = budget.amount - spent;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverBudget 
          ? Colors.red.shade50 
          : isNearLimit 
              ? Colors.orange.shade50 
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${spent.toStringAsFixed(2)} / \$${budget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _editBudget(budget);
                    } else if (val == 'delete') {
                      _deleteBudget(budget);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 100.0) / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget 
                    ? Colors.red.shade700 
                    : isNearLimit 
                        ? Colors.orange.shade700 
                        : Colors.green.shade700,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isOverBudget 
                        ? Colors.red.shade700 
                        : isNearLimit 
                            ? Colors.orange.shade700 
                            : Colors.grey[600],
                  ),
                ),
                Text(
                  remaining >= 0 
                      ? '\$${remaining.toStringAsFixed(2)} remaining'
                      : '\$${(-remaining).toStringAsFixed(2)} over',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: remaining >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 4),
              Text(
                'Budget exceeded by \$${(-remaining).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else if (isNearLimit) ...[
              const SizedBox(height: 4),
              Text(
                'Approaching budget limit',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(List<Transaction> txns) {
    return Column(
      children: [
        // Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('Expenses')),
                        ButtonSegment(value: 'income', label: Text('Income')),
                        ButtonSegment(value: 'all', label: Text('All')),
                      ],
                      selected: {_selectedType == 'all' ? 'all' : _selectedType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          final val = newSelection.first;
                          _selectedType = val == 'all' ? 'all' : val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPeriod,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All time')),
                        DropdownMenuItem(value: 'This Month', child: Text('This month')),
                        DropdownMenuItem(value: 'Custom', child: Text('Custom range')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPeriod = val;
                            if (val == 'Custom' && _customStartDate == null) {
                              _customStartDate = DateTime.now().subtract(const Duration(days: 30));
                              _customEndDate = DateTime.now();
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Category"),
                      value: _selectedFilter,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All categories')),
                        ...txns.map((t) => t.category).toSet().map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (value) => setState(() => _selectedFilter = value),
                    ),
                  ),
                ],
              ),
              if (_selectedPeriod == 'Custom') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_customStartDate != null ? '${_customStartDate!.month}/${_customStartDate!.day}/${_customStartDate!.year}' : 'Start Date'),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _customStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setState(() => _customStartDate = d);
                        },
                      ),
                    ),
                    const Text(' to '),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_customEndDate != null ? '${_customEndDate!.month}/${_customEndDate!.day}/${_customEndDate!.year}' : 'End Date'),
                        onPressed: () async {
                          final d = await showDatePicker(context: context, initialDate: _customEndDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setState(() => _customEndDate = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                        DropdownMenuItem(value: 'amount', child: Text('Sort by Amount')),
                        DropdownMenuItem(value: 'category', child: Text('Sort by Category')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () => setState(() => _sortAscending = !_sortAscending),
                    tooltip: _sortAscending ? 'Ascending' : 'Descending',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingTxns
              ? const Center(child: CircularProgressIndicator())
              : txns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: txns.length,
                      itemBuilder: (context, i) {
                        final t = txns[i];
                        final origIndex =
                            _transactions.indexWhere((x) => x.id == t.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(t.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              if (origIndex != -1) _deleteTransaction(t);
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: t.type == 'income'
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                child: Icon(
                                  t.type == 'income'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: t.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                t.category,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                t.date.toLocal().toString().split(' ')[0],
                              ),
                              trailing: Text(
                                '${t.type == 'income' ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: t.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              onTap: () {
                                if (origIndex != -1) _editTransaction(origIndex, t);
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildBudgetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budgets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addBudget,
                icon: const Icon(Icons.add),
                label: const Text('Add Budget'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_budgets.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets set yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add a budget to track your spending'),
                ],
              ),
            )
          else
            for (final budget in _budgets)
              Builder(
                builder: (context) {
                  final spent = _transactions
                      .where((t) =>
                          t.category == budget.category && t.type == 'expense')
                      .fold<double>(0.0, (sum, t) => sum + t.amount);
                  final percentage = (spent / budget.amount * 100).clamp(0.0, 100.0);
                  return _buildBudgetCard(budget, spent, percentage);
                },
              ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    _categoryController.clear();
    _amountController.clear();
    String dialogSelectedType = 'expense';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {dialogSelectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setDialogState(() {
                    dialogSelectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _selectedType = dialogSelectedType;
                _addTransaction();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
