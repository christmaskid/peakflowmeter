import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peak Flow Meter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database database;
  late Future<void> _dbInitFuture;
  final TextEditingController valueController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  String selectedOption = 'Morning';
  final List<String> options = ['Morning', 'Night', 'Symptomatic'];

  @override
  void initState() {
    super.initState();
    _dbInitFuture = _initDatabase();
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'peakflow.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE entries(id INTEGER PRIMARY KEY, date TEXT, time TEXT, value INTEGER, option TEXT, symptoms TEXT)'
        );
        await db.execute(
          'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)'
        );
      },
      version: 1,
    );
    // Ensure settings table exists (for upgrades)
    await database.execute('CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT)');
  }


  Future<void> _addEntry(int value, String option, String symptoms, DateTime dateTime) async {
    await database.insert(
      'entries',
      {
        'date': '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
        'time': '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        'value': value,
        'option': option,
        'symptoms': symptoms,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    setState(() {});
  }

  Future<void> _updateEntry(int id, int value, String option, String symptoms, DateTime dateTime) async {
    await database.update(
      'entries',
      {
        'date': '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
        'time': '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        'value': value,
        'option': option,
        'symptoms': symptoms,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    setState(() {});
  }

  Future<void> _deleteEntry(int id) async {
    await database.delete('entries', where: 'id = ?', whereArgs: [id]);
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _getEntries() async {
    return await database.query('entries');
  }
  void _showAddEntryDialog(BuildContext context) {
    DateTime selectedDateTime = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peak Flow Value'),
                    ),
                    DropdownButton<String>(
                      value: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                        setStateDialog(() {});
                      },
                      items: options.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                    ),
                    if (selectedOption == 'Symptomatic')
                      TextField(
                        controller: symptomsController,
                        decoration: const InputDecoration(labelText: 'Symptoms'),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Date: ${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDateTime = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  selectedDateTime.hour,
                                  selectedDateTime.minute,
                                );
                              });
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Time: ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDateTime = DateTime(
                                  selectedDateTime.year,
                                  selectedDateTime.month,
                                  selectedDateTime.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                          child: const Text('Pick Time'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final value = int.tryParse(valueController.text) ?? 0;
                    final symptoms = selectedOption == 'Symptomatic' ? symptomsController.text : '';
                    _addEntry(value, selectedOption, symptoms, selectedDateTime);
                    valueController.clear();
                    symptomsController.clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEntryDialog(BuildContext context, Map<String, dynamic> entry) {
    valueController.text = entry['value'].toString();
    selectedOption = entry['option'] ?? options[0];
    symptomsController.text = entry['symptoms'] ?? '';
    DateTime selectedDateTime = DateTime.tryParse('${entry['date']} ${entry['time']}') ?? DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peak Flow Value'),
                    ),
                    DropdownButton<String>(
                      value: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                        setStateDialog(() {});
                      },
                      items: options.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                    ),
                    if (selectedOption == 'Symptomatic')
                      TextField(
                        controller: symptomsController,
                        decoration: const InputDecoration(labelText: 'Symptoms'),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Date: ${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDateTime = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  selectedDateTime.hour,
                                  selectedDateTime.minute,
                                );
                              });
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Time: ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDateTime = DateTime(
                                  selectedDateTime.year,
                                  selectedDateTime.month,
                                  selectedDateTime.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                          child: const Text('Pick Time'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final value = int.tryParse(valueController.text) ?? 0;
                    final symptoms = selectedOption == 'Symptomatic' ? symptomsController.text : '';
                    _updateEntry(entry['id'], value, selectedOption, symptoms, selectedDateTime);
                    valueController.clear();
                    symptomsController.clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToGraphPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GraphPage(database: database),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peak Flow Meter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => _navigateToGraphPage(context),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _dbInitFuture,
        builder: (context, dbSnapshot) {
          if (dbSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getEntries(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data!;
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'No entries yet. Tap + to add your first entry!',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    title: Text(
                      'Value: ${entry['value']}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${entry['date']} ${entry['time']} - ${entry['option']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry['symptoms'] != null && entry['symptoms'] != '')
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              'Symptoms: ${entry['symptoms']}',
                              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditEntryDialog(context, entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Entry'),
                                content: const Text('Are you sure you want to delete this entry?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              _deleteEntry(entry['id']);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GraphPage extends StatelessWidget {
  final Database database;

  const GraphPage({super.key, required this.database});

  Future<List<Map<String, dynamic>>> _getEntryList() async {
    return await database.query('entries');
  }

  @override
  Widget build(BuildContext context) {
    return _GraphPageWithRange(database: database);
  }
}

class _GraphPageWithRange extends StatefulWidget {
  final Database database;
  const _GraphPageWithRange({super.key, required this.database});

  @override
  State<_GraphPageWithRange> createState() => _GraphPageWithRangeState();
}

class _GraphPageWithRangeState extends State<_GraphPageWithRange> {
  final GlobalKey _chartKey = GlobalKey();
  DateTime? _startDate;
  DateTime? _endDate;
  double _threshold1 = 200;
  double _threshold2 = 100;
  late TextEditingController _threshold1Controller;
  late TextEditingController _threshold2Controller;

  Future<void> _exportData(BuildContext context, List<Map<String, dynamic>> entries) async {
    // Generate CSV string
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('date,time,value,option,symptoms');
    for (final e in entries) {
      csvBuffer.writeln('${e['date']},${e['time']},${e['value']},${e['option']},${e['symptoms'] ?? ''}');
    }
    // Save to file or share (for now, just show dialog with CSV)
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exported CSV'),
        content: SingleChildScrollView(child: Text(csvBuffer.toString())),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _exportChart(BuildContext context, GlobalKey chartKey) async {
    // Render chart as image and show in dialog (for now)
    final boundary = chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exported Chart Image'),
            content: Image.memory(pngBytes),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
          ),
        );
      }
    }
  }

  Future<String?> _getSetting(String key) async {
    final db = widget.database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) return result.first['value'] as String?;
    return null;
  }

  Future<void> _setSetting(String key, String value) async {
    final db = widget.database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _loadThresholds() async {
    final upper = await _getSetting('upper_threshold');
    final lower = await _getSetting('lower_threshold');
    setState(() {
      if (upper != null) {
        _threshold1 = double.tryParse(upper) ?? _threshold1;
        _threshold1Controller.text = _threshold1.toString();
      }
      if (lower != null) {
        _threshold2 = double.tryParse(lower) ?? _threshold2;
        _threshold2Controller.text = _threshold2.toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _threshold1Controller = TextEditingController(text: _threshold1.toString());
    _threshold2Controller = TextEditingController(text: _threshold2.toString());
    _threshold1Controller.addListener(() {
      final d = double.tryParse(_threshold1Controller.text);
      if (d != null && d != _threshold1) {
        setState(() => _threshold1 = d);
        _setSetting('upper_threshold', d.toString());
      }
    });
    _threshold2Controller.addListener(() {
      final d = double.tryParse(_threshold2Controller.text);
      if (d != null && d != _threshold2) {
        setState(() => _threshold2 = d);
        _setSetting('lower_threshold', d.toString());
      }
    });
    _loadThresholds();
  }

  @override
  void dispose() {
    _threshold1Controller.dispose();
    _threshold2Controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getEntryList() async {
    return await widget.database.query('entries');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export_data') {
                // Export currently displayed data
                final entries = await _getEntryList();
                List<Map<String, dynamic>> filtered = entries;
                if (_startDate != null) {
                  filtered = filtered.where((e) {
                    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime(1900);
                    return !date.isBefore(_startDate!);
                  }).toList();
                }
                if (_endDate != null) {
                  filtered = filtered.where((e) {
                    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime(1900);
                    return !date.isAfter(_endDate!);
                  }).toList();
                }
                await _exportData(context, filtered);
              } else if (value == 'export_chart') {
                await _exportChart(context, _chartKey);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export_data', child: Text('Export Data (CSV)')),
              const PopupMenuItem(value: 'export_chart', child: Text('Export Chart (Image)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                            });
                          }
                        },
                        child: Text(_startDate == null ? 'Start Date' : 'Start: ${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _endDate = picked;
                            });
                          }
                        },
                        child: Text(_endDate == null ? 'End Date' : 'End: ${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear range',
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Upper Threshold',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _threshold1Controller,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Lower Threshold',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _threshold2Controller,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getEntryList(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<Map<String, dynamic>> entries = snapshot.data!;
                // Filter by date range if set
                if (_startDate != null) {
                  entries = entries.where((e) {
                    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime(1900);
                    return !date.isBefore(_startDate!);
                  }).toList();
                }
                if (_endDate != null) {
                  entries = entries.where((e) {
                    final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime(1900);
                    return !date.isAfter(_endDate!);
                  }).toList();
                }
                if (entries.length < 2) {
                  return const Center(
                    child: Text(
                      'Not enough data to display a graph. Add at least 2 entries.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                // Sort by date and time descending (make a copy first)
                final sortedEntries = List<Map<String, dynamic>>.from(entries);
                sortedEntries.sort((a, b) {
                  final dateA = DateTime.tryParse((a['date'] ?? '') + ' ' + (a['time'] ?? '00:00')) ?? DateTime(1900);
                  final dateB = DateTime.tryParse((b['date'] ?? '') + ' ' + (b['time'] ?? '00:00')) ?? DateTime(1900);
                  return dateB.compareTo(dateA);
                });
                final spots = <FlSpot>[];
                final types = <String>[];
                final dateLabels = <int, String>{};
                for (var i = 0; i < sortedEntries.length; i++) {
                  final entry = sortedEntries[i];
                  spots.add(FlSpot(i.toDouble(), (entry['value'] as int).toDouble()));
                  types.add((entry['option'] as String?)?.toLowerCase() ?? '');
                  dateLabels[i] = entry['date'] ?? '';
                }
                Color getDotColor(String type) {
                  switch (type) {
                    case 'morning':
                      return Colors.red;
                    case 'night':
                    case 'evening':
                      return Colors.green;
                    case 'symptomatic':
                      return Colors.orange;
                    default:
                      return Colors.black;
                  }
                }
                double upper = _threshold1 > _threshold2 ? _threshold1 : _threshold2;
                double lower = _threshold1 > _threshold2 ? _threshold2 : _threshold1;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 300,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            barWidth: 4,
                            gradient: LinearGradient(
                              colors: [Colors.black, Colors.black],
                            ),
                            belowBarData: BarAreaData(show: false),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final type = (index < types.length) ? types[index] : '';
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: getDotColor(type),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ],
                        rangeAnnotations: RangeAnnotations(
                          horizontalRangeAnnotations: [
                            HorizontalRangeAnnotation(
                              y1: 0,
                              y2: lower,
                              color: Colors.red.withOpacity(0.2),
                            ),
                            HorizontalRangeAnnotation(
                              y1: lower,
                              y2: upper,
                              color: Colors.yellow.withOpacity(0.2),
                            ),
                            HorizontalRangeAnnotation(
                              y1: upper,
                              y2: 300,
                              color: Colors.green.withOpacity(0.2),
                            ),
                          ],
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                final label = dateLabels[idx] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}