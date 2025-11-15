import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class TaskEditScreen extends StatefulWidget {
  // If task is null, we are in "Create" mode.
  // If task is not null, we are in "Edit" mode.
  final ParseObject? task;

  const TaskEditScreen({super.key, this.task});

  @override
  // ignore: library_private_types_in_public_api
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  get keyboardType => null;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _isEditMode = true;
      _titleController.text = widget.task!.get<String>('title') ?? '';
      _descriptionController.text =
          widget.task!.get<String>('description') ?? '';
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorMessage = "Title cannot be empty.";
        _isLoading = false;
      });
      return;
    }

    ParseResponse response;

    try {
      if (_isEditMode) {
        // --- Update Existing Task ---
        widget.task!.set('title', title);
        widget.task!.set('description', description);
        response = await widget.task!.save();
      } else {
        // --- Create New Task ---
        final ParseUser? user = await ParseUser.currentUser();
        if (user == null) {
          throw Exception("User is not logged in.");
        }

        final newTask = ParseObject('Task')
          ..set('title', title)
          ..set('description', description)
          ..set('isDone', false)
          ..set('user', user); // Link task to the current user
        
        response = await newTask.save();
      }

      if (response.success) {
        if (mounted) {
          // Success! Pop back to the task list.
          // LiveQuery will handle updating the list UI.
          Navigator.pop(context);
        }
      } else {
        _showError(response.error?.message ?? "An unknown error occurred.");
      }
    } catch (e) {
      _showError("A network error occurred: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
        title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),             
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Save Task'),
              ),
          ],
        ),
      ),
    );
  }
}