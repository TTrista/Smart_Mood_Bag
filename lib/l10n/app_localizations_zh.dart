// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '心脏健康';

  @override
  String get settings => '设置';

  @override
  String get themeColor => '主题颜色';

  @override
  String get language => '语言';

  @override
  String get tapToChangeLanguage => '点击切换语言';

  @override
  String get moreSettings => '更多设置即将上线...';

  @override
  String get history => '历史';

  @override
  String get home => '主页';

  @override
  String get hr => '心率';

  @override
  String get hrv => '心率变异性';

  @override
  String get update => '更新时间：';

  @override
  String get mainInfo => '主要信息';

  @override
  String get bleDevice => '蓝牙设备';

  @override
  String get scan => '扫描';

  @override
  String get scanning => '正在扫描...';

  @override
  String get noDeviceConnected => '未连接设备';

  @override
  String get connected => '已连接：';

  @override
  String get noDevicesFound => '未发现设备。';

  @override
  String get selectBleDevice => '选择蓝牙设备';

  @override
  String get hrvStatus => 'HRV状态';

  @override
  String get greenRelaxed => '绿色：放松（HRV > 70）';

  @override
  String get orangeWarning => '橙色：中度压力（30-70）';

  @override
  String get redAlert => '红色：高压力（<30）';

  @override
  String get lineChartArea => '折线图区域（待实现）';

  @override
  String get noSignalData => '暂无信号数据。';
}
