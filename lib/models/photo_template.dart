import 'dart:convert';

class PhotoTemplate {
  final String id;
  final String name;
  final double width;
  final double height;
  final int photoCount;

  /// File background/template belakang.
  final String? backPath;

  /// File foreground/template depan.
  final String? frontPath;

  final List<TemplatePhotoPosition> photos;

  const PhotoTemplate({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.photoCount,
    required this.photos,
    this.backPath,
    this.frontPath,
  });

  factory PhotoTemplate.fromJson(
    Map<String, dynamic> json, {
    String? backPath,
    String? frontPath,
  }) {
    return PhotoTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      photoCount: json['photoCount'] as int,
      backPath: backPath,
      frontPath: frontPath,
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map(
            (item) => TemplatePhotoPosition.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'photoCount': photoCount,
      'photos': photos.map((e) => e.toJson()).toList(),
    };
  }

  String encode() {
    return jsonEncode(toJson());
  }
}

class TemplatePhotoPosition {
  final double x;
  final double y;
  final double width;
  final double height;

  /// Rotation dalam derajat.
  final double rotation;

  const TemplatePhotoPosition({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  factory TemplatePhotoPosition.fromJson(
    Map<String, dynamic> json,
  ) {
    return TemplatePhotoPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
    };
  }
}