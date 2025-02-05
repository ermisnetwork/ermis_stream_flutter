import 'package:ermis_stream/api/endpoint/endpoint_path.dart';
import 'package:ermis_stream/api/http_method.dart';
import 'package:ermis_stream/api/payload/create_whip_session_request_body.dart';
import 'package:ermis_stream/config/app_environment.dart';
import 'package:ermis_stream/utilities/secure_storage.dart';

import '../../config/config.dart';

class Endpoint {
  HttpMethod httpMethod;
  EndpointPath endpointPath;
  Map<String, dynamic>? queries;
  Map<String, dynamic>? body;
  String? accessToken;

  Endpoint(
      {required this.httpMethod,
      required this.endpointPath,
      this.queries,
      this.body,
      this.accessToken});

  Uri get uri {
    return Uri(
        scheme: Config.appEnviroment.urlScheme,
        host: Config.appEnviroment.baseURL,
        port: 3000,
        path: endpointPath.path,
        queryParameters: queries);
  }

  Map<String, String> get headers {
    Map<String, String> headers;
    switch (endpointPath) {
      case EndpointPath.connectWhipEndpoint:
      case EndpointPath.connectWhepEndpoint:
        headers = {
          'Content-Type': 'application/sdp',
          'accept': 'application/sdp',
        };
      case EndpointPath.createWhipSession:
      case EndpointPath.createWhepSession:
      case EndpointPath.webRTC:
      case EndpointPath.rtpEngine:
        headers = {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Authorization': 'Bearer insecure',
        };
    }
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer ${accessToken!}';
    }
    return headers;
  }
}

extension TokenEndpoint on Endpoint {
  static Endpoint createWhipSession(CreateWhipSessionRequestBody body) {
    return Endpoint(
        httpMethod: HttpMethod.post,
        endpointPath: EndpointPath.createWhipSession,
        body: body.endCode());
  }

  static Endpoint createWhepSession(CreateWhipSessionRequestBody body) {
    return Endpoint(
        httpMethod: HttpMethod.post,
        endpointPath: EndpointPath.createWhepSession,
        body: body.endCode());
  }

  static Endpoint webRTC(CreateWhipSessionRequestBody body) {
    return Endpoint(
        httpMethod: HttpMethod.post,
        endpointPath: EndpointPath.webRTC,
        body: body.endCode());
  }

  static Endpoint rtpEngine(CreateWhipSessionRequestBody body) {
    return Endpoint(
        httpMethod: HttpMethod.post,
        endpointPath: EndpointPath.webRTC,
        body: body.endCode());
  }
}

extension WhepEndpoint on Endpoint {
  static Endpoint connectWhepSession(String? accessToken) {
    return Endpoint(
        httpMethod: HttpMethod.post,
        endpointPath: EndpointPath.connectWhepEndpoint,
        accessToken: accessToken);
  }
}
