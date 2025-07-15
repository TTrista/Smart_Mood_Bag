import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'settings_page.dart';
import 'theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_helper.dart';

class HomePage extends StatefulWidget {
  final void Function(Locale)? onLocaleChange;
  const HomePage({super.key, this.onLocaleChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Default to Home

  // BLE
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final bleHelper = BleHelper(
    serviceUuid: Uuid.parse("12345678-1234-1234-1234-1234567890AB"),
    charUuid: Uuid.parse("ABCD1234-5678-1234-5678-ABCDEF123456"),
  );

  late StreamSubscription<DiscoveredDevice> _scanStream;
  List<DiscoveredDevice> _foundDevices = [];
  DiscoveredDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  String _connectionStatus = 'Not connected';

  // Example data
  String hr = '--';
  String hrv = '--';
  String hrUpdateTime = '--';
  String hrvUpdateTime = '--';

  // For HRV abnormality detection
  double? hrvValue;
  String hrvStatus = 'Unknown';
  Color hrvColor = Colors.grey;
  bool _hasShownHrvWarning = false; // 防止重复弹出警告弹框

  final List<double> _signalList = [];
  final int _maxSignalPoints = 100;

  @override
  void initState() {
    super.initState();
    _requestBlePermissions();
  }

  Future<void> _requestBlePermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();
  }

  void _startScan() async {
    await _requestBlePermissions();
    setState(() {
      _foundDevices = [];
      _isScanning = true;
    });
    _scanStream = _ble
        .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
        .listen(
          (device) {
            if (!_foundDevices.any((d) => d.id == device.id)) {
              setState(() {
                _foundDevices.add(device);
              });
            }
          },
          onDone: () {
            setState(() {
              _isScanning = false;
            });
          },
          onError: (e) {
            setState(() {
              _isScanning = false;
            });
          },
        );
    // 自动停止扫描（比如10秒）
    Future.delayed(const Duration(seconds: 10), () {
      _scanStream.cancel();
      setState(() {
        _isScanning = false;
      });
    });
  }

  void _connectToDevice(DiscoveredDevice device) {
    setState(() {
      _isConnected = false;
      _connectionStatus = 'Connecting...';
    });

    bleHelper.connectAndListen(
      deviceId: device.id,
      onData: (data) {
        setState(() {
          hr = data['hr'] != null ? '${data['hr']} bpm' : '--';
          hrv = data['hrv'] != null ? '${data['hrv']} ms' : '--';
          hrUpdateTime = DateTime.now().toLocal().toIso8601String().substring(
            11,
            19,
          );
          hrvUpdateTime = DateTime.now().toLocal().toIso8601String().substring(
            11,
            19,
          );
          hrvValue =
              data['hrv'] != null
                  ? double.tryParse(data['hrv'].toString())
                  : null;

          // signal数据本地缓存
          if (data['signal'] != null) {
            double? sig = double.tryParse(data['signal'].toString());
            if (sig != null) {
              _signalList.add(sig);
              if (_signalList.length > _maxSignalPoints) {
                _signalList.removeAt(0);
              }
            }
          }
        });
      },
      onError: (error) {
        setState(() {
          _isConnected = false;
          _connectionStatus = 'Error: $error';
        });
        print('BLE Error: $error');
      },
    );

    // 监听连接状态
    _ble
        .connectToDevice(id: device.id)
        .listen(
          (update) {
            if (update.connectionState == DeviceConnectionState.connected) {
              setState(() {
                _isConnected = true;
                _connectionStatus = 'Connected';
              });
            } else if (update.connectionState ==
                DeviceConnectionState.disconnected) {
              setState(() {
                _isConnected = false;
                _connectionStatus = 'Disconnected';
              });
            }
          },
          onError: (e) {
            setState(() {
              _isConnected = false;
              _connectionStatus = 'Connection failed';
            });
          },
        );
  }

  void _checkHrvStatus() {
    String previousStatus = hrvStatus;

    if (hrvValue == null) {
      hrvStatus = 'Unknown';
      hrvColor = Colors.grey;
      _hasShownHrvWarning = false; // 重置警告标志
      return;
    }

    if (hrvValue! > 70) {
      hrvStatus = 'Relaxed';
      hrvColor = Colors.green;
      _hasShownHrvWarning = false; // 重置警告标志
    } else if (hrvValue! >= 30 && hrvValue! <= 70) {
      hrvStatus = 'Warning';
      hrvColor = Colors.orange;
      // 只有当状态改变且未显示过警告时才弹出
      if (previousStatus != 'Warning' && !_hasShownHrvWarning) {
        _hasShownHrvWarning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHrvDialog(
            'Warning: Moderate stress detected. Please pay attention.',
          );
        });
      }
    } else if (hrvValue! < 30) {
      hrvStatus = 'Alert';
      hrvColor = Colors.red;
      // 只有当状态改变且未显示过警告时才弹出
      if (previousStatus != 'Alert' && !_hasShownHrvWarning) {
        _hasShownHrvWarning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHrvDialog(
            'Alert: High stress detected. Please take a break or relax.',
          );
        });
      }
    }
  }

  void _showHrvDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('HRV Status'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 重置警告标志，允许下次状态改变时再次弹出
                  _hasShownHrvWarning = false;
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildBleModule() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BLE Device',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _isScanning ? null : _startScan,
                  child: Text(_isScanning ? 'Scanning...' : 'Scan'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isScanning && _foundDevices.isEmpty
                ? const Text('Scanning for devices...')
                : _foundDevices.isEmpty
                ? const Text('No devices found.')
                : DropdownButton<DiscoveredDevice>(
                  value: _selectedDevice,
                  hint: const Text('Select BLE device'),
                  items:
                      _foundDevices.map((device) {
                        return DropdownMenuItem<DiscoveredDevice>(
                          value: device,
                          child: Text(
                            device.name.isNotEmpty ? device.name : device.id,
                          ),
                        );
                      }).toList(),
                  onChanged: (device) {
                    setState(() {
                      _selectedDevice = device;
                    });
                    if (device != null) {
                      _connectToDevice(device);
                    }
                  },
                ),
            const SizedBox(height: 8),
            Text(
              _isConnected
                  ? 'Connected: ${_selectedDevice?.name ?? _selectedDevice?.id ?? ''}'
                  : _selectedDevice == null
                  ? 'No device connected'
                  : _connectionStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalChart() {
    final hasData = _signalList.isNotEmpty;
    final List<FlSpot> spots =
        hasData
            ? List.generate(
              _signalList.length,
              (i) => FlSpot(i.toDouble(), _signalList[i]),
            )
            : [FlSpot(0, 0)];
    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300),
            ),
            minX: 0,
            maxX: hasData ? (_signalList.length - 1).toDouble() : 10,
            minY: 0,
            maxY:
                hasData
                    ? (_signalList.reduce((a, b) => a > b ? a : b) + 1)
                    : 10,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: Colors.blue,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoModule() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Main Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HR', style: TextStyle(fontSize: 16)),
                    Text(
                      hr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Update:', style: TextStyle(fontSize: 12)),
                        Text(
                          hrUpdateTime,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HRV', style: TextStyle(fontSize: 16)),
                    Text(
                      hrv,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Update:', style: TextStyle(fontSize: 12)),
                        Text(
                          hrvUpdateTime,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 折线图区域
            _buildSignalChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHrvStatusModule() {
    _checkHrvStatus();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: hrvColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'HRV Status: $hrvStatus',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 根据状态显示不同的提示语
            if (hrvStatus == 'Relaxed')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Great! You are in a relaxed state.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Suggestion: Maintain this state, continue your activities.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (hrvStatus == 'Warning')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Moderate stress detected.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Suggestions: Take deep breaths, go for a short walk, or take a 5-minute break.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (hrvStatus == 'Alert')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'High stress level detected!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Suggestions: Stop current work, practice deep breathing, go outside for fresh air, or take a longer break.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'HRV Guide: Green (>70ms) = Relaxed | Orange (30-70ms) = Moderate stress | Red (<30ms) = High stress',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return ListView(
      children: [
        _buildBleModule(),
        _buildInfoModule(),
        _buildHrvStatusModule(),
        // Add more modules here
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Heart Health'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // History page
          Center(child: Text('History page (to be implemented)')),
          // Home page
          _buildMainContent(),
          // Settings page
          SettingsPage(
            themeColor: AppColors.accent,
            themeOptions: [
              {'color': AppColors.accent, 'name': 'Default'},
              {'color': Colors.blue, 'name': 'Blue'},
              {'color': Colors.green, 'name': 'Green'},
            ],
            onThemeChanged: (color) {
              // 主题切换逻辑（暂时不实现）
            },
            onLanguageTap: () {
              if (widget.onLocaleChange != null) {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Language'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('English'),
                              onTap: () {
                                widget.onLocaleChange!(const Locale('en'));
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              title: const Text('简体中文'),
                              onTap: () {
                                widget.onLocaleChange!(const Locale('zh'));
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text,
      ),
    );
  }

  @override
  void dispose() {
    _scanStream.cancel();
    bleHelper.disconnect();
    super.dispose();
  }
}
