import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Graph App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<charts.Series<DataPoint, DateTime>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _startBluetoothScan();
  }

  void _startBluetoothScan() {
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 5));
    FlutterBlue.instance.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Обработка результатов сканирования Bluetooth
        if (r.device.name == 'ESP32') {
          _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) {
    device.connect().then((_) {
      // Подключение к устройству Bluetooth
      _startDataSubscription(device);
    });
  }

  void _startDataSubscription(BluetoothDevice device) {
    device.discoverServices().then((services) {
      for (BluetoothService service in services) {
        // Обработка доступных сервисов Bluetooth
        if (service.uuid.toString() == '0000180D-0000-1000-8000-00805F9B34FB') {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            // Обработка доступных характеристик Bluetooth
            if (characteristic.uuid.toString() == '00002A37-0000-1000-8000-00805F9B34FB') {
              characteristic.setNotifyValue(true);
              characteristic.value.listen((data) {
                // Обработка данных, полученных по Bluetooth
                _processData(data);
              });
            }
          }
        }
      }
    });
  }

  void _processData(List<int> data) {
    // Обработка полученных данных
    // Преобразование данных в формат DataPoint и добавление в список данных для графика

    setState(() {
      _chartData = [
        charts.Series<DataPoint, DateTime>(
          id: 'Data',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (DataPoint point, _) => point.time,
          measureFn: (DataPoint point, _) => point.value,
          data: data.map((value) => DataPoint(DateTime.now(), value)).toList(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Graph App'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Data Graph',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: charts.TimeSeriesChart(
                _chartData,
                animate: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataPoint {
  final DateTime time;
  final int value;

  DataPoint(this.time, this.value);
}
