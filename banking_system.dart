import 'dart:math';

/// -------------------------
/// Abstract base class
/// -------------------------
abstract class BankAccount {
  // private fields (library-private by using underscore)
  final String _accountNumber;
  String _holderName;
  double _balance;

  BankAccount(this._accountNumber, this._holderName, [double initialBalance = 0])
      : _balance = initialBalance;

  // Getters and setters (encapsulation)
  String get accountNumber => _accountNumber;
  String get holderName => _holderName;
  double get balance => _balance;

  set holderName(String name) {
    if (name.trim().isEmpty) throw ArgumentError('Holder name cannot be empty');
    _holderName = name;
  }

  // allow subclasses or bank to change balance through protected-like method
  @protected()
  void setBalance(double value) => _balance = value;

  // Abstract operations
  void deposit(double amount);
  void withdraw(double amount);

  // Display account information
  void displayInfo() {
    print('Account: $_accountNumber | Holder: $_holderName | Balance: \$${_balance.toStringAsFixed(2)}');
  }
}

/// Simple annotation to indicate "protected-like" method (no real enforcement)
// ignore: unused_element
class _Protected {
  const _Protected();
}

/// Helper annotation (no enforcement, for readability)
// ignore: camel_case_types
class protected {
  const protected();
}

/// -------------------------
/// Interest-bearing interface
/// -------------------------
abstract class InterestBearing {
  double calculateInterest(); // returns interest amount (not applied)
}

/// -------------------------
/// Savings Account
/// -------------------------
class SavingsAccount extends BankAccount implements InterestBearing {
  static const double minBalance = 500.0;
  static const double interestRate = 0.02; // 2%
  final int withdrawalLimitPerMonth;
  int _withdrawalsThisMonth = 0;

  SavingsAccount(String accountNumber, String holderName, [double initialBalance = 0])
      : withdrawalLimitPerMonth = 3,
        super(accountNumber, holderName, initialBalance) {
    if (initialBalance < minBalance) {
      // allow creation but warn and set to minBalance? We'll throw to be strict:
      throw ArgumentError('Initial balance for SavingsAccount must be at least \$${minBalance.toStringAsFixed(2)}');
    }
  }

  @override
  void deposit(double amount) {
    if (amount <= 0) throw ArgumentError('Deposit amount must be positive');
    setBalance(balance + amount);
    print('Deposited \$${amount.toStringAsFixed(2)} to savings $_accountNumber');
  }

  @override
  void withdraw(double amount) {
    if (amount <= 0) throw ArgumentError('Withdrawal amount must be positive');

    if (_withdrawalsThisMonth >= withdrawalLimitPerMonth) {
      throw StateError('Withdrawal limit reached for the month (limit: $withdrawalLimitPerMonth)');
    }

    if (balance - amount < minBalance) {
      throw StateError('Cannot withdraw: must maintain minimum balance of \$${minBalance.toStringAsFixed(2)}');
    }

    setBalance(balance - amount);
    _withdrawalsThisMonth++;
    print('Withdrew \$${amount.toStringAsFixed(2)} from savings $accountNumber (withdrawals this month: $_withdrawalsThisMonth)');
  }

  @override
  double calculateInterest() {
    return balance * interestRate;
  }

  // helper to apply interest to balance
  void applyInterest() {
    final interest = calculateInterest();
    setBalance(balance + interest);
    print('Applied interest \$${interest.toStringAsFixed(2)} to savings $accountNumber');
  }

  // Simulate monthly reset
  void resetMonthlyCounters() {
    _withdrawalsThisMonth = 0;
  }

  int get withdrawalsThisMonth => _withdrawalsThisMonth;
}

/// -------------------------
/// Checking Account
/// -------------------------
class CheckingAccount extends BankAccount {
  static const double overdraftFee = 35.0;

  CheckingAccount(super.accountNumber, super.holderName, [super.initialBalance]);

  @override
  void deposit(double amount) {
    if (amount <= 0) throw ArgumentError('Deposit amount must be positive');
    setBalance(balance + amount);
    print('Deposited \$${amount.toStringAsFixed(2)} to checking $accountNumber');
  }

  @override
  void withdraw(double amount) {
    if (amount <= 0) throw ArgumentError('Withdrawal amount must be positive');

    setBalance(balance - amount);
    print('Withdrew \$${amount.toStringAsFixed(2)} from checking $accountNumber');

    // Apply overdraft fee if now below zero
    if (balance < 0) {
      setBalance(balance - overdraftFee);
      print('Overdraft! Applied fee \$${overdraftFee.toStringAsFixed(2)} to checking $accountNumber');
    }
  }
}

/// -------------------------
/// Premium Account
/// -------------------------
class PremiumAccount extends BankAccount implements InterestBearing {
  static const double minBalance = 10000.0;
  static const double interestRate = 0.05; // 5%

  PremiumAccount(String accountNumber, String holderName, [double initialBalance = 0])
      : super(accountNumber, holderName, initialBalance) {
    if (initialBalance < minBalance) {
      throw ArgumentError('Initial balance for PremiumAccount must be at least \$${minBalance.toStringAsFixed(2)}');
    }
  }

  @override
  void deposit(double amount) {
    if (amount <= 0) throw ArgumentError('Deposit amount must be positive');
    setBalance(balance + amount);
    print('Deposited \$${amount.toStringAsFixed(2)} to premium $accountNumber');
  }

  @override
  void withdraw(double amount) {
    if (amount <= 0) throw ArgumentError('Withdrawal amount must be positive');

    if (balance - amount < minBalance) {
      throw StateError('Cannot withdraw: Premium account must maintain minimum balance of \$${minBalance.toStringAsFixed(2)}');
    }

    setBalance(balance - amount);
    print('Withdrew \$${amount.toStringAsFixed(2)} from premium $accountNumber');
  }

  @override
  double calculateInterest() {
    return balance * interestRate;
  }

  void applyInterest() {
    final interest = calculateInterest();
    setBalance(balance + interest);
    print('Applied interest \$${interest.toStringAsFixed(2)} to premium $accountNumber');
  }
}

/// -------------------------
/// Bank class (manager)
/// -------------------------
class Bank {
  final Map<String, BankAccount> _accounts = {};
  final Random _rand = Random();

  // Generates simple unique account numbers; in real life use stronger scheme
  String _generateAccountNumber() {
    String candidate;
    do {
      candidate = 'AC${100000 + _rand.nextInt(900000)}';
    } while (_accounts.containsKey(candidate));
    return candidate;
  }

  // Create new accounts
  BankAccount createSavings(String holderName, double initialBalance) {
    final accNo = _generateAccountNumber();
    final account = SavingsAccount(accNo, holderName, initialBalance);
    _accounts[accNo] = account;
    print('Created Savings account $accNo for $holderName');
    return account;
  }

  BankAccount createChecking(String holderName, [double initialBalance = 0]) {
    final accNo = _generateAccountNumber();
    final account = CheckingAccount(accNo, holderName, initialBalance);
    _accounts[accNo] = account;
    print('Created Checking account $accNo for $holderName');
    return account;
  }

  BankAccount createPremium(String holderName, double initialBalance) {
    final accNo = _generateAccountNumber();
    final account = PremiumAccount(accNo, holderName, initialBalance);
    _accounts[accNo] = account;
    print('Created Premium account $accNo for $holderName');
    return account;
  }

  BankAccount? findAccount(String accountNumber) => _accounts[accountNumber];

  // Transfer money between accounts (basic transactional behavior)
  bool transfer(String fromAcc, String toAcc, double amount) {
    final src = findAccount(fromAcc);
    final dst = findAccount(toAcc);

    if (src == null) {
      print('Transfer failed: source account $fromAcc not found');
      return false;
    }
    if (dst == null) {
      print('Transfer failed: destination account $toAcc not found');
      return false;
    }
    if (amount <= 0) {
      print('Transfer failed: amount must be positive');
      return false;
    }

    try {
      // perform withdraw first; if it throws we abort
      src.withdraw(amount);
      // deposit to destination
      dst.deposit(amount);
      print('Transferred \$${amount.toStringAsFixed(2)} from $fromAcc to $toAcc');
      return true;
    } catch (e) {
      print('Transfer failed: ${e.toString()}');
      return false;
    }
  }

  // Generate a simple report of all accounts
  void generateReport() {
    print('--- Bank Accounts Report (${_accounts.length} accounts) ---');
    for (var acc in _accounts.values) {
      acc.displayInfo();
    }
    print('--- End of Report ---');
  }

  // Apply monthly interest to all interest-bearing accounts
  void applyMonthlyInterest() {
    for (var acc in _accounts.values) {
      if (acc is InterestBearing) {
        if (acc is SavingsAccount) {
          acc.applyInterest();
        } else if (acc is PremiumAccount) {
          acc.applyInterest();
        } // other interest-bearing types could be added
      }
    }
  }

  // Reset monthly counters (e.g., for savings withdrawal limits)
  void resetMonthlyCounters() {
    for (var acc in _accounts.values) {
      if (acc is SavingsAccount) acc.resetMonthlyCounters();
    }
  }
}

/// -------------------------
/// Demo usage in main()
/// -------------------------
void main() {
  final bank = Bank();

  // Create accounts
  final saving = bank.createSavings('Abhishek', 1500.0); // Savings with >= $500
  final checking = bank.createChecking('Bibek', 200.0); // Checking
  final premium = bank.createPremium('Utsav', 15000.0); // Premium with >= 10000

  print('\n--- Initial report ---');
  bank.generateReport();

  // Polymorphism: treat accounts uniformly as BankAccount
  List<BankAccount> accounts = [saving, checking, premium];

  // Deposits
  for (var a in accounts) {
    a.deposit(200.0);
  }

  print('\n--- After deposits ---');
  bank.generateReport();

  // Withdraw attempts
  try {
    // Savings: should succeed (still above min balance)
    saving.withdraw(300.0);
    // Savings: withdraw 3 times then 4th should fail
    saving.withdraw(100.0);
    saving.withdraw(50.0);
    // Next withdrawal should throw due to transaction limit
    try {
      saving.withdraw(10.0);
    } catch (e) {
      print('Expected savings withdrawal error: $e');
    }
  } catch (e) {
    print('Savings op error: $e');
  }

  // Checking: overdraft demonstration
  try {
    checking.withdraw(500.0); // will go negative and apply overdraft fee
  } catch (e) {
    print('Checking op error: $e');
  }

  // Premium: try to withdraw below minimum -> should throw
  try {
    premium.withdraw(6000.0); // leaves 9500 which is below 10000 -> should fail
  } catch (e) {
    print('Expected premium withdrawal error: $e');
  }

  print('\n--- After withdrawals ---');
  bank.generateReport();

  // Transfer money: from premium to checking
  final fromAcc = premium.accountNumber;
  final toAcc = checking.accountNumber;
  print('\nAttempting transfer of \$3000 from premium to checking:');
  bank.transfer(fromAcc, toAcc, 3000.0);

  print('\n--- After transfer ---');
  bank.generateReport();

  // Apply monthly interest (Savings: 2%, Premium: 5%)
  print('\nApplying monthly interest:');
  bank.applyMonthlyInterest();

  print('\n--- Final report ---');
  bank.generateReport();

  // Reset monthly counters (e.g., start of new month)
  bank.resetMonthlyCounters();
  print('\n--- Reset monthly counters done ---');
}
