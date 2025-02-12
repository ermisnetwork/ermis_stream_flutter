import 'dart:ffi';

import 'package:ermis_stream/api/endpoint/endpoint.dart';
 
abstract class EndpointEncodable {
  Future<Uri>encode(Endpoint endpoint);
}



