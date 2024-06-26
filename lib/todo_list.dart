import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskPriority {
  Low,
  Normal,
  High,
  Finished,
}

class Todo {
  String title;
  String description;
  DateTime dueTime;
  TaskPriority priority;
  String group;
  bool isDone;
  bool isLocked;
  String notes;  // New field for notes

  Todo({
    required this.title,
    required this.description,
    required this.dueTime,
    this.priority = TaskPriority.Normal,
    this.group = '',
    this.isDone = false,
    this.isLocked = false,
    this.notes = '',  // Initialize notes field
  });

  Map<String, dynamic> toJson() => {
  'title': title,
  'description': description,
  'dueTime': dueTime.toIso8601String(),
  'priority': priority.index,
  'group': group,
  'isDone': isDone,
  'isLocked': isLocked,
  'notes': notes,
};

static Todo fromJson(Map<String, dynamic> json) => Todo(
  title: json['title'],
  description: json['description'],
  dueTime: DateTime.parse(json['dueTime']),
  priority: TaskPriority.values[json['priority']],
  group: json['group'],
  isDone: json['isDone'],
  isLocked: json['isLocked'],
  notes: json['notes'],
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
      sortTodosByPriority();
      notifyListeners();
    }
  }

  void _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
    prefs.setString('todos', todosJson);
  }

  void addTodo(String title, String description, DateTime dueTime, TaskPriority priority, String group) {
    _todos.add(Todo(
      title: title,
      description: description,
      dueTime: dueTime,
      priority: priority,
      group: group,
    ));
    sortTodosByPriority();
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
    sortTodosByPriority();
    _saveTodos();
    notifyListeners();
  }

  void lockTodoStatus(int index) {
    _todos[index].isLocked = !_todos[index].isLocked;
    _saveTodos();
    notifyListeners();
  }

  void editTodo(int index, String newTitle, String newDescription, DateTime newDueTime, TaskPriority newPriority, String newGroup) {
    _todos[index].title = newTitle;
    _todos[index].description = newDescription;
    _todos[index].dueTime = newDueTime;
    _todos[index].priority = newPriority;
    _todos[index].group = newGroup;
    sortTodosByPriority();
    _saveTodos();
    notifyListeners();
  }

  // New method to update notes
  void updateTodoNotes(int index, String newNotes) {
    _todos[index].notes = newNotes;
    _saveTodos();
    notifyListeners();
  }

  void sortTodosByPriority() {
  _todos.sort((a, b) {
    if (a.priority == TaskPriority.Finished && b.priority != TaskPriority.Finished) {
      return 1; // Finished tasks go to the end
    } else if (a.priority != TaskPriority.Finished && b.priority == TaskPriority.Finished) {
      return -1; // Finished tasks go to the end
    } else if (a.priority.index < b.priority.index) {
      return 1; // Higher priority first
    } else if (a.priority.index > b.priority.index) {
      return -1;
    } else {
      return 0;
    }
  });
  notifyListeners();
}

  List<Todo> getTodosByGroup(String group) {
    return _todos.where((todo) => todo.group == group).toList();
  }

  List<String> getGroups() {
    return _todos.map((todo) => todo.group).toSet().toList();
  }
}
