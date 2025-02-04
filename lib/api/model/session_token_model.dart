import 'base_model.dart';

class SessionTokenModel extends BaseModel {
  String token;

  @override
  factory SessionTokenModel.fromJson(Map<String, dynamic>json) {
    return SessionTokenModel(token: json['token']);
  }

  SessionTokenModel({required this.token});
}