import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:stc_training/helper/methods.dart';
import 'package:stc_training/services/CRUD/crud_exceptions.dart';
import 'package:stc_training/services/CRUD/offline_course_model.dart';
import 'package:stc_training/services/CRUD/offline_unit_model.dart';
import 'package:stc_training/services/CRUD/offline_video_model.dart';

class OfflineCoursesController extends GetxController {
  Database? _db;
  List<OfflineCourseModel> _courses = [];
  List<OfflineCourseModel> get courses => _courses;

  Future<void> _cacheCourses() async {
    final allCourses = await getAllCoursesWithDetails();
    _courses = allCourses;
    update();
  }

  Future<List<OfflineUnitModel>> getAllOfflineCourseUnits({coursePk}) async {
    final db = _getDatabaseOrThrow();
    List<Map<String, dynamic>> unitMaps = await db
        .query(offlineUnitTable, where: 'courseId = ?', whereArgs: [coursePk]);

    if (unitMaps.isNotEmpty) {
      List<OfflineUnitModel> units = unitMaps
          .map((unitMap) => OfflineUnitModel.fromJson(unitMap))
          .toList();
      return units;
    }
    throw CouldNotFindUnitsException();
  }

  Future<List<OfflineUnitModel>> getAllOfflineCourseUnitsWithData(
      {coursePk}) async {
    final db = _getDatabaseOrThrow();
    List<Map<String, dynamic>> unitMaps = await db
        .query(offlineUnitTable, where: 'courseId = ?', whereArgs: [coursePk]);

    if (unitMaps.isNotEmpty) {
      List<OfflineUnitModel> units = unitMaps
          .map((unitMap) => OfflineUnitModel.fromJson(unitMap))
          .toList();

      //Todo: get all the videos with that unit
      for (OfflineUnitModel unit in units) {
        List<Map<String, dynamic>> videoMaps = await db.query(offlineVideoTable,
            where: 'unitId = ?', whereArgs: [unit.pk]);
        List<OfflineVideoModel> videos = videoMaps
            .map((videoMap) => OfflineVideoModel.fromJson(videoMap))
            .toList();
        unit.videos =
            videos; // Assuming you add a 'videos' List<OfflineVideoModel> field in OfflineUnitModel
      }

      return units;
    }
    throw CouldNotFindUnitsException();
  }

  Future<List<OfflineVideoModel>> getAllOfflineUnitVideos({unitPk}) async {
    final db = _getDatabaseOrThrow();
    List<Map<String, dynamic>> videoMaps = await db
        .query(offlineVideoTable, where: 'unitId = ?', whereArgs: [unitPk]);
    if (videoMaps.isNotEmpty) {
      List<OfflineVideoModel> videos = videoMaps
          .map((videoMap) => OfflineVideoModel.fromJson(videoMap))
          .toList();
      return videos;
    }
    throw CouldNotFindVideosException();
  }

  // Get all courses with their associated units and videos
  Future<List<OfflineCourseModel>> getAllCoursesWithDetails() async {
    final db = _getDatabaseOrThrow();
    List<Map<String, dynamic>> courseMaps = await db.query(offlineCourseTable);
    List<OfflineCourseModel> courses = [];

    for (var courseMap in courseMaps) {
      OfflineCourseModel course = OfflineCourseModel.fromJson(courseMap);
      List<Map<String, dynamic>> unitMaps = await db.query(offlineUnitTable,
          where: 'courseId = ?', whereArgs: [course.pk]);

      List<OfflineUnitModel> units = unitMaps
          .map((unitMap) => OfflineUnitModel.fromJson(unitMap))
          .toList();

      for (OfflineUnitModel unit in units) {
        List<Map<String, dynamic>> videoMaps = await db.query(offlineVideoTable,
            where: 'unitId = ?', whereArgs: [unit.pk]);
        List<OfflineVideoModel> videos = videoMaps
            .map((videoMap) => OfflineVideoModel.fromJson(videoMap))
            .toList();
        unit.videos =
            videos; // Assuming you add a 'videos' List<OfflineVideoModel> field in OfflineUnitModel
      }

      course.units =
          units; // Assuming you add a 'units' List<OfflineUnitModel> field in OfflineCourseModel
      courses.add(course);
    }

    return courses;
  }

  //todo: CREATE cousre
  Future<OfflineCourseModel> createOfflineCourse(
      OfflineCourseModel course) async {
    final db = _getDatabaseOrThrow();
    //todo: check if the course all ready exists
    final List<Map<String, dynamic>> results = await db.query(
      offlineCourseTable,
      limit: 1,
      where: 'pk = ?',
      whereArgs: [course.pk],
    );
    if (results.isNotEmpty) {
      return OfflineCourseModel.fromJson(results.first);
    }

    await db.insert(
      offlineCourseTable,
      course
          .toMap(), // Assuming toMap() method is properly implemented in OfflineCourseModel
      conflictAlgorithm: ConflictAlgorithm
          .replace, // To handle cases where the same PK might be inserted
    );

    //todo: update the cashe
    _courses.add(course);
    //todo: update the UI
    update();
    return course;
  }

  //todo: CREATE unit
  Future<OfflineUnitModel> createOfflineUnit(OfflineUnitModel unit) async {
    final db = _getDatabaseOrThrow();
    //todo: make suer the course is exists fist
    // First, check if the course exists
    List<Map<String, dynamic>> course = await db
        .rawQuery('SELECT pk FROM OfflineCourse WHERE pk = ?', [unit.courseId]);
    if (course.isEmpty) {
      // Handle the case where the course does not exist
      // You could throw an exception, return an error code, or handle it in another appropriate way
      throw CouldNotFindCourseException();
    }

    var existingUnit = await db.query(
      offlineUnitTable,
      where: 'pk = ?',
      whereArgs: [unit.pk],
    );

    if (existingUnit.isNotEmpty) {
      // If the unit exists, return it
      return OfflineUnitModel.fromJson(existingUnit.first);
    }

    await db.insert(
      offlineUnitTable,
      unit.toMap(), // Assuming toMap() method is implemented in OfflineUnitModel
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return unit;
  }

  //todo: CREATE video
  Future<OfflineVideoModel> createOfflineVideo(OfflineVideoModel video) async {
    final db = _getDatabaseOrThrow();
    List<Map<String, dynamic>> unit = await db
        .rawQuery('SELECT pk FROM OfflineUnit WHERE pk = ?', [video.unitId]);
    if (unit.isEmpty) {
      // Handle the case where the unit does not exist
      // Could throw an exception, return an error code, or handle it another appropriate way
      throw CouldNotFindUnitException();
    }

    var existingVideo = await db.query(
      offlineVideoTable,
      where: 'id = ?',
      whereArgs: [video.id],
    );

    if (existingVideo.isNotEmpty) {
      // If the video exists, return it
      return OfflineVideoModel.fromJson(existingVideo.first);
    }

    await db.insert(
      offlineVideoTable,
      video
          .toMap(), // Assuming toMap() method is implemented in OfflineVideoModel
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return video;
  }

  //todo: get single course
  // Method to fetch a single course by its primary key
  Future<OfflineCourseModel?> getCourse(int pk) async {
    final db = _getDatabaseOrThrow();
    // final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM OfflineCourse WHERE pk = ?', [pk]);
    final List<Map<String, dynamic>> maps = await db.query(
      offlineCourseTable,
      limit: 1,
      where: 'pk = ?',
      whereArgs: [pk],
    );
    if (maps.isNotEmpty) {
      return OfflineCourseModel.fromJson(maps.first);
    }
    throw CouldNotFindCourseException();
    // return null;
  }

  //todo: get single unit
  // Method to fetch a single course by its primary key
  Future<OfflineUnitModel?> getUnit(int pk) async {
    final db = _getDatabaseOrThrow();
    // final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM OfflineCourse WHERE pk = ?', [pk]);
    final List<Map<String, dynamic>> maps = await db.query(
      offlineUnitTable,
      limit: 1,
      where: 'pk = ?',
      whereArgs: [pk],
    );
    if (maps.isNotEmpty) {
      return OfflineUnitModel.fromJson(maps.first);
    }
    throw CouldNotFindUnitException();
    // return null;
  }

  //todo: get single video
  // Method to fetch a single course by its primary key
  Future<OfflineVideoModel?> getvideo(int pk) async {
    final db = _getDatabaseOrThrow();
    // final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM OfflineCourse WHERE pk = ?', [pk]);
    final List<Map<String, dynamic>> maps = await db.query(
      offlineVideoTable,
      limit: 1,
      where: 'pk = ?',
      whereArgs: [pk],
    );
    if (maps.isNotEmpty) {
      return OfflineVideoModel.fromJson(maps.first);
    }
    throw CouldNotFindVideoException();
    // return null;
  }

  //todo: delete course
  Future<void> deleteCourse(int coursePk) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      offlineCourseTable,
      where: 'pk = ?',
      whereArgs: [coursePk],
    );
    // Since units and videos are deleted by cascading, no need to explicitly delete them here
    if (deletedCount == 0) {
      throw CouldNotDeleteCourseException();
    } else {
      //todo: remove the cousrse from the cashe
      _courses.removeWhere((element) => element.pk == coursePk);
    }

    //todo: update the UI
    update();
  }

  //todo: delete unit
  Future<void> deleteUnit(int unitPk) async {
    final db = _getDatabaseOrThrow();

    final deletedCount = await db.delete(
      offlineUnitTable,
      where: 'pk = ?',
      whereArgs: [unitPk],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUnitException();
    }

    //todo: update the UI
    update();
  }

  //todo: delete video
  Future<void> deleteVideo({required int videoPk}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      offlineVideoTable,
      where: 'pk = ?',
      whereArgs: [videoPk],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteVideoException();
    } else {}

    //todo: update the UI
    update();
  }

  //todo: Delete the video and cascationg the deleteion to the unit amd the course
  Future<void> removeVideo({required int videoId}) async {
    final db = _getDatabaseOrThrow();

    // Fetch the unit ID and course ID from the video before any deletion
    var videoDetails = await db.query(offlineVideoTable,
        columns: ['unitId'], where: 'pk = ?', whereArgs: [videoId]);
    if (videoDetails.isEmpty) return; // Video not found
    int unitId = videoDetails.first['unitId'] as int;

    // Delete the specified video
    await db.delete(offlineVideoTable, where: 'pk = ?', whereArgs: [videoId]);

    // Check if the unit is now empty
    var unitVideos = await db
        .query(offlineVideoTable, where: 'unitId = ?', whereArgs: [unitId]);
    if (unitVideos.isNotEmpty) return; // Unit still contains other videos

    // Fetch the course ID before deleting the unit
    var unitDetails = await db.query(offlineUnitTable,
        columns: ['courseId'], where: 'pk = ?', whereArgs: [unitId]);
    if (unitDetails.isEmpty) return; // No unit found
    int courseId = unitDetails.first['courseId'] as int;

    // Delete the empty unit
    await db.delete(offlineUnitTable, where: 'pk = ?', whereArgs: [unitId]);

    // Check if the course is now empty
    var courseUnits = await db
        .query(offlineUnitTable, where: 'courseId = ?', whereArgs: [courseId]);

    if (courseUnits.isNotEmpty) return; // Course still contains other units

    try {
      // Delete the empty course
      await db
          .delete(offlineCourseTable, where: 'pk = ?', whereArgs: [courseId]);
      // Remove the course from the in-memory cache
      _courses.removeWhere((course) => course.pk == courseId);
    } catch (e) {
      LOG_THE_DEBUG_DATA(messag: 'e => ${e}', type: 'e');
    }

    update();
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }

    try {
      //tODO: Get the ApplicationDocumentsDirectory
      final docsPath = await getApplicationDocumentsDirectory();
      //tODO: create the database path
      final dbPath = join(docsPath.path, dbName);
      //tODO: open the database
      final db = await openDatabase(dbPath);
      //tODO: assigne the database globally
      _db = db;
      //tODO: Create the tables if there are not exists
      //? Create the course table
      await db.execute(createCourseTable);
      //? Create the unit table
      await db.execute(createUnitTable);
      //? Create the table for the videos
      await db.execute(createVideoTable);
      //todo: get all courses
      await _cacheCourses();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    } catch (e) {}
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> deleteMyDatabase() async {
    final docsPath = await getApplicationDocumentsDirectory();
    //tODO: create the database path
    final dbPath = join(docsPath.path, dbName);
    await deleteDatabase(dbPath);
    _db = null;
    LOG_THE_DEBUG_DATA(messag: 'Database deleted');
  }
}

const dbName = 'offlineCourses.db';
const offlineCourseTable = 'OfflineCourse';
const offlineUnitTable = 'OfflineUnit';
const offlineVideoTable = 'OfflineVideo';

const createUnitTable = '''CREATE TABLE IF NOT EXISTS OfflineUnit (
    pk INTEGER PRIMARY KEY,
    id TEXT,
    title TEXT NOT NULL,
    isExternal BOOLEAN,
    courseId INTEGER,
    FOREIGN KEY (courseId) REFERENCES OfflineCourse(pk) ON DELETE CASCADE
);
 ''';

const createCourseTable = '''
        CREATE TABLE IF NOT EXISTS OfflineCourse (
            id TEXT,
            pk INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            totalHours TEXT,
            profile TEXT NOT NULL,
            cover TEXT NOT NULL,
            courseHours TEXT
        );''';

const createVideoTable = '''CREATE TABLE IF NOT EXISTS OfflineVideo (
    pk INTEGER PRIMARY KEY,
    id TEXT NOT NULL,
    title TEXT NOT NULL,
    videoUuid TEXT,
    storagePath TEXT NOT NULL,
    unitId INTEGER NOT NULL,
    FOREIGN KEY (unitId) REFERENCES OfflineUnit(pk) ON DELETE CASCADE
);
''';
// const createVideoTable = '''CREATE TABLE IF NOT EXISTS OfflineVideo (
//     pk INTEGER PRIMARY KEY,
//     id TEXT NOT NULL,
//     title TEXT NOT NULL,
//     storagePath TEXT NOT NULL,
//     downloadStatus TEXT NOT NULL,
//     unitId INTEGER NOT NULL,
//     FOREIGN KEY (unitId) REFERENCES OfflineUnit(pk) ON DELETE CASCADE
// );
// ''';
