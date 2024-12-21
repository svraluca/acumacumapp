import 'package:acumacum/notifications_setup/logging/logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AppCloudFunctionService {
  final _logger = getLogger('AppCloudFunctions');
  late FirebaseFunctions _functions;

  // Make this a singleton class.

  AppCloudFunctionService._internal() {
    _functions = FirebaseFunctions.instance;
  }

  static final AppCloudFunctionService _instance = AppCloudFunctionService._internal();

  factory AppCloudFunctionService() {
    return _instance;
  }

  Future<bool> sendMessageToFirestore(Map<String, dynamic> messageData) async {
    try {
      final sanitizedMessageData = _sanitizeMessageData(messageData);
      // Call the Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('addChatMessage');
      final result = await callable.call(sanitizedMessageData);

      // Process the result if needed (the Cloud Function doesn't return anything useful currently)
      _logger.i('Message sent successfully to Firestore: ${result.data}');
      if (result.data['success'] == true) {
        return true;
      } else {
        _logger.e('Error sending message: ${result.data['error']}');
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      // Handle errors from the Cloud Function
      _logger.e('Error sending message: ${e.message}');
      _logger.e('Error details: ${e.details}');
      // Show a user-friendly error message or log the error
    } catch (e) {
      // Handle other errors
      _logger.e('Unexpected error: $e');
    }
    return false;
  }

  Map<String, dynamic> _sanitizeMessageData(Map<String, dynamic> messageData) {
    // Ensure all values in the map are JSON-serializable
    return messageData.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      } else if (value is List || value is Map || value is String || value is num || value is bool || value == null) {
        return MapEntry(key, value);
      } else {
        throw ArgumentError('Invalid value type for key "$key": ${value.runtimeType}');
      }
    });
  }
}
