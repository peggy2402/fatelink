import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  const AdminDashboardScreen({required this.token});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _promptController = TextEditingController();
  String _activeProvider = 'gemini';
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchConfig();
    _fetchUsers();
  }

  Future<void> _fetchConfig() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/admin/config'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _promptController.text = data['systemPrompt'];
        _activeProvider = data['activeAiProvider'];
      });
    }
  }

  Future<void> _saveConfig() async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/admin/config'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'systemPrompt': _promptController.text,
        'activeAiProvider': _activeProvider,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu thành công!')));
    }
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/admin/users'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        _users = jsonDecode(response.body);
      });
    }
  }

  Future<void> _toggleBanUser(String userId, bool currentStatus) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/admin/users/$userId/ban'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isBanned': !currentStatus}),
    );
    if (response.statusCode == 200) {
      _fetchUsers(); // Tải lại danh sách
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? 'Đã khóa tài khoản!' : 'Đã mở khóa!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('FateLink Admin Dashboard'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Cấu hình AI'),
              Tab(text: 'Quản lý Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: CẤU HÌNH AI
            Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhà cung cấp AI ưu tiên:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _activeProvider,
                    items: [
                      DropdownMenuItem(
                        value: 'gemini',
                        child: Text('Gemini 2.0 Flash'),
                      ),
                      DropdownMenuItem(
                        value: 'openai',
                        child: Text('Groq / OpenAI (Llama 3)'),
                      ),
                      DropdownMenuItem(
                        value: 'llama',
                        child: Text('Local Llama'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _activeProvider = val!),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'System Prompt (Hồn của Faye):',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Lưu Cấu Hình'),
                    onPressed: _saveConfig,
                  ),
                ],
              ),
            ),

            // TAB 2: QUẢN LÝ USERS
            ListView.builder(
              padding: EdgeInsets.all(32),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isBanned = user['isBanned'] ?? false;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['email'] ?? user['name'] ?? 'Ẩn danh'),
                    subtitle: Text('ID: ${user['_id']}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBanned ? Colors.green : Colors.red,
                      ),
                      onPressed: () => _toggleBanUser(user['_id'], isBanned),
                      child: Text(isBanned ? 'Mở khóa' : 'Khóa (Ban)'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
