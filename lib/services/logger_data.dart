class LoggerData {
  static final LoggerData _instance = LoggerData._internal();
  factory LoggerData() => _instance;
  LoggerData._internal();

  bool isExpense = true;
  String amount = "0";
  String description = "";
  String? selectedCategory;
  String? selectedAccount;

  void reset() {
    isExpense = true;
    amount = "0";
    description = "";
    selectedCategory = null;
    selectedAccount = null;
  }
}