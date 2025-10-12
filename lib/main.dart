import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // 添加系統UI控制
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'consts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add drift imports
import 'package:drift/drift.dart' as drift;
import 'drift_db.dart';

void main() {
  // 設置系統UI為邊緣到邊緣模式，相容Android 15
  WidgetsFlutterBinding.ensureInitialized();
  
  // 使用新的邊緣到邊緣API替代已棄用的方法
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peak Flow Meter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 確保主題相容Android 15的邊緣到邊緣顯示
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
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
  AppDatabase? database;  // 改为可空类型
  late Future<void> _dbInitFuture;
  final TextEditingController valueController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  String selectedOption = 'morning';
  final List<String> options = ['morning', 'night', 'symptomatic'];

  @override
  void initState() {
    super.initState();
    _dbInitFuture = _initDatabase();
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      
      if (isFirstTime) {
        // Wait a bit for the UI to settle, then show guide
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showGuide(context);
              // Mark as not first time
              prefs.setBool('isFirstTime', false);
            }
          });
        });
      }
    } catch (e) {
      print('Error checking first time user: $e');
    }
  }

  Future<void> _initDatabase() async {
    try {
      final db = AppDatabase();
      // 测试数据库连接
      await db.customSelect('SELECT 1').get();
      database = db;
      print('Database initialized successfully');
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> _addEntry(int value, String option, String symptoms, DateTime dateTime) async {
    try {
      final db = database;
      if (db == null) {
        print('Database not initialized');
        return;
      }
      
      await db.into(db.entries).insert(
        EntriesCompanion.insert(
          date: '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
          time: '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
          value: value,
          option: option,
          symptoms: drift.Value(symptoms),
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('Error adding entry: $e');
    }
  }

  Future<void> _updateEntry(int id, int value, String option, String symptoms, DateTime dateTime) async {
    try {
      final db = database;
      if (db == null) {
        print('Database not initialized');
        return;
      }
      await (db.update(db.entries)..where((tbl) => tbl.id.equals(id))).write(
        EntriesCompanion(
          date: drift.Value('${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}'),
          time: drift.Value('${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'),
          value: drift.Value(value),
          option: drift.Value(option),
          symptoms: drift.Value(symptoms),
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('Error updating entry: $e');
    }
  }

  Future<void> _deleteEntry(int id) async {
    try {
      final db = database;
      if (db == null) {
        print('Database not initialized');
        return;
      }
      await (db.delete(db.entries)..where((tbl) => tbl.id.equals(id))).go();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error deleting entry: $e');
    }
  }

  Future<List<Entry>> _getEntries() async {
    try {
      final db = database;
      if (db == null) {
        print('Database not initialized');
        return [];
      }
      return await db.select(db.entries).get();
    } catch (e) {
      print('Error getting entries: $e');
      return [];
    }
  }
  void _showAddEntryDialog(BuildContext context) {
    // Clear controllers to ensure clean state for new entry
    valueController.clear();
    symptomsController.clear();
    DateTime? selectedDateTime; // Start with null instead of DateTime.now()
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppStrings.get('addEntry')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: AppStrings.get('peakFlowValue')),
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
                          child: Text(AppStrings.get(option)),
                        );
                      }).toList(),
                    ),
                    if (selectedOption == 'symptomatic')
                      TextField(
                        controller: symptomsController,
                        decoration: InputDecoration(
                          labelText: AppStrings.get('symptoms'),
                          hintText: AppStrings.get('symptomsHint'), // Unicode hint text
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.done,
                        maxLines: null,
                        inputFormatters: [],
                        // textCapitalization: TextCapitalization.none,
                        // enableSuggestions: true,
                        // autocorrect: false,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(selectedDateTime != null 
                            ? '${AppStrings.get('date')}: ${selectedDateTime!.year}-${selectedDateTime!.month.toString().padLeft(2, '0')}-${selectedDateTime!.day.toString().padLeft(2, '0')}'
                            : '${AppStrings.get('date')}: ${AppStrings.get('notSelected')}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDateTime = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  selectedDateTime?.hour ?? DateTime.now().hour,
                                  selectedDateTime?.minute ?? DateTime.now().minute,
                                );
                              });
                            }
                          },
                          child: Text(AppStrings.get('pickDate')),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(selectedDateTime != null 
                            ? '${AppStrings.get('time')}: ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}'
                            : '${AppStrings.get('time')}: ${AppStrings.get('notSelected')}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedDateTime != null 
                                ? TimeOfDay.fromDateTime(selectedDateTime!)
                                : TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDateTime = DateTime(
                                  selectedDateTime?.year ?? DateTime.now().year,
                                  selectedDateTime?.month ?? DateTime.now().month,
                                  selectedDateTime?.day ?? DateTime.now().day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                          child: Text(AppStrings.get('pickTime')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear controllers when canceling to avoid carrying over values
                    valueController.clear();
                    symptomsController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(AppStrings.get('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    final value = int.tryParse(valueController.text) ?? 0;
                    final symptoms = selectedOption == 'symptomatic' ? symptomsController.text : '';
                    // Use current time if no date/time was selected
                    final finalDateTime = selectedDateTime ?? DateTime.now();
                    _addEntry(value, selectedOption, symptoms, finalDateTime);
                    valueController.clear();
                    symptomsController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(AppStrings.get('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEntryDialog(BuildContext context, Entry entry) {
    valueController.text = entry.value.toString();
    selectedOption = (entry.option).toString().toLowerCase();
    symptomsController.text = entry.symptoms ?? '';
    DateTime selectedDateTime = DateTime.tryParse('${entry.date} ${entry.time}') ?? DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(AppStrings.get('editEntry')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: AppStrings.get('peakFlowValue')),
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
                          child: Text(AppStrings.get(option)),
                        );
                      }).toList(),
                    ),
                    if (selectedOption == 'symptomatic')
                      TextField(
                        controller: symptomsController,
                        decoration: InputDecoration(
                          labelText: AppStrings.get('symptoms'),
                          hintText: AppStrings.get('symptomsHint'), // Use consistent localized hint
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.done,
                        maxLines: null,
                        inputFormatters: [],
                        // textCapitalization: TextCapitalization.none,
                        // enableSuggestions: true,
                        // autocorrect: false,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${AppStrings.get('date')}: ${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}'),
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
                          child: Text(AppStrings.get('pickDate')),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${AppStrings.get('time')}: ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}'),
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
                          child: Text(AppStrings.get('pickTime')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear controllers when canceling to avoid carrying over values
                    valueController.clear();
                    symptomsController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(AppStrings.get('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    final value = int.tryParse(valueController.text) ?? 0;
                    final symptoms = selectedOption == 'symptomatic' ? symptomsController.text : '';
                    _updateEntry(entry.id, value, selectedOption, symptoms, selectedDateTime);
                    valueController.clear();
                    symptomsController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(AppStrings.get('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GuidePageView(),
      ),
    );
  }

  void _navigateToGraphPage(BuildContext context) {
    final db = database;
    if (db == null) {
      print('Database not initialized, cannot navigate to graph page');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GraphPage(database: db),
      ),
    );
  }

  @override
  void dispose() {
    // 清理数据库连接
    try {
      database?.close();
    } catch (e) {
      print('Error closing database: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('appTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showGuide(context),
            tooltip: AppStrings.get('guide'),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => _navigateToGraphPage(context),
          ),
          DropdownButton<String>(
            value: AppStrings.currentLanguage,
            icon: const Icon(Icons.language, color: Colors.white),
            underline: Container(),
            dropdownColor: Colors.white,
            onChanged: (String? lang) {
              if (lang != null) {
                setState(() {
                  AppStrings.currentLanguage = lang;
                });
              }
            },
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(AppStrings.get('english')),
              ),
              DropdownMenuItem(
                value: 'zh',
                child: Text(AppStrings.get('chinese')),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _dbInitFuture,
        builder: (context, dbSnapshot) {
          if (dbSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<List<Entry>>(
            future: _getEntries(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              List<Entry> entries = snapshot.data!;
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.get('noEntries'),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              // Sort entries by date and time descending
              entries = List<Entry>.from(entries);
              entries.sort((a, b) {
                final dateA = DateTime.tryParse('${a.date} ${a.time}') ?? DateTime(1900);
                final dateB = DateTime.tryParse('${b.date} ${b.time}') ?? DateTime(1900);
                return dateB.compareTo(dateA);
              });
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final date = entry.date;
                  final time = entry.time;
                  final value = entry.value.toString();
                  final option = (entry.option).toString().toLowerCase();
                  final symptoms = (entry.symptoms != null && entry.symptoms.toString().trim().isNotEmpty)
                      ? entry.symptoms.toString().trim()
                      : null;
                  Color optionColor;
                  switch (option) {
                    case 'morning':
                      optionColor = Colors.red;
                      break;
                    case 'night':
                      optionColor = Colors.green;
                      break;
                    case 'symptomatic':
                      optionColor = Colors.orange;
                      break;
                    default:
                      optionColor = Colors.black;
                  }
                  return ListTile(
                    title: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.get(option),
                            style: TextStyle(fontSize: 16, color: optionColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            value,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    subtitle: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          if (symptoms != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              symptoms,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: SizedBox(
                      width: 96, // Fixed width for buttons
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditEntryDialog(context, entry),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(AppStrings.get('deleteEntry')),
                                  content: Text(AppStrings.get('deleteEntryConfirm')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(AppStrings.get('cancel')),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text(AppStrings.get('delete')),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                _deleteEntry(entry.id);
                              }
                            },
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )
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
  final AppDatabase database;

  const GraphPage({super.key, required this.database});


  @override
  Widget build(BuildContext context) {
    return _GraphPageWithRange(database: database);
  }
}

class _GraphPageWithRange extends StatefulWidget {
  final AppDatabase database;
  const _GraphPageWithRange({required this.database});

  @override
  State<_GraphPageWithRange> createState() => _GraphPageWithRangeState();
}

// Graph page
class _GraphPageWithRangeState extends State<_GraphPageWithRange> {
  final GlobalKey _chartKey = GlobalKey();
  DateTime? _startDate;
  DateTime? _endDate;
  double _threshold1 = AppConsts.upperThreshold; // default
  double _threshold2 = AppConsts.lowerThreshold; // default
  late TextEditingController _threshold1Controller;
  late TextEditingController _threshold2Controller;

  Future<void> _exportData(BuildContext context, List<Entry> entries) async {
    try {
      // Generate CSV string
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('date,time,value,option,symptoms');
      for (final e in entries) {
        csvBuffer.writeln('${e.date},${e.time},${e.value},${e.option},${e.symptoms ?? ''}');
      }
      
      // Use Documents directory for iOS compatibility
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'peakflow_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsString(csvBuffer.toString());
      if (!mounted) return;
      
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.get('csvExported')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${AppStrings.get('csvSave')}:'),
              const SizedBox(height: 8),
              Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (Platform.isIOS)
                Text(
                  'File saved to app documents. Use "Files" app to access.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            if (!Platform.isIOS)
              TextButton(
                onPressed: () {
                  OpenFile.open(filePath);
                  Navigator.pop(dialogContext);
                },
                child: Text(AppStrings.get('open')),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppStrings.get('close')),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error exporting data: $e');
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Export Error'),
          content: Text('Failed to export data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _exportChart(BuildContext context, GlobalKey chartKey) async {
    try {
      // Render chart as image and save to file
      final boundary = chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Chart not ready for export');
      }
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image data');
      }
      
      final pngBytes = byteData.buffer.asUint8List();
      
      // Use Documents directory for iOS compatibility
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'peakflow_chart_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(pngBytes);
      if (!mounted) return;
      
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.get('chartImageExported')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(pngBytes, height: 150),
              const SizedBox(height: 12),
              Text(
                '${AppStrings.get('chartImageSave')}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                fileName,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (Platform.isIOS)
                Text(
                  'Image saved to app documents. Use "Files" app to access and share.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            if (!Platform.isIOS)
              TextButton(
                onPressed: () {
                  OpenFile.open(filePath);
                  Navigator.pop(dialogContext);
                },
                child: Text(AppStrings.get('open')),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppStrings.get('close')),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error exporting chart: $e');
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Export Error'),
          content: Text('Failed to export chart: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<String?> _getSetting(String key) async {
    try {
      final db = widget.database;
      final query = db.select(db.settings)..where((tbl) => tbl.key.equals(key));
      final result = await query.get();
      if (result.isNotEmpty) return result.first.value;
      return null;
    } catch (e) {
      print('Error getting setting $key: $e');
      return null;
    }
  }

  Future<void> _setSetting(String key, String value) async {
    try {
      final db = widget.database;
      await db.into(db.settings).insertOnConflictUpdate(
        SettingsCompanion(
          key: drift.Value(key),
          value: drift.Value(value),
        ),
      );
    } catch (e) {
      print('Error setting $key: $e');
    }
  }

  Future<void> _loadThresholds() async {
    final upper = await _getSetting('upper_threshold');
    final lower = await _getSetting('lower_threshold');
    setState(() {
      if (upper != null) {
        var parsedUpper = double.tryParse(upper) ?? _threshold1;
        // Ensure loaded threshold is within bounds
        parsedUpper = parsedUpper.clamp(AppConsts.minYValue, AppConsts.maxYValue);
        _threshold1 = parsedUpper;
        _threshold1Controller.text = _threshold1.toString();
      }
      if (lower != null) {
        var parsedLower = double.tryParse(lower) ?? _threshold2;
        // Ensure loaded threshold is within bounds
        parsedLower = parsedLower.clamp(AppConsts.minYValue, AppConsts.maxYValue);
        _threshold2 = parsedLower;
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
        // Validate threshold is within bounds
        if (d > AppConsts.maxYValue) {
          _threshold1Controller.text = AppConsts.maxYValue.toString();
          return;
        }
        if (d < AppConsts.minYValue) {
          _threshold1Controller.text = AppConsts.minYValue.toString();
          return;
        }
        setState(() => _threshold1 = d);
        _setSetting('upper_threshold', d.toString());
      }
    });
    _threshold2Controller.addListener(() {
      final d = double.tryParse(_threshold2Controller.text);
      if (d != null && d != _threshold2) {
        // Validate threshold is within bounds
        if (d > AppConsts.maxYValue) {
          _threshold2Controller.text = AppConsts.maxYValue.toString();
          return;
        }
        if (d < AppConsts.minYValue) {
          _threshold2Controller.text = AppConsts.minYValue.toString();
          return;
        }
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

  Future<List<Entry>> _getEntryList() async {
    try {
      return await widget.database.select(widget.database.entries).get();
    } catch (e) {
      print('Error getting entry list: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Graph page top bar with export menu
      appBar: AppBar(
        title: Text(AppStrings.get('graphTitle')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            onSelected: (value) async {
              if (value == 'export_data') {
                // Export currently displayed data
                final entries = await _getEntryList();
                List<Entry> filtered = entries;
                if (_startDate != null) {
                  filtered = filtered.where((e) {
                    final date = DateTime.tryParse(e.date) ?? DateTime(1900);
                    return !date.isBefore(_startDate!);
                  }).toList();
                }
                if (_endDate != null) {
                  filtered = filtered.where((e) {
                    final date = DateTime.tryParse(e.date) ?? DateTime(1900);
                    return !date.isAfter(_endDate!);
                  }).toList();
                }
                await _exportData(context, filtered);
              } else if (value == 'export_chart') {
                await _exportChart(context, _chartKey);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export_data', child: Text(AppStrings.get('exportDataCSV'))),
              PopupMenuItem(value: 'export_chart', child: Text(AppStrings.get('exportChartImage'))),
            ],
          ),
        ],
      ),

      // Graph page body with date range selectors and chart
      body: SingleChildScrollView(
        // Select date interval
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                          child: Text(_startDate == null
                            ? AppStrings.get('startDate')
                            : '${AppStrings.get('start')}: ${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
                          ),
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
                          child: Text(_endDate == null
                            ? AppStrings.get('endDate')
                            : '${AppStrings.get('end')}: ${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
                          ),
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
                          decoration: InputDecoration(
                            labelText: AppStrings.get('upperThreshold'),
                            hintText: '${AppConsts.minYValue.toInt()}-${AppConsts.maxYValue.toInt()}',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: _threshold1Controller,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: AppStrings.get('lowerThreshold'),
                            hintText: '${AppConsts.minYValue.toInt()}-${AppConsts.maxYValue.toInt()}',
                            border: const OutlineInputBorder(),
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

            // Chart
            SizedBox(
              height: 400,
              child: FutureBuilder<List<Entry>>(
                future: _getEntryList(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<Entry> entries = snapshot.data!;
                  // Filter by date range if set
                  if (_startDate != null) {
                    entries = entries.where((e) {
                      final date = DateTime.tryParse(e.date) ?? DateTime(1900);
                      return !date.isBefore(_startDate!);
                    }).toList();
                  }
                  if (_endDate != null) {
                    entries = entries.where((e) {
                      final date = DateTime.tryParse(e.date) ?? DateTime(1900);
                      return !date.isAfter(_endDate!);
                    }).toList();
                  }
                  if (entries.length < 2) {
                    return Center(
                      child: Text(
                        AppStrings.get('notEnoughData'),
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  // Sort by date and time descending (make a copy first)
                  final sortedEntries = List<Entry>.from(entries);
                  sortedEntries.sort((a, b) {
                    final dateA = DateTime.tryParse('${a.date} ${a.time}') ?? DateTime(1900);
                    final dateB = DateTime.tryParse('${b.date} ${b.time}') ?? DateTime(1900);
                    return dateB.compareTo(dateA);
                  });
                  final spots = <FlSpot>[];
                  final types = <String>[];
                  final dateLabels = <double, String>{};
                  // Use time since first entry as x value (in days, with fraction for time)
                  if (sortedEntries.isEmpty) {
                    return const SizedBox();
                  }
                  final firstDateTime = DateTime.tryParse('${sortedEntries.last.date} ${sortedEntries.last.time}') ?? DateTime(1900);
                  for (var i = 0; i < sortedEntries.length; i++) {
                    final entry = sortedEntries[i];
                    final dateStr = entry.date;
                    final timeStr = entry.time;
                    final dt = DateTime.tryParse('$dateStr $timeStr') ?? firstDateTime;
                    final x = dt.difference(firstDateTime).inMinutes / 1440.0; // days as double
                    spots.add(FlSpot(x, (entry.value).toDouble()));
                    types.add((entry.option as String?)?.toLowerCase() ?? '');
                    // Only keep the day part for the label
                    String dayLabel = '';
                    if (dateStr.length >= 10) {
                      // Expecting format YYYY-MM-DD
                      dayLabel = dateStr.substring(8, 10);
                    }
                    dateLabels[x] = dayLabel;
                  }
                  Color getDotColor(String type) {
                    switch (type) {
                      case 'morning':
                        return Colors.red;
                      case 'night':
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
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 8.0, bottom: 8.0),
                        child: LineChart(
                          LineChartData(
                            minY: AppConsts.minYValue,
                            maxY: AppConsts.maxYValue,
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
                                  y1: AppConsts.minYValue,
                                  y2: lower,
                                  color: Colors.red, //.withOpacity(0.2),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: lower,
                                  y2: upper,
                                  color: Colors.yellow, //.withOpacity(0.2),
                                ),
                                HorizontalRangeAnnotation(
                                  y1: upper,
                                  y2: AppConsts.maxYValue,
                                  color: Colors.green, //.withOpacity(0.2),
                                ),
                              ],
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: MediaQuery.of(context).size.width < 360 ? 35 : 40,
                                  interval: 50,
                                  getTitlesWidget: (value, meta) {
                                    // Use smaller font size for narrow screens
                                    double fontSize = MediaQuery.of(context).size.width < 360 ? 10 : 12;
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        color: Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    // Show only the day part as label
                                    String label = '';
                                    double? closest;
                                    for (final k in dateLabels.keys) {
                                      if (closest == null || (k - value).abs() < (closest - value).abs()) {
                                        closest = k;
                                      }
                                    }
                                    if (closest != null && (closest - value).abs() < 0.5) {
                                      label = dateLabels[closest] ?? '';
                                    }
                                    // Use smaller font size for narrow screens
                                    double fontSize = MediaQuery.of(context).size.width < 360 ? 10 : 12;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        label,
                                        style: TextStyle(fontSize: fontSize),
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
                    )
                  );
                }, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Guide Page View
class GuidePageView extends StatefulWidget {
  const GuidePageView({super.key});

  @override
  State<GuidePageView> createState() => _GuidePageViewState();
}

class _GuidePageViewState extends State<GuidePageView> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6; // Welcome + 5 steps

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipGuide() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('guide')),
        actions: [
          TextButton(
            onPressed: _skipGuide,
            child: Text(
              AppStrings.get('skipGuide'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildWelcomePage(),
                _buildGuidePage(
                  AppStrings.get('guideStep1Title'),
                  AppStrings.get('guideStep1Desc'),
                  Icons.add_circle_outline,
                  Colors.blue,
                ),
                _buildGuidePage(
                  AppStrings.get('guideStep2Title'),
                  AppStrings.get('guideStep2Desc'),
                  Icons.medical_services_outlined,
                  Colors.orange,
                ),
                _buildGuidePage(
                  AppStrings.get('guideStep3Title'),
                  AppStrings.get('guideStep3Desc'),
                  Icons.show_chart,
                  Colors.green,
                ),
                _buildGuidePage(
                  AppStrings.get('guideStep4Title'),
                  AppStrings.get('guideStep4Desc'),
                  Icons.file_download_outlined,
                  Colors.purple,
                ),
                _buildGuidePage(
                  AppStrings.get('guideStep5Title'),
                  AppStrings.get('guideStep5Desc'),
                  Icons.tips_and_updates_outlined,
                  Colors.teal,
                ),
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                _currentPage > 0
                    ? ElevatedButton(
                        onPressed: _previousPage,
                        child: Text(AppStrings.get('previous')),
                      )
                    : const SizedBox.shrink(),
                // Page indicator
                Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                // Next/Finish button
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? AppStrings.get('getStarted')
                        : AppStrings.get('next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.air,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.get('welcomeTitle'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.get('welcomeSubtitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              AppStrings.get('welcomeDescription'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidePage(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}