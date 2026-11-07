import 'package:freezed_annotation/freezed_annotation.dart';

/// A Nigerian bank account a courier is paid into.
///
/// Customers pay their courier directly — cash at the door, or a bank
/// transfer to this account. The courier keeps it on their profile
/// (`users/{uid}.payoutAccount`, owner-only); when a customer accepts their
/// offer, the server copies it onto that one order (`couriers/{id}.courierBank`)
/// so the customer can see where to send the money, and nothing else.
@immutable
class BankAccount {
  const BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  final String bankName;

  /// NUBAN — always ten digits.
  final String accountNumber;
  final String accountName;

  static final _nuban = RegExp(r'^\d{10}$');

  static bool isValidAccountNumber(String value) => _nuban.hasMatch(value);

  bool get isComplete =>
      bankName.trim().isNotEmpty &&
      isValidAccountNumber(accountNumber) &&
      accountName.trim().isNotEmpty;

  static BankAccount? fromMap(Object? value) {
    if (value is! Map) return null;
    String read(String key) => (value[key] as Object?)?.toString().trim() ?? '';
    final account = BankAccount(
      bankName: read('bankName'),
      accountNumber: read('accountNumber'),
      accountName: read('accountName'),
    );
    return account.bankName.isEmpty && account.accountNumber.isEmpty
        ? null
        : account;
  }

  Map<String, dynamic> toMap() => {
    'bankName': bankName.trim(),
    'accountNumber': accountNumber.trim(),
    'accountName': accountName.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is BankAccount &&
      other.bankName == bankName &&
      other.accountNumber == accountNumber &&
      other.accountName == accountName;

  @override
  int get hashCode => Object.hash(bankName, accountNumber, accountName);

  @override
  String toString() => 'BankAccount($bankName, $accountNumber, $accountName)';
}

/// Reads a bank account map from Firestore, whatever map type the platform
/// channel hands back. Absent or empty → null.
class BankAccountConverter implements JsonConverter<BankAccount?, Object?> {
  const BankAccountConverter();

  @override
  BankAccount? fromJson(Object? json) => BankAccount.fromMap(json);

  @override
  Object? toJson(BankAccount? account) => account?.toMap();
}
