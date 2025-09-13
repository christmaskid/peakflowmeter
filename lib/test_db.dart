import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Dog {
  final int id;
  final String name;
  final int age;

  Dog({required this.id, required this.name, required this.age});

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'age': age};
  }

  @override
  String toString() {
    return 'Dog{id: $id, name: $name, age: $age}';
  }
}

class DogDatabase {
  static final DogDatabase instance = DogDatabase._init();
  static Database? _database;

  DogDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('doggie_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        );
      },
    );
  }

  Future<void> insertDog(Dog dog) async {
    final db = await instance.database;
    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Dog>> fetchDogs() async {
    final db = await instance.database;
    final List<Map<String, Object?>> dogMaps = await db.query('dogs');
    return dogMaps.map((map) {
      return Dog(
        id: map['id'] as int,
        name: map['name'] as String,
        age: map['age'] as int,
      );
    }).toList();
  }

  Future<void> updateDog(Dog dog) async {
    final db = await instance.database;
    await db.update(
      'dogs',
      dog.toMap(),
      where: 'id = ?',
      whereArgs: [dog.id],
    );
  }

  Future<void> deleteDog(int id) async {
    final db = await instance.database;
    await db.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

class DogDatabaseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DogDatabaseScreen(),
    );
  }
}

class DogDatabaseScreen extends StatefulWidget {
  @override
  _DogDatabaseScreenState createState() => _DogDatabaseScreenState();
}

class _DogDatabaseScreenState extends State<DogDatabaseScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  List<Dog> _dogs = [];

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    final dogs = await DogDatabase.instance.fetchDogs();
    setState(() {
      _dogs = dogs;
    });
  }

  Future<void> _addDog() async {
    final name = _nameController.text;
    final age = int.tryParse(_ageController.text);
    if (name.isNotEmpty && age != null) {
      final newDog = Dog(id: DateTime.now().millisecondsSinceEpoch, name: name, age: age);
      await DogDatabase.instance.insertDog(newDog);
      _nameController.clear();
      _ageController.clear();
      _loadDogs();
    }
  }

  Future<void> _deleteDog(int id) async {
    await DogDatabase.instance.deleteDog(id);
    _loadDogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog Database'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Dog Name'),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Dog Age'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addDog,
              child: Text('Add Dog'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _dogs.length,
                itemBuilder: (context, index) {
                  final dog = _dogs[index];
                  return ListTile(
                    title: Text(dog.name),
                    subtitle: Text('Age: ${dog.age}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteDog(dog.id),
                    ),
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

void main() {
  runApp(DogDatabaseApp());
}
