import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String category;

  @HiveField(2)
  String targetAccount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String description;

  @HiveField(5)
  bool isExpense;

  Transaction({
    required this.amount,
    required this.category,
    required this.targetAccount,
    required this.date,
    required this.description,
    required this.isExpense,
  });
}

