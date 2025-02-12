import 'package:ermis_stream/api/api_sub_client.dart';


class EndpointPath {
  String path;
  EndpointPathType type;

  EndpointPath({required this.path, required this.type});

  static EndpointPath get connectWhipEndpoint => EndpointPath(path: '${ApiSubClient.whip.path}/endpoint', type: EndpointPathType.connectWhipEndpoint);
  static EndpointPath get connectWhepEndpoint => EndpointPath(path: '${ApiSubClient.whep.path}/endpoint', type: EndpointPathType.connectWhepEndpoint);
  static EndpointPath connection(String path) => EndpointPath(path: path, type: EndpointPathType.connection);
  static EndpointPath deleteConnection(String path) => EndpointPath(path: path, type: EndpointPathType.deleteConnection);
  static EndpointPath get createWhipSession => EndpointPath(path: '${ApiSubClient.token.path}/whip', type: EndpointPathType.createWhipSession);
  static EndpointPath get createWhepSession => EndpointPath(path: '${ApiSubClient.token.path}/whep', type: EndpointPathType.createWhepSession);
  static EndpointPath get webRTC => EndpointPath(path: '${ApiSubClient.token.path}/webrtc', type: EndpointPathType.webRTC);
  static EndpointPath get rtpEngine => EndpointPath(path: '${ApiSubClient.token.path}/rtpengine', type: EndpointPathType.rtpEngine);
}

enum EndpointPathType {
  connectWhipEndpoint,
  connectWhepEndpoint,
  connection,
  deleteConnection,
  createWhipSession,
  createWhepSession,
  webRTC,
  rtpEngine
}