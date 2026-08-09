import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();

  List<dynamic> results = [];

  Future<void> search(String value) async {
    if (value.isEmpty) {
      setState(() {
        results = [];
      });
      return;
    }

    results = await ApiService.search(value);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: controller,
              onChanged: search,
              decoration: const InputDecoration(
                hintText: "Search Tasks, Notes, Goals...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text("No Results"),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.search),
                          title: Text(results[index]["title"]),
                          subtitle: Text(results[index]["type"]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}