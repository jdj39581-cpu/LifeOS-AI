import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../services/api_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<dynamic> documents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    setState(() {
      loading = true;
    });

    final data = await ApiService.getDocuments();

    if (!mounted) return;

    setState(() {
      documents = data;
      loading = false;
    });
  }

  Future<void> uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result == null) return;

    final path = result.files.single.path;

    if (path == null) return;

    final success = await ApiService.uploadDocument(path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Document Uploaded Successfully" : "Upload Failed",
        ),
      ),
    );

    if (success) {
      await loadDocuments();
    }
  }

  Future<void> openDocument(dynamic document) async {
    final id = document["id"];
    final fileName = document["file_name"];

    if (id == null || fileName == null) return;

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Opening document...")));

    final path = await ApiService.downloadDocument(id, fileName);

    if (!mounted) return;

    if (path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unable to open document")));
      return;
    }

    await OpenFilex.open(path);
  }

  Future<void> deleteDocument(int id) async {
    final success = await ApiService.deleteDocument(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Document Deleted" : "Delete Failed")),
    );

    if (success) {
      await loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Documents")),

      floatingActionButton: FloatingActionButton(
        onPressed: uploadDocument,
        child: const Icon(Icons.upload_file),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
          ? const Center(child: Text("No Documents"))
          : RefreshIndicator(
              onRefresh: loadDocuments,
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.insert_drive_file,
                        color: Colors.blue,
                      ),

                      title: Text(doc["file_name"] ?? "Document"),

                      subtitle: Text(doc["uploaded_at"] ?? ""),

                      onTap: () {
                        openDocument(doc);
                      },

                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          deleteDocument(doc["id"]);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
