import 'package:flutter/widgets.dart';
import 'app_localizations.dart';
import 'app_localizations_de.dart';
export 'app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Optional context preserves compatibility with non-widget date helpers.
AppLocalizations stringsFor(BuildContext? context) =>
    context == null ? AppLocalizationsDe() : context.l10n;
