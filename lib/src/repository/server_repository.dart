import 'package:dio/dio.dart';
import '../model/outline_server.dart';

class ServerRepository {
  final Dio _dio;
  final String baseUrl;

  ServerRepository({required Dio dio, required this.baseUrl}) : _dio = dio;

  Future<OutlineServer> getServerInfo() async {
    try {
      final response = await _dio.get('$baseUrl/server');
      if (response.statusCode == 200 && response.data != null) {
        return OutlineServer.fromJson(response.data);
      } else {
        throw Exception('Failed to load server info: \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching server info: $e');
    }
  }
}
