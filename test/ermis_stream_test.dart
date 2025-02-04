import 'package:ermis_stream/api/api_client.dart';
import 'package:ermis_stream/api/endpoint/endpoint.dart';
import 'package:ermis_stream/api/endpoint/endpoint_path.dart';
import 'package:ermis_stream/api/http_method.dart';
import 'package:ermis_stream/api/model/base_model.dart';
import 'package:ermis_stream/api/model/pagination_model.dart';
import 'package:ermis_stream/api/model/session_token_model.dart';
import 'package:ermis_stream/api/payload/create_whip_session_request_body.dart';
import 'package:ermis_stream/utilities/logger.dart';
import 'package:ermis_stream/utilities/secure_storage.dart';
import 'package:ermis_stream/whep/webrtc_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ermis_stream/ermis_stream.dart';
import 'package:http/http.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient client = ApiClient();
  var body = CreateWhipSessionRequestBody(
      room: "room",
      peer: "peer",
      ttl: 7200,
      record: false,
      extraData: "extraData");
  final BaseApiResponse<SessionTokenModel> abc = await client.request(TokenEndpoint.createWhepSession(body));
  print('Token is ${abc.data?.token}');
}
