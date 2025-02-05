import 'dart:ffi';

import 'package:ermis_stream/api/api_client.dart';
import 'package:ermis_stream/api/endpoint/endpoint.dart';
import 'package:ermis_stream/utilities/secure_storage.dart';
import 'package:flutter_whip/flutter_whip.dart';

import '../utilities/logger.dart';

class WebRTCClient {
  late WHIP whep;
  late ApiClient client;
  SecureStorage secureStorage = SecureStorage();

  WebRTCClient({ required this.client});

  Future<int> connect() async {
    final accessToken = await secureStorage.accessToken;
    final connectWhepEndpoint = WhepEndpoint.connectWhepSession(accessToken);
    final headers = connectWhepEndpoint.headers;
    logger.d('Header $headers');
    final newHeaders = {
      'Content-Type': 'application/sdp',
      if (headers != null) ...headers!
    };
    logger.d('new header $newHeaders');
    logger.d('WHEP ENPOINT URL: ${connectWhepEndpoint.uri.toString()}');
    whep = WHIP(url: connectWhepEndpoint.uri.toString(), headers: headers);

    whep.onState = (WhipState state) {
      logger.d(state);
    };

    try {
      await whep.initlize(mode: WhipMode.kReceive);
      await whep.connect();
      whep.onTrack = (event) {
        logger.d(event);
      };
    } catch (error) {
      logger.e('$error');
      return 0;
    };
    return 1;
  }
}