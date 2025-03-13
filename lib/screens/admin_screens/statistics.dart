import 'package:flutter/material.dart';

class Statistics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: Center(
        child: Text(
          'Statistics Overview',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}