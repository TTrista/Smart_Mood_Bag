// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Heart Health';

  @override
  String get settings => 'Settings';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get language => 'Language';

  @override
  String get tapToChangeLanguage => 'Tap to change language';

  @override
  String get moreSettings => 'More settings coming soon...';

  @override
  String get history => 'History';

  @override
  String get home => 'Home';

  @override
  String get hr => 'HR';

  @override
  String get hrv => 'HRV';

  @override
  String get update => 'Update:';

  @override
  String get mainInfo => 'Main Information';

  @override
  String get bleDevice => 'BLE Device';

  @override
  String get scan => 'Scan';

  @override
  String get scanning => 'Scanning...';

  @override
  String get noDeviceConnected => 'No device connected';

  @override
  String get connected => 'Connected:';

  @override
  String get noDevicesFound => 'No devices found.';

  @override
  String get selectBleDevice => 'Select BLE device';

  @override
  String get hrvStatus => 'HRV Status';

  @override
  String get greenRelaxed => 'Green: Relaxed (HRV > 70)';

  @override
  String get orangeWarning => 'Orange: Moderate stress (30-70)';

  @override
  String get redAlert => 'Red: High stress (<30)';

  @override
  String get lineChartArea => 'Line chart area (to be implemented)';

  @override
  String get noSignalData => 'No signal data yet.';
}
