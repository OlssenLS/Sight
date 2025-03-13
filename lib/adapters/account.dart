import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account {
  @HiveField(0)
  String name;

  @HiveField(1)
  double balance;

  Account({required this.name, this.balance = 0.0});
}