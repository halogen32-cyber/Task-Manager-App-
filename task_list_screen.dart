import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const TaskListScreen({super.key, required this.onLogout});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<ParseObject> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _username = 'User';

  // For Real-Time Sync
  final LiveQuery _liveQuery = LiveQuery();
  late Subscription _subscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up LiveQuery subscription
    _liveQuery.client.unSubscribe(_subscription);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    ParseUser? user = await ParseUser.currentUser();
    if (user == null) {
      widget.onLogout();
      return;
    }

    if (mounted) {
      setState(() {
        _username = user.emailAddress ?? 'User';
      });
    }

    await _initLiveQuery();
    await _getTasks();
  }

  Future<void> _initLiveQuery() async {
    // Query for tasks created by the current user
    final QueryBuilder<ParseObject> query =
        QueryBuilder<ParseObject>(ParseObject('Task'));
    ParseUser? user = await ParseUser.currentUser();
    query.whereEqualTo('user', user);

    _subscription = await _liveQuery.client.subscribe(query);

    // Listen for real-time events
    _subscription.on(LiveQueryEvent.create, (value) {
      debugPrint('LiveQuery: Task Created');
      _addTaskToList(value as ParseObject);
    });

    _subscription.on(LiveQueryEvent.update, (value) {
      debugPrint('LiveQuery: Task Updated');
      _updateTaskInList(value as ParseObject);
    });

    _subscription.on(LiveQueryEvent.delete, (value) {
      debugPrint('LiveQuery: Task Deleted');
      _removeTaskFromList(value as ParseObject);
    });
  }

  // --- LiveQuery Helper Functions ---

  void _addTaskToList(ParseObject task) {
    if (mounted) {
      setState(() {
        _tasks.insert(0, task);
      });
    }
  }

  void _updateTaskInList(ParseObject updatedTask) {
    if (mounted) {
      setState(() {
        _tasks = _tasks.map((task) {
          return task.objectId == updatedTask.objectId ? updatedTask : task;
        }).toList();
      });
    }
  }

  void _removeTaskFromList(ParseObject deletedTask) {
    if (mounted) {
      setState(() {
        _tasks.removeWhere((task) => task.objectId == deletedTask.objectId);
      });
    }
  }

  // --- Standard CRUD Functions ---

  Future<void> _getTasks() async {
    try {
      final QueryBuilder<ParseObject> query =
          QueryBuilder<ParseObject>(ParseObject('Task'));
      ParseUser? user = await ParseUser.currentUser();
      if (user == null) {
        widget.onLogout();
        return;
      }
      query.whereEqualTo('user', user);

      final ParseResponse response = await query.query();

      if (response.success && response.results != null) {
        if (mounted) {
          setState(() {
            _tasks = response.results as List<ParseObject>;
            _isLoading = false;
          });
        }
      } else {
        _showError(response.error?.message ?? "Could not load tasks.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  Future<void> _handleTaskToggled(ParseObject task, bool? isDone) async {
    if (isDone == null) return;
    task.set('isDone', isDone);
    final response = await task.save();

    if (!response.success && mounted) {
      // Revert on failure
      setState(() {
        task.set('isDone', !isDone);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Error: ${response.error?.message ?? 'Could not update task'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
    // No need to manually update state, LiveQuery will handle it.
  }

  Future<void> _handleTaskDelete(ParseObject task) async {
    final response = await task.delete();
    if (!response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Error: ${response.error?.message ?? 'Could not delete task'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
    // No need to manually update state, LiveQuery will handle it.
  }

  Future<void> _handleLogout() async {
    ParseUser? user = await ParseUser.currentUser();
    if (user != null) {
      await user.logout();
    }
    widget.onLogout();
  }

  void _navigateToEdit(ParseObject? task) {
    // Navigate to the edit/create screen
    // We don't need to await this and refresh, because LiveQuery
    // will automatically update the list when the new/edited task is saved.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: task),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_username\'s Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(null), // Pass null for "create" mode
        tooltip: 'New Task',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
          child: Text('Error: $_errorMessage',
              style: const TextStyle(color: Colors.red)));
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text(
          'No tasks yet. Tap + to add one!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _getTasks, // Manual refresh
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final title = task.get<String>('title') ?? 'No Title';
          final isDone = task.get<bool>('isDone') ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            child: ListTile(
              // Checkbox
              leading: Checkbox(
                value: isDone,
                onChanged: (value) => _handleTaskToggled(task, value),
              ),
              // Title
              title: Text(
                title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : Colors.black,
                ),
              ),
              // Edit Button
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                    onPressed: () => _navigateToEdit(task),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _handleTaskDelete(task),
                  ),
                ],
              ),
              onTap: () => _navigateToEdit(task),
            ),
          );
        },
      ),
    );
  }
}