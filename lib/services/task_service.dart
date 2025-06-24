import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../config/api_config.dart';
import 'token_service.dart';

class TaskService {
  List<Task> getDummyTasks() {
    // This dummy data needs to be updated to match the new Task model.
    // For now, I'll return an empty list to resolve the compilation errors.
    // We can repopulate this later if needed.
    return [];
  }

  Future<Map<String, dynamic>> postTask(Task task) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    final url = Uri.parse(ApiConfig.postTaskEndpoint);

    // Debug print statements
    print('Posting task with posterId: [33m[1m[4m[7m[41m[42m[43m[44m[45m[46m[47m[100m[101m[102m[103m[104m[105m[106m[107m${task.taskPoster}[0m');
    print('Task payload: [36m${jsonEncode(task.toJson())}[0m');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle non-JSON success responses
        if (response.body.isNotEmpty && response.body.trim().startsWith('{')) {
          return {'success': true, 'data': jsonDecode(response.body)};
        }
        return {'success': true, 'data': response.body};
      } else {
        return {
          'success': false,
          'error':
              'Failed to post task. Status: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<List<Task>> getTasksByPoster(String posterId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse(ApiConfig.getTasksByPosterEndpoint(posterId));
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> taskData = jsonDecode(response.body);
        // We'll need a Task.fromJson constructor for this to work
        return taskData.map((data) => Task.fromJson(data)).toList();
      } else {
        throw Exception(
            'Failed to load tasks. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<List<Task>> getAllTasks() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse(ApiConfig.getAllTasksEndpoint);
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> taskData = jsonDecode(response.body);
        return taskData.map((data) => Task.fromJson(data)).toList();
      } else {
        throw Exception(
            'Failed to load tasks. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateTaskStatus(
      int taskId, String newStatus, String userId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    final url = Uri.parse(
        '${ApiConfig.updateTaskStatusEndpoint(taskId)}?newStatus=$newStatus&userId=$userId');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.body};
      } else {
        return {
          'success': false,
          'error':
              'Failed to update status. Status: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteTask(int taskId, int userId) async {
    final token = await TokenService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    final url = Uri.parse('${ApiConfig.taskBaseUrl}/delete/$taskId?userId=$userId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.body};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete task. Status: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An error occurred: ${e.toString()}',
      };
    }
  }
}