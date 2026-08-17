import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

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
    setState(() => loading = true);

    notes = await ApiService.getNotes();

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> exportNoteToPDF(Map note) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              note["title"],
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(note["content"]),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: "${note["title"]}.pdf");
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/${note["title"]}.pdf");

      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("PDF Ready: ${note["title"]}.pdf")));
  }

  Future<void> showAddNoteDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            child: const Text("Save"),
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
      builder: (_) => AlertDialog(
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

  void showNoteOptions(Map note) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                showEditNoteDialog(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Export as PDF"),
              onTap: () {
                Navigator.pop(context);
                exportNoteToPDF(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete"),
              onTap: () {
                Navigator.pop(context);
                deleteNote(note["id"]);
              },
            ),
          ],
        ),
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
              itemBuilder: (_, index) {
                final note = notes[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.note, color: Colors.blue),
                    title: Text(note["title"]),
                    subtitle: Text(
                      note["content"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => showEditNoteDialog(note),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => showNoteOptions(note),
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
