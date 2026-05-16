import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
            // Text("KrakFlow"),
            // SizedBox(height: 25),
            // Text("Organizacja studiów"),
            // SizedBox(height: 25),
            // Text("Masz dziś ${tasks.length} zadania"),
            // SizedBox(height: 16),
            // Text("Dzisiejsze zadania"),
            Expanded(
              child: TaskListScreen()
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
              // tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

final random = Random();
final priorities = ["niski", "średni", "wysoki"];
final deadlines = ["2 dni", "1 dzień", "3 dni", "5 dni", "2 tygodnie"];

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse("$baseUrl/todos"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      return todos.map((todo) {
        return Task(
            todo["todo"],
            deadlines[random.nextInt(deadlines.length)],
            todo["completed"],
            priorities[random.nextInt(priorities.length)]
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = TaskApiService().fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: tasksFuture, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Text("Błąd: ${snapshot.error}"),
        );
      }

      final tasks = snapshot.data!;

      return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskCard(tasks[index]);
          });
    });
  }
}

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
