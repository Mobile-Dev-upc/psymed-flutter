// lib/models/task_model.dart

class Task {
  final String id;
  final int idPatient;
  final int idSession;
  final String title;
  final String description;
  final int status; // 0 = pending, 1 = completed
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.idPatient,
    required this.idSession,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['taskId']?.toString() ?? json['id']?.toString() ?? '',
      idPatient: json['idPatient'] ?? 0,
      idSession: json['idSession'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': id,
      'idPatient': idPatient,
      'idSession': idSession,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    int? idPatient,
    int? idSession,
    String? title,
    String? description,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      idPatient: idPatient ?? this.idPatient,
      idSession: idSession ?? this.idSession,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

