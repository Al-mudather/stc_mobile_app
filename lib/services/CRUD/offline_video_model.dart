import 'package:stc_training/services/CRUD/offline_unit_model.dart';

class OfflineVideoModel {
  int pk;
  String id;
  String title;
  String? videoUuid;
  String storagePath;
  int unitId;

  OfflineVideoModel({
    required this.pk,
    required this.id,
    required this.title,
    this.videoUuid,
    required this.storagePath,
    required this.unitId,
  });

  OfflineVideoModel.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as String,
        pk = map[pkColumn] as int,
        title = map[titleColumn] as String,
        videoUuid = map[videoUuidColumn] as String?,
        storagePath = map[storagePathColumn] as String,
        unitId = map[unitIdColumn] as int;

  factory OfflineVideoModel.fromJson(Map<String, dynamic> json) {
    return OfflineVideoModel(
      pk: json['pk'],
      id: json['id'],
      title: json['title'],
      videoUuid: json['videoUuid'],
      storagePath: json['storagePath'],
      // downloadStatus: json['downloadStatus'],
      unitId: json['unitId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pk': pk,
      'id': id,
      'title': title,
      'videoUuid': videoUuid,
      'storagePath': storagePath,
      'unitId': unitId,
      // 'downloadStatus':
      //     downloadStatus.toString().split('.').last // Convert enum to string
    };
  }

  @override
  String toString() => 'Video title = $title,  pk =$pk';

  @override
  bool operator ==(covariant OfflineVideoModel other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const idColumn = 'id';
const pkColumn = 'pk';
const titleColumn = 'title';
const videoUuidColumn = 'videoUuid';
const storagePathColumn = 'storagePath';
