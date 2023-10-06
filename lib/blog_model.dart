import 'package:hive/hive.dart';

part 'blog_model.g.dart'; 

@HiveType(typeId: 0)
class BlogModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String imageUrl;

  BlogModel({
    required this.title,
    required this.imageUrl,
  });
}