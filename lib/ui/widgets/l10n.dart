import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/strings.dart';

/// Supplies [Strings] for the active locale through [Localizations].
class StringsDelegate extends LocalizationsDelegate<Strings> {
  /// The single delegate instance.
  const StringsDelegate();

  /// Locales with a [Strings] implementation.
  static final supportedLocales = [
    for (final l in AppLanguage.values) Locale(l.code, l.country),
  ];

  @override
  bool isSupported(Locale locale) =>
      AppLanguage.values.any((l) => l.code == locale.languageCode);

  @override
  Future<Strings> load(Locale locale) =>
      SynchronousFuture(Strings.of(AppLanguage.fromCode(locale.languageCode)));

  @override
  bool shouldReload(StringsDelegate old) => false;
}

/// Texts of the current locale; Turkish outside a localized app (tests).
extension StringsContext on BuildContext {
  /// Active UI texts.
  Strings get strings => Localizations.of<Strings>(this, Strings) ?? Strings.tr;
}
