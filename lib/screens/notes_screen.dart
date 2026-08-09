import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    setState(() {
      loading = true;
    });

    notes = await ApiService.getNotes();

    setState(() {
      loading = false;
    });
  }

  Future<void> showAddNoteDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Content"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              bool success = await ApiService.addNote(
                titleController.text,
                contentController.text,
              );

              Navigator.pop(context);

              if (success) {
                await loadNotes();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Note Added Successfully")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteNote(int id) async {
    bool success = await ApiService.deleteNote(id);

    if (success) {
      await loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note Deleted Successfully")),
      );
    }
  }

  Future<void> showEditNoteDialog(Map note) async {
    final titleController = TextEditingController(text: note["title"]);
    final contentController = TextEditingController(text: note["content"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Content"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = await ApiService.updateNote(
                note["id"],
                titleController.text,
                contentController.text,
              );

              Navigator.pop(context);

              if (success) {
                await loadNotes();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Note Updated Successfully")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Notes"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
          ? const Center(child: Text("No Notes Found"))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () {
                      showEditNoteDialog(notes[index]);
                    },
                    leading: const Icon(Icons.note, color: Colors.blue),
                    title: Text(notes[index]["title"]),
                    subtitle: Text(notes[index]["content"]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteNote(notes[index]["id"]);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
