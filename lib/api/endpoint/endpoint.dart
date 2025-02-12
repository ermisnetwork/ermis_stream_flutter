import 'package:ermis_stream/api/endpoint/endpoint_path.dart';
import 'package:ermis_stream/api/http_method.dart';
import 'package:ermis_stream/api/payload/create_whip_session_request_body.dart';
import 'package:ermis_stream/config/app_environment.dart';

import '../../config/config.dart';

class Endpoint {
  HttpMethod httpMethod;
  EndpointPath endpointPath;
  Map<String, dynamic>? queries;
  Object? body;
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
        port: (Config.appEnviroment == AppEnviroment.local) ? 3000 : null,
        path: endpointPath.path,
        queryParameters: queries);
  }

  Map<String, String> get headers {
    Map<String, String> headers;
    switch (endpointPath.type) {
      case EndpointPathType.connectWhipEndpoint:
      case EndpointPathType.connectWhepEndpoint:
        headers = {
          'Content-Type': 'application/sdp',
          'Accept': 'application/sdp',
        };
      case EndpointPathType.connection:
        headers = {
          'Content-Type': 'application/trickle-ice-sdpfrag',
          'Accept': 'application/trickle-ice-sdpfrag'
        };
      case EndpointPathType.deleteConnection:
        headers = {
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'text/plain; charset=utf-8'
        };
      case EndpointPathType.createWhipSession:
      case EndpointPathType.createWhepSession:
      case EndpointPathType.webRTC:
      case EndpointPathType.rtpEngine:
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
  static Endpoint connectWhepSession(String? accessToken, String sdp) {
    return Endpoint(
        httpMethod: HttpMethod.post,
        endpointPath: EndpointPath.connectWhepEndpoint,
        accessToken: accessToken,
        body: sdp);
  }

  static Endpoint sendIce(String path, String? candidate) {
    return Endpoint(httpMethod: HttpMethod.patch, endpointPath: EndpointPath.connection(path), body: candidate);
  }

  static Endpoint deleteConnection(String path) {
    return Endpoint(httpMethod: HttpMethod.delete, endpointPath: EndpointPath.deleteConnection(path));
  }
}
