import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
    setState(() => loading = true);

    final data = await ApiService.getDocuments();

    if (!mounted) return;

    setState(() {
      documents = data;
      loading = false;
    });
  }

  Future<void> uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiService.baseUrl}/documents"),
      );

      request.headers["Authorization"] = "Bearer ${ApiService.token}";

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "file",
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath("file", file.path!),
        );
      }

      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document Uploaded Successfully")),
        );
        await loadDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload Error: $e")));
    }
  }

  Future<void> openDocument(dynamic document) async {
    final id = document["id"];

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/documents/$id/download"),
        headers: {"Authorization": "Bearer ${ApiService.token}"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Download documents from the web version."),
            ),
          );
        } else {
          final dir = await getTemporaryDirectory();
          final file = File("${dir.path}/${document["file_name"]}");

          await file.writeAsBytes(response.bodyBytes);
          await OpenFilex.open(file.path);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Open failed: $e")));
    }
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text("Documents"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadDocument,
        child: const Icon(Icons.upload_file),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
          ? const Center(
              child: Text(
                "No Documents",
                style: TextStyle(color: Colors.white),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadDocuments,
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.insert_drive_file,
                        color: Colors.cyan,
                      ),
                      title: Text(
                        doc["file_name"] ?? "Document",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        doc["uploaded_at"] ?? "",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () => openDocument(doc),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteDocument(doc["id"]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
