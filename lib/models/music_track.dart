class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String sourceUrl; // URL for remote, path for local
  final bool isLocal;
  final bool isRadio;
  String? localPath; // Path if downloaded or imported

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceUrl,
    this.isLocal = false,
    this.isRadio = false,
    this.localPath,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      sourceUrl: json['sourceUrl'] as String,
      isLocal: json['isLocal'] as bool? ?? false,
      isRadio: json['isRadio'] as bool? ?? false,
      localPath: json['localPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'sourceUrl': sourceUrl,
      'isLocal': isLocal,
      'isRadio': isRadio,
      'localPath': localPath,
    };
  }
  
  MusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? sourceUrl,
    bool? isLocal,
    bool? isRadio,
    String? localPath,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isLocal: isLocal ?? this.isLocal,
      isRadio: isRadio ?? this.isRadio,
      localPath: localPath ?? this.localPath,
    );
  }
}
