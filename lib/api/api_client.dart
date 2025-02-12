import 'dart:convert';
import 'dart:io';

import 'package:ermis_stream/api/http_method.dart';
import 'package:ermis_stream/api/model/base_model.dart';
import 'package:ermis_stream/config/app_environment.dart';
import 'package:ermis_stream/config/config.dart';
import 'package:ermis_stream/utilities/curl.dart';
import 'package:ermis_stream/utilities/logger.dart';
import 'package:http/http.dart' as http;
import 'endpoint/endpoint.dart';

class ApiClient {
  var httpClient = HttpClient();
  var baseUrl = Config.appEnviroment.baseURL;

  ApiClient();

  /// Request api [Endpoint]
  Future<http.Response> request<T>(Endpoint endpoint) async {
    var headers = await endpoint.headers;
    var request = http.Request(endpoint.httpMethod.value, endpoint.uri);
    request.headers.addAll(headers);

    if (endpoint.body != null) {
      if (endpoint.body is String) {
        var stringBody = endpoint.body as String;
        // request.bodyBytes = utf8.encode(stringBody);
        // request.body = jsonEncode(endpoint.body);
        request.body = stringBody;
        logger.d('TTTT ${request.url}');
      } else {
        request.body = jsonEncode(endpoint.body);
      }
    }

    request.headers.clear();
    request.headers.addAll(headers);

    if (endpoint.queries != null) {
      var bodyFields = endpoint.queries!.map((key, value) =>
          MapEntry(key, value.toString()));
      request.bodyFields = bodyFields;
    }


    logger.d('Request api with curl: ${request.curl}');
    var streamResponse = await request.send();
    var response = await http.Response.fromStream(streamResponse);

    if (response.statusCode > 199 && response.statusCode < 301) {
      return response;
    } else {
      throw Exception(
          'Request api failed ${response.body}');
    }
  }

  /// Request api [Endpoint] with response of type [BaseApiResponse].
  Future<BaseApiResponse<T>> ermisRequest<T>(Endpoint endpoint) async {
    var response = await request(endpoint);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      logger.d('Api response: $json');
      final BaseApiResponse<T> result = BaseApiResponse.fromJson(json);
      return result;
    } else {
      throw Exception(
          'Request api failed ${response.request}, ${response.request
              ?.method}, ${response.request?.headers}, ${response.request
              .toString()}');
    }
  }
}