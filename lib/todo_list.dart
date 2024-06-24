import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Todo {
  String title;
  String description;
  DateTime dueTime;
  bool isDone;
  bool isLocked;

  Todo({
    required this.title,
    required this.description,
    required this.dueTime,
    this.isDone = false,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'dueTime': dueTime.toIso8601String(),
        'isDone': isDone,
        'isLocked': isLocked,
      };

  static Todo fromJson(Map<String, dynamic> json) => Todo(
        title: json['title'],
        description: json['description'],
        dueTime: DateTime.parse(json['dueTime']),
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

  void addTodo(String title, String description, DateTime dueTime) {
    _todos.add(Todo(
      title: title,
      description: description,
      dueTime: dueTime,
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

  void editTodo(int index, String newTitle, String newDescription, DateTime newDueTime) {
    _todos[index].title = newTitle;
    _todos[index].description = newDescription;
    _todos[index].dueTime = newDueTime;
    _saveTodos();
    notifyListeners();
  }
}
