import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TaskPriority {
  Low,
  Normal,
  High,
  Finished,
}

enum SortMode {
  PriorityHighToLow,
  PriorityLowToHigh,
  DateCreated,
}

class Todo {
  String title;
  String description;
  DateTime dueTime;
  TaskPriority priority;
  String group;
  bool isDone;
  bool isLocked;
  String notes;

  Todo({
    required this.title,
    required this.description,
    required this.dueTime,
    this.priority = TaskPriority.Normal,
    this.group = '',
    this.isDone = false,
    this.isLocked = false,
    this.notes = '',
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
  SortMode _currentSortMode = SortMode.PriorityHighToLow;

  List<Todo> get todos => _todos;
  SortMode get currentSortMode => _currentSortMode;

  TodoList() {
    _loadTodos();
  }

  void _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosString = prefs.getString('todos');
    if (todosString != null) {
      final List<dynamic> todosJson = jsonDecode(todosString);
      _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
      sortTodos();
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
    sortTodos();
    _saveTodos();
    notifyListeners();
  }

  void toggleTodoStatus(int index) {
    _todos[index].isDone = !_todos[index].isDone;
    if (_todos[index].isDone) {
      _todos[index].priority = TaskPriority.Finished; // Change priority to Finished if checklist is ticked
    } else {
      // Revert priority to previous state if checklist is unticked
      // Example: Assuming priority was TaskPriority.Normal before marking as finished
      _todos[index].priority = _getOriginalPriority(_todos[index]);
    }
    _saveTodos();
    notifyListeners();
  }

  TaskPriority _getOriginalPriority(Todo todo) {
    // Implement logic to determine the original priority before marking as finished
    // For simplicity, assuming if it was finished, revert to Normal; otherwise, keep current priority
    if (todo.priority == TaskPriority.Finished) {
      return TaskPriority.Normal;
    } else {
      return todo.priority;
    }
  }

  void removeTodo(int index) {
    _todos.removeAt(index);
    sortTodos();
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
    sortTodos();
    _saveTodos();
    notifyListeners();
  }

  void updateTodoNotes(int index, String newNotes) {
    _todos[index].notes = newNotes;
    _saveTodos();
    notifyListeners();
  }

  void sortTodosByPriorityHighToLow() {
    _todos.sort((a, b) {
      if (a.priority == TaskPriority.Finished && b.priority != TaskPriority.Finished) {
        return 1; // Finished tasks go to the end
      } else if (a.priority != TaskPriority.Finished && b.priority == TaskPriority.Finished) {
        return -1; // Finished tasks go to the end
      } else if (a.priority.index > b.priority.index) {
        return -1; // Higher priority first
      } else if (a.priority.index < b.priority.index) {
        return 1;
      } else {
        return 0;
      }
    });
  }

  void sortTodosByPriorityLowToHigh() {
    _todos.sort((a, b) {
      if (a.priority == TaskPriority.Finished && b.priority != TaskPriority.Finished) {
        return 1; // Finished tasks go to the end
      } else if (a.priority != TaskPriority.Finished && b.priority == TaskPriority.Finished) {
        return -1; // Finished tasks go to the end
      } else if (a.priority.index < b.priority.index) {
        return -1; // Lower priority first
      } else if (a.priority.index > b.priority.index) {
        return 1;
      } else {
        return 0;
      }
    });
  }

  void sortTodosByDateCreated() {
    _todos.sort((a, b) => a.dueTime.compareTo(b.dueTime));
  }

  void sortCycle() {
    switch (_currentSortMode) {
      case SortMode.PriorityHighToLow:
        sortTodosByPriorityHighToLow();
        _currentSortMode = SortMode.PriorityLowToHigh;
        break;
      case SortMode.PriorityLowToHigh:
        sortTodosByPriorityLowToHigh();
        _currentSortMode = SortMode.DateCreated;
        break;
      case SortMode.DateCreated:
        sortTodosByDateCreated();
        _currentSortMode = SortMode.PriorityHighToLow;
        break;
    }
    notifyListeners();
  }

  void sortTodos() {
    switch (_currentSortMode) {
      case SortMode.PriorityHighToLow:
        sortTodosByPriorityHighToLow();
        break;
      case SortMode.PriorityLowToHigh:
        sortTodosByPriorityLowToHigh();
        break;
      case SortMode.DateCreated:
        sortTodosByDateCreated();
        break;
    }
    notifyListeners();
  }

  List<Todo> getTodosByGroup(String group) {
    return _todos.where((todo) => todo.group == group).toList();
  }

  List<String> getGroups() {
    return _todos.map((todo) => todo.group).toSet().toList();
  }
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        actions: [
          Consumer<TodoList>(
            builder: (context, todoList, child) {
              return PopupMenuButton<SortMode>(
                icon: Icon(Icons.sort),
                onSelected: (SortMode result) {
                  Provider.of<TodoList>(context, listen: false).sortCycle();
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMode>>[
                  PopupMenuItem<SortMode>(
                    value: SortMode.PriorityHighToLow,
                    child: Text('Sort: Priority High to Low'),
                  ),
                  PopupMenuItem<SortMode>(
                    value: SortMode.PriorityLowToHigh,
                    child: Text('Sort: Priority Low to High'),
                  ),
                  PopupMenuItem<SortMode>(
                    value: SortMode.DateCreated,
                    child: Text('Sort: Date Created'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.sort),
                      SizedBox(width: 4),
                      Text(_getSortModeText(todoList.currentSortMode)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildAllTasksView(),
    );
  }

  String _getSortModeText(SortMode sortMode) {
    switch (sortMode) {
      case SortMode.PriorityHighToLow:
        return 'Priority High to Low';
      case SortMode.PriorityLowToHigh:
        return 'Priority Low to High';
      case SortMode.DateCreated:
        return 'Date Created';
      default:
        return 'None';
    }
  }

  Widget _buildAllTasksView() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: [
              // Your existing code for background and time/date display
            ],
          ),
        ),
        Expanded(
          child: Consumer<TodoList>(
            builder: (context, todoList, child) {
              return ListView.builder(
                itemCount: todoList.todos.length,
                itemBuilder: (context, index) {
                  final todo = todoList.todos[index];
                  return ListTile(
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description: ${todo.description}'),
                        Text('Due Time: ${_formatDateTime(todo.dueTime)}'),
                        Text(
                          'Priority: ${_getPriorityText(todo.priority)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(todo.priority),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showTaskDetailsDialog(context, todo, index);
                    },
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (value) {
                        if (!todo.isLocked) {
                          todoList.toggleTodoStatus(index);
                        }
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(todo.isLocked ? Icons.lock : Icons.lock_open),
                          onPressed: () {
                            todoList.lockTodoStatus(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            if (!todo.isLocked) {
                              _showEditDialog(context, todoList, index, todo);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            if (!todo.isLocked) {
                              _showDeleteConfirmationDialog(context, todoList, index);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.Low:
        return 'Low';
      case TaskPriority.Normal:
        return 'Normal';
      case TaskPriority.High:
        return 'High';
      case TaskPriority.Finished:
        return 'Finished';
      default:
        return '';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.Low:
        return Colors.green;
      case TaskPriority.Normal:
        return Colors.blue;
      case TaskPriority.High:
        return Colors.orange;
      case TaskPriority.Finished:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _showTaskDetailsDialog(BuildContext context, Todo todo, int index) {
    // Implement your dialog to show task details here
  }

  void _showEditDialog(BuildContext context, TodoList todoList, int index, Todo todo) {
    // Implement your dialog to edit a task here
  }

  void _showDeleteConfirmationDialog(BuildContext context, TodoList todoList, int index) {
    // Implement your delete confirmation dialog here
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TodoList(),
      child: MaterialApp(
        home: MyWidget(),
      ),
    ),
  );
}
