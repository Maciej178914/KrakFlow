import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hive_ce/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

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
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("KrakFlow")),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: tasksFuture,
                builder: (context, snapshot) {
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

                  final tasks = snapshot.data ?? [];

                  return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return TaskCard(
                            task: tasks[index],
                            onTap: () async {
                              final Task? updatedTask = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditTaskScreen(task: tasks[index])
                                  )
                              );

                              if(updatedTask != null) {
                                await TaskLocalDatabase.updateTask(updatedTask);
                              }

                              setState(() {
                                tasksFuture = loadTasks();
                              });
                            },
                            onChanged: (value) async {
                              final updatedTask = Task(
                                  id: tasks[index].id,
                                  title: tasks[index].title,
                                  deadline: tasks[index].deadline,
                                  done: value ?? false,
                                  priority: tasks[index].priority
                              );

                              await TaskLocalDatabase.updateTask(updatedTask);

                              setState(() {
                                tasksFuture = loadTasks();
                              });
                            }
                        );
                      });
                })
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
            addTask(newTask);

            setState(() {
              tasksFuture = loadTasks();
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

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse("$baseUrl/todos"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      return todos.map((todo) {
        return Task(
          id: generateTaskId(),
          title: todo["todo"],
          deadline: deadlines[random.nextInt(deadlines.length)],
          done: todo["completed"],
          priority: priorities[random.nextInt(priorities.length)]
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}

Future<List<Task>> loadTasks() async {
  await TaskSyncService.loadInitialDataIfNeeded();
  return TaskLocalDatabase.getTasks();
}

Future<void> addTask(Task task) async {
  await TaskLocalDatabase.addTask(task);
  await loadTasks();
}

class TaskLocalDatabase {
  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {
    return _box.values.map((item) {
      return Task.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();

    for(final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
  }

  static Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  static Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  static Future<void> deleteTask(int id) async {
    await _box.delete(id);
  }

  static Future<void> deleteAllTasks() async {
    await _box.clear();
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}

class TaskSyncService {
  static Future<void> loadInitialDataIfNeeded() async {
    if(!TaskLocalDatabase.isEmpty()) {
      return;
    }

    final tasks = await TaskApiService.fetchTasks();
    await TaskLocalDatabase.saveTasks(tasks);
  }
}

var tasksLength = 0;
int generateTaskId() {
  tasksLength++;
  return tasksLength;
}

class Task {
  late int id;
  String title;
  String deadline;
  bool done;
  String priority;

  Task({required this.id, required this.title,required this.deadline,required this.done,required this.priority});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "done": done,
      "priority": priority,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      done: map["done"],
      priority: map["priority"]
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(bool?) onChanged;

  TaskCard({super.key, required this.task, required this.onTap, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.task),
        title: Text(task.title),
        subtitle: Text(
          "termin: ${task.deadline} | priorytet: ${task.priority}",
        ),
        trailing: Checkbox(
            value: task.done,
            onChanged: onChanged
        ),
        onTap: onTap
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
              final newTask = Task(
                id: generateTaskId(),
                title: titleController.text,
                deadline: deadlineController.text,
                done: false,
                priority: priorityController.text
              );
              Navigator.pop(context, newTask);
            }, child: Text("Dodaj zadanie")),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  EditTaskScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController(text: task.title);
    final TextEditingController deadlineController = TextEditingController(text: task.deadline);
    final TextEditingController priorityController = TextEditingController(text: task.priority);

    return Scaffold(
      appBar: AppBar(title: Text("Edycja zadania nr: ${task.id}")),
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

            Wrap( children: [
              ElevatedButton(
                onPressed: () {
                  final updatedTask = null;
                  TaskLocalDatabase.deleteTask(task.id);
                  Navigator.pop(context, updatedTask);
                },
                child: Text("Usuń"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  )
                )
              ),

              Padding(
                padding: EdgeInsets.only(left: 40),
                child: ElevatedButton(onPressed: () {
                  final updatedTask = Task(
                      id: task.id,
                      title: titleController.text,
                      deadline: deadlineController.text,
                      done: task.done,
                      priority: priorityController.text
                  );
                  Navigator.pop(context, updatedTask);
                }, child: Text("Zapisz")),
              )
            ])
          ],
        ),
      ),
    );
  }
}