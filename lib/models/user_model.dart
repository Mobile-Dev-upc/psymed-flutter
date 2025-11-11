// lib/models/user_model.dart

class SignUpRequest {
  final String username;
  final String password;
  final String role;

  SignUpRequest({
    required this.username,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'role': role,
    };
  }
}

class SignInRequest {
  final String username;
  final String password;

  SignInRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class AuthResponse {
  final int id;
  final String role;
  final String token;

  AuthResponse({
    required this.id,
    required this.role,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: json['id'],
      role: json['role'],
      token: json['token'],
    );
  }
}

class UserResponse {
  final int id;
  final String username;
  final String role;

  UserResponse({
    required this.id,
    required this.username,
    required this.role,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      username: json['username'],
      role: json['role'],
    );
  }
}

class PatientProfileRequest {
  final String firstName;
  final String lastName;
  final String street;
  final String city;
  final String country;
  final String email;
  final String username;
  final String password;
  final int professionalId;

  PatientProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.street,
    required this.city,
    required this.country,
    required this.email,
    required this.username,
    required this.password,
    required this.professionalId,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'street': street,
      'city': city,
      'country': country,
      'email': email,
      'username': username,
      'password': password,
      'professionalId': professionalId,
    };
  }
}

class PatientProfile {
  final int id;
  final String fullName;
  final String email;
  final String streetAddress;
  final int accountId;
  final int professionalId;

  PatientProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.streetAddress,
    required this.accountId,
    required this.professionalId,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      streetAddress: json['streetAddress'],
      accountId: json['accountId']['accountId'],
      professionalId: json['professionalId'],
    );
  }
}