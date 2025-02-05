enum AppEnviroment {
  local, dev, product
}

extension AppEnviromentExtension on AppEnviroment {
  String get urlScheme {
    switch (this) {
      case AppEnviroment.local:
        return 'http';
      case AppEnviroment.dev:
        return 'https';
      case AppEnviroment.product:
        return 'https';
    }
  }
  String get baseURL {
    switch (this) {
      case AppEnviroment.local:
        return '192.168.31.116';
      case AppEnviroment.dev:
        return 'media-dev.ermis.network';
      case AppEnviroment.product:
        return 'media.ermis.network';
    }
  }
}