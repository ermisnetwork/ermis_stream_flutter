import 'dart:convert';

import 'package:ermis_stream/api/model/pagination_model.dart';
import 'package:ermis_stream/api/model/session_token_model.dart';

class BaseModel {}

class BaseApiResponse<T> {
  String? error;
  bool status;
  T? data;
  PaginationModel? pagination;

  static final jsonDecoderFactories = <Type, dynamic Function(Map<String, dynamic>)> {
    SessionTokenModel: (Map<String, dynamic> json) => SessionTokenModel.fromJson(json)
  };

  BaseApiResponse({this.error, required this.status, this.data, this.pagination});

factory BaseApiResponse.fromJson(final Map<String, dynamic> json) {
  final error = json['error'];
  final status = json['status'];
  final T data = jsonDecoderFactories[T]!(json['data']) as T;
  final pagination = PaginationModel.fromJson(json['pagination'] ?? {});
  return BaseApiResponse<T>(error: error,status: status,data: data,pagination: pagination);
}
}

class WhipSessionModel extends BaseModel {
  String room;
  String peer;
  int ttl;
  bool record;
  String extraData;


  @override
  factory WhipSessionModel.fromJson(Map<String, dynamic> json) {
    return WhipSessionModel(room: json['room'],
        peer: json['peer'],
        ttl: json['ttl'],
        record: json['record'],
        extraData: json['extra_data']);
  }

  WhipSessionModel(
      {required this.room, required this.peer, required this.ttl, required this.record, required this.extraData});
}

