import 'package:hive/hive.dart';

part 'publications.g.dart';

@HiveType(typeId: 1)
class Publication extends HiveObject {
  @HiveField(0)
  String title = '';

  @HiveField(1)
  String fbLink = '';

  @HiveField(2)
  DateTime datePublished = DateTime.now();

  @HiveField(3)
  String slotTime = ''; // ex: "06:00"

  Publication({
    this.title = '',
    this.fbLink = '',
    DateTime? datePublished,
    this.slotTime = '',
  }) : datePublished = datePublished ?? DateTime.now();
}