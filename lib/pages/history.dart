import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sight/adapters/transaction.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, List<Transaction>>> getTransactions({bool monthly = false}) async {
    var box = await Hive.openBox<Transaction>('transactions');
    List<Transaction> transactions = box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort in descending order

    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((transaction) =>
        transaction.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        transaction.targetAccount.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        transaction.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      String dateKey = monthly
          ? DateFormat('MMM yyyy').format(transaction.date)
          : DateFormat('dd MMM yy').format(transaction.date);
      
      if (!monthly && DateFormat('yyyy-MM-dd').format(transaction.date) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
        dateKey = 'Today';
      }
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }
    return groupedTransactions;
  }

  String formatRupiah(double value) {
    final formatter = NumberFormat.decimalPattern('id');
    return 'Rp ${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            if (!_isSearching)
              const Text(
                'History',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            if (_isSearching)
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = "";
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.blue,
          indicatorWeight: 3.0,
          indicator: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.blue, width: 3.0)),
          ),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList(monthly: false),
          _buildTransactionList(monthly: true),
        ],
      ),
    );
  }

  Widget _buildTransactionList({required bool monthly}) {
    return FutureBuilder<Map<String, List<Transaction>>>(
      future: getTransactions(monthly: monthly),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var groupedTransactions = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: groupedTransactions.entries.map((entry) {
            double total = entry.value.fold(0, (sum, item) => sum + item.amount);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(formatRupiah(total),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      Column(
                        children: entry.value.map((transaction) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: transaction.amount < 0 ? Colors.red : Colors.green,
                                      child: const Icon(FontAwesomeIcons.clock, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(transaction.category,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          transaction.description.isNotEmpty == true 
                                            ? "${transaction.targetAccount} - ${transaction.description}"
                                            : transaction.targetAccount,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(formatRupiah(transaction.amount),
                                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}