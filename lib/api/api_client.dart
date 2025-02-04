import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ermis_stream/api/http_method.dart';
import 'package:ermis_stream/api/model/base_model.dart';
import 'package:ermis_stream/config/app_environment.dart';
import 'package:ermis_stream/config/config.dart';
import 'package:http/http.dart' as http;
import 'endpoint/endpoint.dart';

class ApiClient {
  var httpClient = new HttpClient();
  var baseUrl = Config.appEnviroment.baseURL;

  ApiClient() {
  }

  Future<BaseApiResponse<T>> request<T>(Endpoint endpoint) async {
    var headers = await endpoint.headers;
    http.Response response;
    switch (endpoint.httpMethod) {
      case HttpMethod.get:
        response = await http.get(endpoint.uri, headers: headers);
      case HttpMethod.post:
        response = await http.post(endpoint.uri,
            headers: headers, body: jsonEncode(endpoint.body));
      case HttpMethod.delete:
        response = await http.delete(endpoint.uri,
            headers: headers, body: endpoint.body);
      case HttpMethod.put:
        response =
            await http.put(endpoint.uri, headers: headers, body: endpoint.body);
    }

    print("Request end: $response");
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      print(json);
      final BaseApiResponse<T> result = BaseApiResponse.fromJson(json);
      print('Result data is: ${result.data}');
      return result;
    } else {
      throw Exception('Request api failed ${response.request}, ${response.request?.method}, ${response.request?.headers}, ${response.request.toString()}');
    }
  }
}


