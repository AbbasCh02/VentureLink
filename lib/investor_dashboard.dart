import 'package:flutter/material.dart';

class InvestorDashboard extends StatelessWidget {
  const InvestorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Investor Dashboard')),
      body: Center(child: Text('Welcome to the Investor dashboard!')),
    );
  }
}
