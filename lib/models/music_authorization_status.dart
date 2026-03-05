enum MusicAuthorizationStatus {
  authorized,
  denied,
  notDetermined,
  restricted,
  unknown;

  static MusicAuthorizationStatus fromString(String value) {
    switch (value) {
      case 'authorized':
        return MusicAuthorizationStatus.authorized;
      case 'denied':
        return MusicAuthorizationStatus.denied;
      case 'notDetermined':
        return MusicAuthorizationStatus.notDetermined;
      case 'restricted':
        return MusicAuthorizationStatus.restricted;
      default:
        return MusicAuthorizationStatus.unknown;
    }
  }
}
