import 'dart:developer';
import 'dart:io';

import 'package:dio/io.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../repository/access_key_repository.dart';
import '../repository/server_repository.dart';

part 'repository_provider.g.dart';

@Riverpod(keepAlive: true)
class BaseUrlProvider extends _$BaseUrlProvider {
  @override
  String build() {
    return '';
  }

  void setupUrl(String url) {
    state = url;
  }
}

@Riverpod(keepAlive: true)
ServerRepository serverRepository(Ref ref) {
  final dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };

  final baseUrl = ref.watch(baseUrlProviderProvider);
  log("BaseUrl : $baseUrl");
  return ServerRepository(dio: dio, baseUrl: baseUrl);
}

@Riverpod(keepAlive: true)
AccessKeyRepository accessKeyRepository(Ref ref) {
  final dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };

  final baseUrl = ref.watch(baseUrlProviderProvider);
  log("BaseUrl : $baseUrl");
  return AccessKeyRepository(dio: dio, baseUrl: baseUrl);
}
