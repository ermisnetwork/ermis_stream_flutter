import 'dart:convert';

import 'package:http/http.dart' as http;

extension RequestCurl on http.Request {
  String get curl {
    final newLine = '\n';
    final method = '--request ${this.method}$newLine';
    final urlString = '--url ${url}$newLine';
    var header = '';
    var data = '';
    headers.forEach((key, value) {
      header += "--header '$key: $value'$newLine";
    });

    if (this.body != null) {
      data += "--data '${this.body}'";
    }

    // if (this.bodyBytes != null) {
    //   final dataString = utf8.decode(this.bodyBytes);
    //   data += "--data $dataString$newLine";
    // }
    final cURLString = 'curl ${method}${urlString}${header}${data}';
    return cURLString;
  }
}