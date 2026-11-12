// Public legal and support pages. A store build can point them elsewhere with
// --dart-define=PRIVACY_URL=... and --dart-define=SUPPORT_URL=...
const privacyUrl = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: 'https://github.com/Tabtii/AniApp/blob/master/docs/PRIVACY.md',
);
const supportUrl = String.fromEnvironment(
  'SUPPORT_URL',
  defaultValue: 'https://github.com/Tabtii/AniApp/issues',
);
// Same address as the controller contact in docs/PRIVACY.md.
const supportEmail = 'info@tabtisworld.de';
