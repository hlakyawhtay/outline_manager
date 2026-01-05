import 'package:dio/dio.dart';
import '../model/access_keys.dart';

class AccessKeyRepository {
  /// Updates the data limit for a specific access key.
  /// Pass `bytes` as null to remove the limit.
  Future<bool> updateAccessKeyDataLimit({
    required String accessKeyId,
    int? bytes,
  }) async {
    try {
      final payload = {
        "limit": bytes != null ? {"bytes": bytes} : null,
      };
      final response = await _dio.put(
        '$baseUrl/access-keys/$accessKeyId/data-limit',
        data: payload,
      );
      if (response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Failed to update data limit: \\${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating data limit: $e');
    }
  }

  final Dio _dio;
  final String baseUrl;

  AccessKeyRepository({required Dio dio, required this.baseUrl}) : _dio = dio;

  Future<AccessKey> createAccessKey({
    required String name,
    DateTime? expiredDate,
    DataLimit? dataLimit,
  }) async {
    try {
      final payload = {
        'method': "aes-192-gcm",
        'name': name,
        if (dataLimit != null)
          'dataLimit': dataLimit.toJson()
        else
          'dataLimit': DataLimit(
            bytes: 100 * 1024 * 1024 * 1024,
          ).toJson(), // 100GB default
        if (expiredDate != null) 'expiredDate': expiredDate.toIso8601String(),
      };
      final response = await _dio.post('$baseUrl/access-keys', data: payload);
      if (response.statusCode == 201 && response.data != null) {
        final key = AccessKey.fromJson(response.data);
        // If expiredDate is provided, update the model
        if (expiredDate != null) {
          return AccessKey(
            id: key.id,
            outlineId: key.outlineId,
            name: key.name,
            password: key.password,
            port: key.port,
            method: key.method,
            dataLimit: key.dataLimit,
            accessUrl: key.accessUrl,
            expiredDate: expiredDate,
            serverId: key.serverId,
          );
        }
        return key;
      } else {
        throw Exception(
          'Failed to create access key: \\${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating access key: $e');
    }
  }

  /// Updates the name of the access key with the given id.
  /// Returns true if the update was successful (204 No Content).
  Future<bool> updateAccessKeyName({
    required String id,
    required String name,
  }) async {
    try {
      final response = await _dio.put(
        '$baseUrl/access-keys/$id/name',
        data: {'name': name},
      );
      if (response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Failed to update access key name: \\${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating access key name: $e');
    }
  }

  /// Deletes the access key with the given id.
  /// Returns true if the deletion was successful (204 No Content).
  Future<bool> deleteAccessKey({required String id}) async {
    try {
      final response = await _dio.delete('$baseUrl/access-keys/$id');
      if (response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Failed to delete access key: \\${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting access key: $e');
    }
  }

  /// Retrieves all access keys as a list.
  Future<List<AccessKey>> getAllAccessKeys() async {
    try {
      // Fetch access keys
      final response = await _dio.get('$baseUrl/access-keys');
      List<AccessKey> accessKeys;
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          accessKeys = data.map((e) => AccessKey.fromJson(e)).toList();
        } else if (data is Map && data['accessKeys'] is List) {
          accessKeys = (data['accessKeys'] as List)
              .map((e) => AccessKey.fromJson(e))
              .toList();
        } else {
          throw Exception('Unexpected response format for access keys list');
        }
      } else {
        throw Exception('Failed to get access keys: \\${response.statusCode}');
      }

      // Fetch transfer metrics
      final transferResponse = await _dio.get('$baseUrl/metrics/transfer');
      Map<String, dynamic> transferData = transferResponse.data ?? {};
      Map<String, dynamic> bytesTransferredByUserId =
          transferData['bytesTransferredByUserId'] ?? {};

      // Merge usage into access keys (assuming accessKey.id == userId)
      accessKeys = accessKeys.map((key) {
        final usage = bytesTransferredByUserId[key.outlineId];
        return key.copyWith(
          bytesTransferred: usage is int
              ? usage
              : (usage is String ? int.tryParse(usage) : null),
        );
      }).toList();

      return accessKeys;
    } catch (e) {
      throw Exception('Error getting access keys: $e');
    }
  }
}
