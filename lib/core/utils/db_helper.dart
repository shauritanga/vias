import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../shared/models/prospectus_models.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vias_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE programs (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            duration TEXT,
            requirements TEXT,
            category TEXT,
            faculty TEXT,
            fee REAL,
            careerOpportunities TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE fee_structures (
            id TEXT PRIMARY KEY,
            programId TEXT,
            programName TEXT,
            tuitionFee REAL,
            registrationFee REAL,
            examinationFee REAL,
            otherFees REAL,
            currency TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE admission_info (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            generalRequirements TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE general_content (
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            category TEXT,
            lastUpdated TEXT,
            tags TEXT
          )
        ''');
      },
    );
  }

  // --- Programs ---
  Future<void> savePrograms(List<Program> programs) async {
    final dbClient = await db;
    final batch = dbClient.batch();
    await dbClient.delete('programs');
    for (final p in programs) {
      batch.insert('programs', {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'duration': p.duration,
        'requirements': p.requirements.join('|'),
        'category': p.category,
        'faculty': p.faculty,
        'fee': p.fee,
        'careerOpportunities': p.careerOpportunities.join('|'),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Program>> loadPrograms() async {
    final dbClient = await db;
    final maps = await dbClient.query('programs');
    return maps
        .map(
          (m) => Program(
            id: m['id'] as String,
            name: m['name'] as String,
            description: m['description'] as String,
            duration: m['duration'] as String,
            requirements: (m['requirements'] as String).split('|'),
            category: m['category'] as String,
            faculty: m['faculty'] as String,
            fee: m['fee'] as double?,
            careerOpportunities: (m['careerOpportunities'] as String).split(
              '|',
            ),
          ),
        )
        .toList();
  }

  // --- Fee Structures ---
  Future<void> saveFeeStructures(List<FeeStructure> fees) async {
    final dbClient = await db;
    final batch = dbClient.batch();
    await dbClient.delete('fee_structures');
    for (final f in fees) {
      batch.insert('fee_structures', f.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<FeeStructure>> loadFeeStructures() async {
    final dbClient = await db;
    final maps = await dbClient.query('fee_structures');
    return maps.map((m) => FeeStructure.fromMap(m)).toList();
  }

  // --- Admission Info ---
  Future<void> saveAdmissionInfo(List<AdmissionInfo> admissions) async {
    final dbClient = await db;
    final batch = dbClient.batch();
    await dbClient.delete('admission_info');
    for (final a in admissions) {
      batch.insert('admission_info', {
        'id': a.id,
        'title': a.title,
        'description': a.description,
        'generalRequirements': a.generalRequirements.join('|'),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<AdmissionInfo>> loadAdmissionInfo() async {
    final dbClient = await db;
    final maps = await dbClient.query('admission_info');
    return maps
        .map(
          (m) => AdmissionInfo(
            id: m['id'] as String,
            title: m['title'] as String,
            description: m['description'] as String,
            generalRequirements: (m['generalRequirements'] as String).split(
              '|',
            ),
          ),
        )
        .toList();
  }

  // --- General Content ---
  Future<void> saveGeneralContent(List<ProspectusContent> content) async {
    final dbClient = await db;
    final batch = dbClient.batch();
    await dbClient.delete('general_content');
    for (final c in content) {
      batch.insert('general_content', {
        'id': c.id,
        'title': c.title,
        'content': c.content,
        'category': c.category,
        'lastUpdated': c.lastUpdated.toIso8601String(),
        'tags': c.tags.join('|'),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProspectusContent>> loadGeneralContent() async {
    final dbClient = await db;
    final maps = await dbClient.query('general_content');
    return maps
        .map(
          (m) => ProspectusContent(
            id: m['id'] as String,
            title: m['title'] as String,
            content: m['content'] as String,
            category: m['category'] as String,
            lastUpdated: DateTime.parse(m['lastUpdated'] as String),
            tags: (m['tags'] as String).split('|'),
          ),
        )
        .toList();
  }
}
