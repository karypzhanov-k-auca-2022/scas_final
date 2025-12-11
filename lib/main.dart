import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCAS Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.robotoTextTheme(),
        useMaterial3: true,
      ),
      home: const ConfigurablePage(),
    );
  }
}

class ConfigurablePage extends StatefulWidget {
  const ConfigurablePage({super.key});

  @override
  State<ConfigurablePage> createState() => _ConfigurablePageState();
}

class _ConfigurablePageState extends State<ConfigurablePage> {
  String? _pageTitle;
  List<dynamic>? _widgets;
  String? _errorMessage;
  bool _isLoading = true;
  final Map<String, bool> _toggleStates = {};
  final Map<String, double> _sliderStates = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  String _getBaseUrl() {
    // Critical fix for Android emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    // For iOS/macOS/others use localhost
    return 'http://127.0.0.1:8000';
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '${_getBaseUrl()}/config.json?t=$timestamp';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _pageTitle = data['page_title'];
          _widgets = data['widgets'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Ошибка сервера: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Не удалось подключиться к серверу:\n${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildWidget(dynamic widgetData) {
    final type = widgetData['type'];

    switch (type) {
      case 'header':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            widgetData['text'] ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );

      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            widgetData['text'] ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        );

      case 'card':
        final colorName = widgetData['color'] ?? 'blue';
        final color = _parseColor(colorName);
        final child = widgetData['child'];

        return Card(
          color: color.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child != null ? _buildWidget(child) : const SizedBox(),
          ),
        );

      case 'toggle':
        final label = widgetData['label'] ?? '';
        final initialValue = widgetData['initial_value'] ?? false;

        if (!_toggleStates.containsKey(label)) {
          _toggleStates[label] = initialValue;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Switch(
                value: _toggleStates[label]!,
                onChanged: (value) {
                  setState(() {
                    _toggleStates[label] = value;
                  });
                },
              ),
            ],
          ),
        );

      case 'slider':
        final label = widgetData['label'] ?? '';
        final min = (widgetData['min'] ?? 0).toDouble();
        final max = (widgetData['max'] ?? 100).toDouble();

        if (!_sliderStates.containsKey(label)) {
          _sliderStates[label] = min;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ${_sliderStates[label]!.toInt()}',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: _sliderStates[label]!,
                min: min,
                max: max,
                onChanged: (value) {
                  setState(() {
                    _sliderStates[label] = value;
                  });
                },
              ),
            ],
          ),
        );

      default:
        return Text('Unknown widget type: $type');
    }
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle ?? 'SCAS Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadConfig,
                      child: const Text('Повторить попытку'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _widgets?.map((w) => _buildWidget(w)).toList() ?? [],
              ),
            ),
    );
  }
}
