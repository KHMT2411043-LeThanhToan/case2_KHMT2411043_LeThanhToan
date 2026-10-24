
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';

class TaskService {
  // Dia chi API khi chay tren Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5000/api/tasks';

  Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception(
        'Khong the tai danh sach cong viec: ${response.statusCode}',
      );
    }
  }
}
