import 'package:hive/hive.dart';

part 'theme_item.g.dart';

@HiveType(typeId: 0)
class ThemeItem extends HiveObject {
  @HiveField(0)
  String title = '';

  @HiveField(1)
  String fbLink = '';

  @HiveField(2)
  int numberOfParts = 1;

  ThemeItem({
    this.title = '',
    this.fbLink = '',
    this.numberOfParts = 1,
  });
}