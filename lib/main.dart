import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<GooglePayBloc>(
          create: (context) => GooglePayBloc(),
        ),
        // Add other BlocProviders if needed
      ],
      child: GooglePayApp(),
    ),
  );
}

class User {
  String phoneNum;
  double availableAmount;

  User(this.phoneNum, this.availableAmount);
}

class Transaction {
  String from;
  String to;
  double amount;

  Transaction(this.from, this.to, this.amount);
}

class GooglePayBloc extends Cubit<List<User>> {
  GooglePayBloc() : super([]);

  void addUser(User user) {
    emit([...state, user]);
  }

  void updateUser(User updatedUser) {
    final updatedList = state
        .map((user) => user.phoneNum == updatedUser.phoneNum ? updatedUser : user)
        .toList();
    emit(updatedList);
  }
}

class GooglePayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => GooglePayBloc(),
        child: LoginPage(),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Pay Clone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final phoneNum = phoneController.text;
                if (phoneNum.isNotEmpty) {
                  final googlePayBloc = context.read<GooglePayBloc>();
                  final existingUserIndex = googlePayBloc.state.indexWhere(
                        (user) => user.phoneNum == phoneNum,
                  );
                  print("Existing User Index: $existingUserIndex");
                  if (existingUserIndex != -1) {
                    // User already exists, navigate to the transfer screen or any other screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransferScreen(phoneNum: phoneNum),
                      ),
                    );
                  } else {
                    // First login, allow the user to add an initial amount
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InitialAmountScreen(phoneNum: phoneNum),
                      ),
                    );
                  }
                }
              },
              child: Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}


class InitialAmountScreen extends StatelessWidget {
  final String phoneNum;
  final TextEditingController amountController = TextEditingController();

  InitialAmountScreen({required this.phoneNum});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Initial Amount'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, $phoneNum!'),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Initial Amount'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;

                if (amount > 0) {
                  context.read<GooglePayBloc>().addUser(User(phoneNum, amount));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransferScreen(phoneNum: phoneNum),
                    ),
                  );
                }
              },
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}


class TransferScreen extends StatelessWidget {
  final String phoneNum;
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  TransferScreen({required this.phoneNum});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<GooglePayBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Transfer Money'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: recipientController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Recipient Phone Number'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final recipient = recipientController.text;
                  final amount = double.tryParse(amountController.text) ?? 0.0;
      
                  if (recipient.isNotEmpty && amount > 0) {
                    final sender = context.read<GooglePayBloc>().state.firstWhere(
                          (user) => user.phoneNum == phoneNum,
                      orElse: () => User(phoneNum, 0.0),
                    );
      
                    if (sender.availableAmount >= amount) {
                      context.read<GooglePayBloc>().updateUser(User(phoneNum, sender.availableAmount - amount));
                      context.read<GooglePayBloc>().updateUser(User(recipient, context.read<GooglePayBloc>().state
                          .firstWhere((user) => user.phoneNum == recipient, orElse: () => User(recipient, 0.0))
                          .availableAmount + amount));
      
                      Navigator.pop(context);
                      _showTransactionDetails(context, amount);
                    } else {
                      _showErrorDialog(context, 'Insufficient balance for the transaction.');
                    }
                  }
                },
                child: Text('Transfer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Successful!'),
        content: Column(
          children: [
            Text('Amount: $amount'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
