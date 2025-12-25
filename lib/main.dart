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
      home: const ScenarioSelectorPage(),
    );
  }
}
// check
class ScenarioSelectorPage extends StatefulWidget {
  const ScenarioSelectorPage({super.key});

  @override
  State<ScenarioSelectorPage> createState() => _ScenarioSelectorPageState();
}

class _ScenarioSelectorPageState extends State<ScenarioSelectorPage> {
  String _appTitle = 'SCAS Demo';
  List<dynamic> _scenarios = [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScenarios();
  }

  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<void> _fetchScenarios() async {
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

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Ошибка сервера: ${response.statusCode}';
          _isLoading = false;
        });
        return;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final scenarios = data['scenarios'];

      if (scenarios is! List) {
        setState(() {
          _errorMessage = 'Неверный формат данных: отсутствует список сценариев';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _appTitle = data['app_title']?.toString() ?? 'SCAS Demo';
        _scenarios = scenarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Не удалось подключиться к серверу:\n${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _fetchScenarios,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _ErrorState(message: _errorMessage!, onRetry: _fetchScenarios)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scenarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scenario = _scenarios[index] as Map<String, dynamic>;
                    final name = scenario['name']?.toString() ?? 'Без названия';
                    final config = scenario['config'];

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: config is Map<String, dynamic>
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DynamicScreen(
                                      uiConfig: config,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicScreen extends StatefulWidget {
  const DynamicScreen({super.key, required this.uiConfig});

  final Map<String, dynamic> uiConfig;

  @override
  State<DynamicScreen> createState() => _DynamicScreenState();
}

class _DynamicScreenState extends State<DynamicScreen> {
  final Map<String, bool> _toggleStates = {};
  final Map<String, double> _sliderStates = {};

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.uiConfig['page_title']?.toString() ?? 'Сценарий';
    final widgetsData = widget.uiConfig['widgets'];

    final widgetsList = widgetsData is List ? widgetsData : <dynamic>[];

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: widgetsList.isEmpty
          ? const Center(child: Text('Нет данных для отображения'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgetsList.map((w) => _buildWidget(w)).toList(),
              ),
            ),
    );
  }

  Widget _buildWidget(dynamic widgetData) {
    if (widgetData is! Map<String, dynamic>) {
      return const Text('Некорректный элемент конфигурации');
    }

    final type = widgetData['type'];

    switch (type) {
      case 'header':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            widgetData['text']?.toString() ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );

      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            widgetData['text']?.toString() ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        );

      case 'card':
        final colorName = widgetData['color']?.toString() ?? 'blue';
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
        final label = widgetData['label']?.toString() ?? '';
        final initialValue = (widgetData['initial_value'] ?? false) == true;

        _toggleStates.putIfAbsent(label, () => initialValue);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Switch(
                value: _toggleStates[label] ?? false,
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
        final label = widgetData['label']?.toString() ?? '';
        final min = (widgetData['min'] ?? 0).toDouble();
        final max = (widgetData['max'] ?? 100).toDouble();

        _sliderStates.putIfAbsent(label, () => min);

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
                value: _sliderStates[label] ?? min,
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
}
