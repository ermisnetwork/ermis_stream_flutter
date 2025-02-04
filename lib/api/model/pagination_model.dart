import 'base_model.dart';

class PaginationModel extends BaseModel {
  int? total;
  int? current;

  PaginationModel({ required this.total, required this.current});

  @override factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(total: json['total'], current: json['current']);
  }
}