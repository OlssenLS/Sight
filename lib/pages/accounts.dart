import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sight/adapters/account.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowInitialBalanceModal();
    });
  }

  Future<void> _checkAndShowInitialBalanceModal() async {
    var box = await Hive.openBox<Account>('accounts');
    if (box.isEmpty) {
      showInitialBalanceModal(context);
    } else {
      setState(() {});
    }
  }

  Future<double> getTotalBalance() async {
    var box = await Hive.openBox<Account>('accounts');
    double total = 0;
    for (var account in box.values) {
      total += account.balance;
    }
    return total;
  }

  void showInitialBalanceModal(BuildContext context) {
    for (var account in ['Cash', 'BCA', 'Mandiri', 'Gopay', 'Ovo']) {
      _controllers[account] = TextEditingController();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Initial Balances"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var account in ['Cash', 'BCA', 'Mandiri', 'Gopay', 'Ovo'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: _controllers[account],

                      decoration: InputDecoration(
                        labelText: "$account Balance",
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          String numericValue = value.replaceAll('.', '');
                          double number = double.tryParse(numericValue) ?? 0;
                          final formatter = NumberFormat('#,###', 'id');
                          String formatted = formatter.format(number).replaceAll(',', '.');
                          _controllers[account]!.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              onPressed: () async {
                var box = await Hive.openBox<Account>('accounts');
                  for (var account in _controllers.keys) {
                    String numericValue = _controllers[account]!.text.replaceAll('.', '');
                    double balance = double.tryParse(numericValue) ?? 0;
                    box.put(account, Account(name: account, balance: balance));
                  }
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text("Done"),
            ),
          ],
        );
      },

    );  }

  String formatRupiah(double value) {
    final formatter = NumberFormat.decimalPattern('id');
    return 'Rp ${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Accounts',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 25),
            FutureBuilder<double>(
              future: getTotalBalance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Card(
                  color: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Balance:',
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                        Text(
                          formatRupiah(snapshot.data ?? 0.0),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Expanded(
              child: FutureBuilder<Box<Account>>(
                future: Hive.openBox<Account>('accounts'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var accounts = [
                    {'name': 'Cash', 'icon': FontAwesomeIcons.moneyBillWave, 'color': Colors.green},
                    {'name': 'BCA', 'icon': FontAwesomeIcons.buildingColumns, 'color': Colors.blue},
                    {'name': 'Mandiri', 'icon': FontAwesomeIcons.buildingColumns, 'color': Colors.blue},
                    {'name': 'Gopay', 'icon': FontAwesomeIcons.wallet, 'color': Colors.white},
                    {'name': 'Ovo', 'icon': FontAwesomeIcons.wallet, 'color': Colors.white},
                  ];

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      var account = accounts[index];
                      var hiveAccount = snapshot.data!.get(account['name']);
                      double balance = hiveAccount?.balance ?? 0.0;

                      return Card(
                        color: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(account['icon'] as IconData, color: account['color'] as Color, size: 30),
                              const SizedBox(height: 16),
                              Text(
                                account['name'] as String,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatRupiah(balance),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}