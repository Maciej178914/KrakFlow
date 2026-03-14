import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("KrakFlow")),
        body: Center(
          child: Column(
            children: [
              Text("KrakFlow"),
              SizedBox(height: 25),
              Text("Organizacja studiów"),
              SizedBox(height: 25),
              Text("Dzisiejsze zadania"),
              TaskCard(title: "Projekt Flutter", subtitle: "termin: jutro"),
              TaskCard(title: "Ćwiczenia z matematyki", subtitle: "termin: dzisiaj"),
              TaskCard(title: "Przeczytać o widgetach", subtitle: "termin: w tym tygodniu")
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon = Icons.task;

  TaskCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
