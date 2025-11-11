// lib/models/mood_state_model.dart

class MoodState {
  final int id;
  final int? idPatient;
  final int mood; // 1=So Sad, 2=Sad, 3=Neutral, 4=Happy, 5=So Happy
  final DateTime? date;

  MoodState({
    required this.id,
    this.idPatient,
    required this.mood,
    this.date,
  });

  factory MoodState.fromJson(Map<String, dynamic> json) {
    // Backend returns status (0-4), convert to Flutter mood (1-5)
    int backendStatus = json['status'] ?? 2; // default to NORMAL (2)
    int flutterMood = backendStatus + 1; // Convert 0-4 to 1-5
    
    return MoodState(
      id: json['id'] ?? 0,
      idPatient: json['idPatient'],
      mood: flutterMood,
      date: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : (json['date'] != null ? DateTime.parse(json['date'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idPatient': idPatient,
      'mood': mood,
      'date': date?.toIso8601String(),
    };
  }

  String getMoodLabel() {
    switch (mood) {
      case 1:
        return 'So Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'So Happy';
      default:
        return 'Neutral';
    }
  }

  String getMoodEmoji() {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }
}

class MoodAnalytic {
  final String idPatient;
  final String year;
  final String month;
  final int sadMood;
  final int happyMood;
  final int neutralMood;
  final int soSadMood;
  final int soHappyMood;

  MoodAnalytic({
    required this.idPatient,
    required this.year,
    required this.month,
    required this.sadMood,
    required this.happyMood,
    required this.neutralMood,
    required this.soSadMood,
    required this.soHappyMood,
  });

  factory MoodAnalytic.fromJson(Map<String, dynamic> json) {
    return MoodAnalytic(
      idPatient: json['idPatient']?.toString() ?? '0',
      year: json['year']?.toString() ?? '0',
      month: json['month']?.toString() ?? '0',
      sadMood: int.tryParse(json['sadMood']?.toString() ?? '0') ?? 0,
      happyMood: int.tryParse(json['happyMood']?.toString() ?? '0') ?? 0,
      neutralMood: int.tryParse(json['neutralMood']?.toString() ?? '0') ?? 0,
      soSadMood: int.tryParse(json['soSadMood']?.toString() ?? '0') ?? 0,
      soHappyMood: int.tryParse(json['soHappyMood']?.toString() ?? '0') ?? 0,
    );
  }

  int get totalMoods => sadMood + happyMood + neutralMood + soSadMood + soHappyMood;
}

