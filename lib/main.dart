import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'todo_list.dart';
import 'settings.dart';
import 'theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => TodoList()),
      ],
      child: TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'To-Do List',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.currentTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => TodoListScreen(),
            '/settings': (context) => SettingsScreen(),
          },
        );
      },
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  File? _backgroundImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickBackgroundImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _backgroundImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _pickBackgroundImage,
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddTaskDialog(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                _backgroundImage != null
                    ? Image.file(
                        _backgroundImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.blueAccent),
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: StreamBuilder(
                    stream: Stream.periodic(Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Text(
                        _formatDateTime(DateTime.now()),
                        style: TextStyle(fontSize: 48, color: Colors.white),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TodoList>(
              builder: (context, todoList, child) {
                // Sort todos by priority before displaying
                todoList.sortTodosByPriority();
                return ListView.builder(
                  itemCount: todoList.todos.length,
                  itemBuilder: (context, index) {
                    final todo = todoList.todos[index];
                    return ListTile(
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description: ${todo.description}'),
                          Text(
                            'Due Time: ${_formatDateTime(todo.dueTime)}',
                          ),
                          Text(
                            'Priority: ${_getPriorityText(todo.priority)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(todo.priority),
                            ),
                          ),
                        ],
                      ),
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
                            icon: Icon(
                                todo.isLocked ? Icons.lock : Icons.lock_open),
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
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    DateTime _selectedDueTime = DateTime.now();
    TaskPriority _selectedPriority = TaskPriority.Normal; // Default priority

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                ),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Task Description',
                ),
              ),
              DropdownButtonFormField<TaskPriority>(
                value: _selectedPriority,
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Text(_getPriorityText(priority)),
                  );
                }).toList(),
                onChanged: (priority) {
                  setState(() {
                    _selectedPriority = priority!;
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Due time: ${_formatDateTime(_selectedDueTime)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_selectedDueTime),
                      );
                      if (pickedTime != null) {
                        final now = DateTime.now();
                        _selectedDueTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      }
                    },
                    child: Text('Select Time'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty) {
                  Provider.of<TodoList>(context, listen: false).addTodo(
                    _titleController.text,
                    _descriptionController.text,
                    _selectedDueTime,
                    _selectedPriority,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
      BuildContext context, TodoList todoList, int index, Todo currentTodo) {
    final TextEditingController _editTitleController =
        TextEditingController(text: currentTodo.title);
    final TextEditingController _editDescriptionController =
        TextEditingController(text: currentTodo.description);
    DateTime _editDueTime = currentTodo.dueTime;
    TaskPriority _editPriority = currentTodo.priority;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editTitleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                ),
              ),
              TextField(
                controller: _editDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Task Description',
                ),
              ),
              DropdownButtonFormField<TaskPriority>(
                value: _editPriority,
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Text(_getPriorityText(priority)),
                  );
                }).toList(),
                onChanged: (priority) {
                  setState(() {
                    _editPriority = priority!;
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Due time: ${_formatDateTime(_editDueTime)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_editDueTime),
                      );
                      if (pickedTime != null) {
                        final now = DateTime.now();
                        _editDueTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      }
                    },
                    child: Text('Select Time'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_editTitleController.text.isNotEmpty &&
                    _editDescriptionController.text.isNotEmpty) {
                  todoList.editTodo(
                    index,
                    _editTitleController.text,
                    _editDescriptionController.text,
                    _editDueTime,
                    _editPriority,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, TodoList todoList, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                todoList.removeTodo(index); // Remove the task
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.Low:
        return 'Low';
      case TaskPriority.Normal:
        return 'Normal';
      case TaskPriority.High:
        return 'High';
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
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
