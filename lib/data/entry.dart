/// One day's photo record (row of the `entries` table).
class Entry {
  /// Creates an immutable entry.
  const Entry({
    required this.dateKey,
    required this.fileName,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  /// Reads a row produced by [toMap].
  factory Entry.fromMap(Map<String, Object?> map) => Entry(
    dateKey: map['date_key']! as String,
    fileName: map['file_name']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    note: map['note'] as String?,
  );

  /// Longest note a day can hold (ISKELET F11).
  static const maxNoteLength = 500;

  /// Local day key `YYYY-MM-DD`; primary key.
  final String dateKey;

  /// File name inside `photos/`; never an absolute path (ISKELET F6b).
  final String fileName;

  /// When the day first got a photo.
  final DateTime createdAt;

  /// When the photo or note last changed.
  final DateTime updatedAt;

  /// The user's note for the day, `null` when there is none (ISKELET F11).
  final String? note;

  /// Whether the day has a non-empty note.
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Row representation for sqflite.
  Map<String, Object?> toMap() => {
    'date_key': dateKey,
    'file_name': fileName,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
    'note': note,
  };

  /// Copy with the given fields replaced; the note is kept.
  Entry copyWith({
    String? dateKey,
    String? fileName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Entry(
    dateKey: dateKey ?? this.dateKey,
    fileName: fileName ?? this.fileName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    note: note,
  );

  /// Copy with [note] replaced; `null` removes it.
  Entry withNote(String? note, {DateTime? updatedAt}) => Entry(
    dateKey: dateKey,
    fileName: fileName,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    note: note,
  );

  @override
  bool operator ==(Object other) =>
      other is Entry &&
      other.dateKey == dateKey &&
      other.fileName == fileName &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(dateKey, fileName, createdAt, updatedAt, note);

  @override
  String toString() => 'Entry($dateKey, $fileName)';
}
