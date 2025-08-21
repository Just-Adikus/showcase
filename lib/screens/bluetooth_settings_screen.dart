import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothSettingsScreen extends StatefulWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  State<BluetoothSettingsScreen> createState() =>
      _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends State<BluetoothSettingsScreen> {
  String _platformVersion = 'Unknown';
  final _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  bool _scanning = false;
  int _deviceStatus = Device.disconnected;
  Uint8List _data = Uint8List(0);
  String? _savedDeviceAddress;
  String? _savedDeviceName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _loadSavedDeviceInfo();
    _bluetoothClassicPlugin.onDeviceStatusChanged().listen((event) {
      setState(() {
        _deviceStatus = event;
      });
    });
    _bluetoothClassicPlugin.onDeviceDataReceived().listen((event) {
      setState(() {
        _data = Uint8List.fromList([..._data, ...event]);
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _bluetoothClassicPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _loadSavedDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedDeviceAddress = prefs.getString('bluetoothDeviceAddress');
        _savedDeviceName = prefs.getString('bluetoothDeviceName');
      });
    } catch (e) {
      print("Error loading Bluetooth settings: $e");
    }
  }

  Future<void> _saveDeviceInfo(String address, String? name) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bluetoothDeviceAddress', address);
      if (name != null) {
        await prefs.setString('bluetoothDeviceName', name);
      }

      setState(() {
        _savedDeviceAddress = address;
        _savedDeviceName = name;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getDevices() async {
    var res = await _bluetoothClassicPlugin.getPairedDevices();
    setState(() {
      _devices = res;
    });
  }

  Future<void> _scan() async {
    if (_scanning) {
      await _bluetoothClassicPlugin.stopScan();
      setState(() {
        _scanning = false;
      });
    } else {
      await _bluetoothClassicPlugin.startScan();
      _bluetoothClassicPlugin.onDeviceDiscovered().listen((event) {
        setState(() {
          // Only add if device not already in the list
          if (!_discoveredDevices.any(
            (device) => device.address == event.address,
          )) {
            _discoveredDevices = [..._discoveredDevices, event];
          }
        });
      });
      setState(() {
        _scanning = true;
      });
    }
  }

  Widget _buildDeviceActionButtons(Device device) {
    final bool isConnected = _deviceStatus == Device.connected;
    final bool isCurrentDevice = _savedDeviceAddress == device.address;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Connect button
        ElevatedButton(
          onPressed:
              isConnected
                  ? null
                  : () async {
                    try {
                      await _bluetoothClassicPlugin.connect(
                        device.address,
                        "00001101-0000-1000-8000-00805f9b34fb",
                      );
                      print("Connected to device: ${device.address}");
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to connect: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: Size(100, 36),
          ),
          child: Text("Connect"),
        ),
        SizedBox(width: 8),

        // Save button
        ElevatedButton(
          onPressed:
              _isSaving || isCurrentDevice
                  ? null
                  : () {
                    _saveDeviceInfo(device.address, device.name);
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrentDevice ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: Size(100, 36),
          ),
          child:
              isCurrentDevice
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16),
                      SizedBox(width: 4),
                      Text("Current"),
                    ],
                  )
                  : _isSaving
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text("Save"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Bluetooth Information'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Currently saved device:'),
                          SizedBox(height: 8),
                          if (_savedDeviceAddress != null) ...[
                            Text(
                              'Name: ${_savedDeviceName ?? 'Unknown'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Address: $_savedDeviceAddress',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ] else
                            Text(
                              'No device saved',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current device info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Device Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("Device Status: ${_getStatusText(_deviceStatus)}"),
                    SizedBox(height: 4),
                    if (_savedDeviceAddress != null) ...[
                      Text("Saved Device: ${_savedDeviceName ?? 'Unknown'}"),
                      Text("Address: $_savedDeviceAddress"),
                    ] else
                      Text(
                        "No device saved",
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _bluetoothClassicPlugin.initPermissions();
                    },
                    icon: Icon(Icons.settings),
                    label: Text("Permissions"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _getDevices,
                    icon: Icon(Icons.bluetooth_connected),
                    label: Text("Paired Devices"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _scan,
                    icon: Icon(_scanning ? Icons.stop : Icons.search),
                    label: Text(_scanning ? "Stop Scan" : "Scan"),
                  ),
                ],
              ),

              if (_deviceStatus == Device.connected) ...[
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _bluetoothClassicPlugin.disconnect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Disconnect"),
                  ),
                ),
              ],

              SizedBox(height: 20),

              // Test signals section
              if (_deviceStatus == Device.connected) ...[
                Text(
                  "Test Signals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _bluetoothClassicPlugin.write("0");
                        print("Sent: 0");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Send 0 (STOP)"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _bluetoothClassicPlugin.write("1");
                        print("Sent: 1");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Send 1 (START)"),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Received data:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _data.isEmpty
                            ? "No data received yet"
                            : String.fromCharCodes(_data),
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 20),

              // Paired devices section
              if (_devices.isNotEmpty) ...[
                Text(
                  "Paired Devices",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ..._devices.map((device) => _buildDeviceListTile(device)),
                Divider(),
              ],

              // Discovered devices section
              SizedBox(height: 10),
              Text(
                "Discovered Devices",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _scanning
                  ? Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text("Scanning for devices..."),
                      ],
                    ),
                  )
                  : SizedBox(),

              ..._discoveredDevices.map(
                (device) => _buildDeviceListTile(device),
              ),

              if (_discoveredDevices.isEmpty && !_scanning)
                Center(
                  child: Text(
                    "No devices found. Tap 'Scan' to start searching.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceListTile(Device device) {
    final bool isCurrentDevice = _savedDeviceAddress == device.address;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      color: isCurrentDevice ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side:
            isCurrentDevice
                ? BorderSide(color: Colors.green)
                : BorderSide(color: Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: isCurrentDevice ? Colors.green : Colors.blue,
        ),
        title: Text(
          device.name ?? "Unknown Device",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Address: ${device.address}"),
            if (isCurrentDevice)
              Text(
                "Currently Selected",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: _buildDeviceActionButtons(device),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case Device.connected:
        return "Connected";
      case Device.connecting:
        return "Connecting";
      case Device.disconnected:
      default:
        return "Disconnected";
    }
  }
}
