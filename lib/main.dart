import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repositories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'CustomFont', // Use a custom font
      ),
      home: RepoListScreen(),
    );
  }
}

class Repo {
  final String name;
  final String description;
  final Map<String, dynamic> lastCommit;

  Repo(
      {required this.name,
      required this.description,
      required this.lastCommit});
}

class RepoListScreen extends StatefulWidget {
  @override
  _RepoListScreenState createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  List<Repo> repositories = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchGitHubRepositories();
  }

  Future<void> fetchGitHubRepositories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/users/freeCodeCamp/repos'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> reposJson = json.decode(response.body);
        final List<Repo> repos = [];

        for (final repoJson in reposJson) {
          final commitResponse = await http.get(
            Uri.parse(
                'https://api.github.com/repos/freeCodeCamp/${repoJson['name']}/commits'),
          );

          Map<String, dynamic> lastCommit = {};
          if (commitResponse.statusCode == 200) {
            final commitData = json.decode(commitResponse.body);
            if (commitData.isNotEmpty) {
              lastCommit = commitData[0];
            }
          }

          final repo = Repo(
            name: repoJson['name'],
            description: repoJson['description'] ?? 'No description available',
            lastCommit: lastCommit,
          );

          repos.add(repo);
        }

        setState(() {
          repositories = repos;
          isLoading = false;
        });
      } else {
        showError('Failed to load GitHub repositories');
      }
    } catch (e) {
      showError('An error occurred: $e');
    }
  }

  void showError(String errorMessage) {
    setState(() {
      error = errorMessage;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GitHub Repositories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.blue[200],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  itemCount: repositories.length,
                  itemBuilder: (context, index) {
                    final repo = repositories[index];
                    final lastCommit = repo.lastCommit;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          repo.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          repo.description,
                          maxLines: 2,
                        ),
                        trailing: lastCommit.isNotEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Last Commit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    // Format the date and time
                                    DateFormat('dd/MM/yyyy HH:mm').format(
                                      DateTime.parse(
                                        lastCommit['commit']['committer']
                                            ['date'],
                                      ).toLocal(),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              )
                            : const Text(
                                'No commits available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
