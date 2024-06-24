import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskPriority {
  Low,
  Normal,
  High,
}

class Todo {
  String title;
  String description;
  DateTime dueTime;
  TaskPriority priority;
  bool isDone;
  bool isLocked;

  Todo({
    required this.title,
    required this.description,
    required this.dueTime,
    this.priority = TaskPriority.Normal,
    this.isDone = false,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'dueTime': dueTime.toIso8601String(),
        'priority': priority.index,
        'isDone': isDone,
        'isLocked': isLocked,
      };

  static Todo fromJson(Map<String, dynamic> json) => Todo(
        title: json['title'],
        description: json['description'],
        dueTime: DateTime.parse(json['dueTime']),
        priority: TaskPriority.values[json['priority']],
        isDone: json['isDone'],
        isLocked: json['isLocked'],
      );
}

class TodoList with ChangeNotifier {
  List<Todo> _todos = [];

  List<Todo> get todos => _todos;

  TodoList() {
    _loadTodos();
  }

  void _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosString = prefs.getString('todos');
    if (todosString != null) {
      final List<dynamic> todosJson = jsonDecode(todosString);
      _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
      notifyListeners();
    }
  }

  void _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
    prefs.setString('todos', todosJson);
  }

  void addTodo(String title, String description, DateTime dueTime, [TaskPriority priority = TaskPriority.Normal]) {
    _todos.add(Todo(
      title: title,
      description: description,
      dueTime: dueTime,
      priority: priority,
    ));
    _saveTodos();
    notifyListeners();
  }

  void toggleTodoStatus(int index) {
    _todos[index].isDone = !_todos[index].isDone;
    _saveTodos();
    notifyListeners();
  }

  void removeTodo(int index) {
    _todos.removeAt(index);
    _saveTodos();
    notifyListeners();
  }

  void lockTodoStatus(int index) {
    _todos[index].isLocked = !_todos[index].isLocked;
    _saveTodos();
    notifyListeners();
  }

  void editTodo(int index, String newTitle, String newDescription, DateTime newDueTime, [TaskPriority newPriority = TaskPriority.Normal]) {
    _todos[index].title = newTitle;
    _todos[index].description = newDescription;
    _todos[index].dueTime = newDueTime;
    _todos[index].priority = newPriority;
    _saveTodos();
    notifyListeners();
  }

  void sortTodosByPriority() {
    _todos.sort((a, b) {
      if (a.priority.index < b.priority.index) {
        return 1; // Higher priority first
      } else if (a.priority.index > b.priority.index) {
        return -1;
      } else {
        return 0;
      }
    });
    notifyListeners();
  }
}
