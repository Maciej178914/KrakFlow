import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("KrakFlow")),
      body: Center(
        child: Column(
          children: [
            Text("KrakFlow"),
            SizedBox(height: 25),
            Text("Organizacja studiów"),
            SizedBox(height: 25),
            Text("Masz dziś ${tasks.length} zadania"),
            SizedBox(height: 16),
            Text("Dzisiejsze zadania"),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(tasks[index]);
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );

          if (newTask != null) {
            setState(() {
              tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

List<Task> tasks = [
  Task("Projekt Flutter", "jutro", false, "wysoki"),
  Task("Ćwiczenia z matematyki", "dzisiaj", false, "niski"),
  Task("Przeczytać o widgetach", "w tym tygodniu", true, "średni"),
];

class Task {
  String title;
  String deadline;
  bool done;
  String priority;

  Task(this.title, this.deadline, this.done, this.priority);
}

class TaskCard extends StatelessWidget {
  final Task task;

  TaskCard(this.task);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.task),
        title: Text(task.title),
        subtitle: Text(
          "termin: ${task.deadline} | priorytet: ${task.priority}",
        ),
        trailing: Icon(
          task.done ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nowe zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12,),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "termin zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12,),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "priority zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15,),
            ElevatedButton(onPressed: () {
              final newTask = Task(titleController.text, deadlineController.text, false, priorityController.text);
              Navigator.pop(context, newTask);
            }, child: Text("Zapisz")),
          ],
        ),
      ),
    );
  }
}
