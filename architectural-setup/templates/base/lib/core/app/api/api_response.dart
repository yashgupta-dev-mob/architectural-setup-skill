// GENERIC: the source app's api_response.dart without its analyzer warning.
import 'dart:convert';
import 'dart:developer';

import 'package:equatable/equatable.dart';

abstract class APIResponse extends Equatable {
  final dynamic data;
  final String code;
  final String message;

  const APIResponse({this.data, this.code = '', this.message = ''});

  @override
  List<Object?> get props => [data, code, message];
}

class SuccessResponse extends APIResponse {
  final String successMessage;
  final String statusCode;
  final dynamic rawData;
  const SuccessResponse({
    required this.successMessage,
    required this.statusCode,
    required this.rawData,
    required super.data,
  }) : super(code: statusCode, message: successMessage);

  SuccessResponse copyWith({
    String? successMessage,
    String? statusCode,
    dynamic rawData,
    dynamic data,
  }) {
    return SuccessResponse(
      successMessage: successMessage ?? this.successMessage,
      statusCode: statusCode ?? this.statusCode,
      data: data ?? this.data,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'statusMessage': successMessage,
      'statusCode': statusCode,
      'data': data,
    };
  }

  factory SuccessResponse.fromMap(Map<String, dynamic> map) {
    log("$map");
    return SuccessResponse(
      successMessage: map['statusMessage'] as String,
      statusCode: map['statusCode'] as String,
      data: map['data'] as dynamic,
      rawData: map["rawData"] as dynamic,
    );
  }

  String toJson() => json.encode(toMap());

  factory SuccessResponse.fromJson(String source) =>
      SuccessResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [successMessage, statusCode, data];
}

class ErrorResponse extends APIResponse {
  final String errorMessage;
  final String errorCode;
  final dynamic rawData;
  const ErrorResponse({
    required this.errorMessage,
    required this.errorCode,
    this.rawData,
    required super.data,
  }) : super(code: errorCode, message: errorMessage);

  ErrorResponse copyWith({
    String? errorMessage,
    String? errorCode,
    dynamic data,
    dynamic rawData,
  }) {
    return ErrorResponse(
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      data: data ?? this.data,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'statusMessage': errorMessage,
      'statusCode': errorCode,
      'data': data,
    };
  }

  factory ErrorResponse.fromMap(Map<String, dynamic> map) {
    // these can be changed according to the structure of API'S
    return ErrorResponse(
      errorMessage: map['statusMessage'] as String,
      errorCode: map['statusCode'] as String,
      data: map['data'] as dynamic,
    );
  }

  String toJson() => json.encode(toMap());

  factory ErrorResponse.fromJson(String source) =>
      ErrorResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ErrorResponse(errorMessage: $errorMessage, data: $data)';

  @override
  List<Object> get props => [errorMessage, errorCode, data];
}

class InvalidResponse extends APIResponse {
  const InvalidResponse()
    : super(code: 'INVALID_RESPONSE', message: 'Invalid API response');
}
