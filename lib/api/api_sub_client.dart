enum ApiSubClient {
  whip, whep, token
}

extension ApiSubClientExtension on ApiSubClient {
  String get path {
    switch (this) {
      case ApiSubClient.whip:
        return "whip";
      case ApiSubClient.whep:
        return "whep";
      case ApiSubClient.token:
        return "token";
    }
  }
}