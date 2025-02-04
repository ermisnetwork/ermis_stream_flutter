import 'package:ermis_stream/api/api_sub_client.dart';


enum EndpointPath {
  connectWhipEndpoint,
  connectWhepEndpoint,
  createWhipSession,
  createWhepSession,
  webRTC,
  rtpEngine
}

extension EndpointPathExtension on EndpointPath {
  String get path {
    switch (this) {
      case EndpointPath.connectWhipEndpoint:
        return ApiSubClient.whip.path + '/endpoint';
      case EndpointPath.connectWhepEndpoint:
        return ApiSubClient.whep.path + '/endpoint';
      case EndpointPath.createWhipSession:
        return ApiSubClient.token.path + '/whip';
      case EndpointPath.createWhepSession:
        return ApiSubClient.token.path + '/whep';
      case EndpointPath.webRTC:
        return ApiSubClient.token.path + '/webrtc';
      case EndpointPath.rtpEngine:
        return ApiSubClient.token.path + '/rtpengine';
    }
  }
}