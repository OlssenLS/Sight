import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sight/services/logger_data.dart';
import '../adapters/transaction.dart';
import '../adapters/account.dart';

class LoggerPage extends StatefulWidget {
  const LoggerPage({super.key});

  @override
  _LoggerPageState createState() => _LoggerPageState();
}

class _LoggerPageState extends State<LoggerPage> {
  final LoggerData loggerData = LoggerData();
  final TextEditingController _descriptionController = TextEditingController();

  late Box<Transaction> transactionBox;
  late Box<Account> accountBox;

  final List<String> categories = ["Shopping", "Bill", "Transport", "Stock", "Other"];
  final List<String> accounts = ["Cash", "BCA", "Mandiri", "Gopay", "Ovo"];

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeHiveBoxes();
    _descriptionController.text = loggerData.description;
  }

  Future<void> _initializeHiveBoxes() async {
    transactionBox = await Hive.openBox<Transaction>('transactions');
    accountBox = await Hive.openBox<Account>('accounts');

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hive boxes are not initialized yet.')),
      );
      return;
    }

    final double? amount = double.tryParse(loggerData.amount);
    if (amount == null || loggerData.selectedCategory == null || loggerData.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final transaction = Transaction(
      amount: loggerData.isExpense ? -amount : amount,
      category: loggerData.selectedCategory!,
      targetAccount: loggerData.selectedAccount!,
      date: DateTime.now(),
      description: _descriptionController.text,
      isExpense: loggerData.isExpense,
    );

    // Save transaction to Hive
    transactionBox.add(transaction);

    // Update the account balance
    var account = accountBox.get(loggerData.selectedAccount);
    if (account != null) {
      double updatedBalance = account.balance + (loggerData.isExpense ? -amount : amount);
      accountBox.put(loggerData.selectedAccount, Account(name: account.name, balance: updatedBalance));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction saved successfully!')),
    );

    setState(() {
      loggerData.reset();
      _descriptionController.clear();
    });
  }

  @override
Widget build(BuildContext context) {
  if (!_isInitialized) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  return Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildToggleBox(),
            const SizedBox(height: 40),
            _buildAmountDisplay(),
            const SizedBox(height: 20),
            _buildDescriptionInput(),
            const SizedBox(height: 10),
            _buildDropdownSection(),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: KeypadWidget(
                onKeypadTap: (value) {
                  setState(() {
                    if (value == "⌫") {
                      loggerData.amount = loggerData.amount.length > 1
                          ? loggerData.amount.substring(0, loggerData.amount.length - 1)
                          : "0";
                    } else if (value == "0" && loggerData.amount != "0") {
                      loggerData.amount += "0";
                    } else if (value == "00" && loggerData.amount != "0") {
                      loggerData.amount += "00";
                    } else {
                      loggerData.amount = loggerData.amount == "0" ? value : loggerData.amount + value;
                    }
                  });
                },
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildAmountDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Rp ", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        Text(loggerData.amount, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _descriptionController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: const InputDecoration(
          hintText: "Description",
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        onChanged: (value) => loggerData.description = value,
      ),
    );
  }

  Widget _buildToggleBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            _buildToggleButton("Expense", true, Icons.remove_circle, Colors.red),
            _buildToggleButton("Income", false, Icons.add_circle, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool value, IconData icon, Color iconColor) {
    bool isSelected = loggerData.isExpense == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => loggerData.isExpense = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[800] : Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown("Category", categories, loggerData.selectedCategory, (value) {
              setState(() {
                loggerData.selectedCategory = value;
              });
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDropdown("Account", accounts, loggerData.selectedAccount, (value) {
              setState(() {
                loggerData.selectedAccount = value;
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String title, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.grey[900],
          value: selectedValue,
          hint: Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _saveTransaction,
          style: TextButton.styleFrom(backgroundColor: Colors.transparent),
          child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class KeypadWidget extends StatelessWidget {
  final Function(String) onKeypadTap;

  const KeypadWidget({super.key, required this.onKeypadTap});

  @override
  Widget build(BuildContext context) {
    List<String> keys = [
      "7", "8", "9",
      "4", "5", "6",
      "1", "2", "3",
      "0", "00", "⌫",
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        String value = keys[index];

        return GestureDetector(
          onTap: () => onKeypadTap(value),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}