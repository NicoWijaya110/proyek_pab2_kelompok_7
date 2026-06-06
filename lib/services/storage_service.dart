import 'dart:convert';
import 'dart:typed_data';

class StorageService {
  Future<String> uploadReviewImage({required Uint8List bytes, required String userId}) async {
    try {
      print('STORAGE: converting review image to base64 (${bytes.lengthInBytes} bytes)');
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';
      print('STORAGE: conversion finished, length=${dataUri.length}');
      return dataUri;
    } catch (e) {
      print('STORAGE: conversion error: $e');
      rethrow;
    }
  }

  Future<String> uploadProfilePhoto({required Uint8List bytes, required String userId}) async {
    try {
      print('STORAGE: converting avatar image to base64 (${bytes.lengthInBytes} bytes)');
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';
      print('STORAGE: conversion finished, length=${dataUri.length}');
      return dataUri;
    } catch (e) {
      print('STORAGE: conversion error: $e');
      rethrow;
    }
  }
}