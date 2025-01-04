import 'dart:async';
import 'dart:io';
import 'exceptions.dart';

class ErrorHandler {
  static String handleError(Exception error) {
    if (error is NetworkException) {
      return 'Network error: ${error.message}';
    }

    if (error is ValidationException) {
      return 'Validation error: ${error.message}';
    }

    if (error is UnauthorizedException) {
      return 'Authentication error: ${error.message}';
    }

    if (error is ForbiddenException) {
      return 'Access denied: ${error.message}';
    }

    if (error is NotFoundException) {
      return 'Not found: ${error.message}';
    }

    if (error is ConflictException) {
      return 'Conflict error: ${error.message}';
    }

    if (error is ServerException) {
      return 'Server error: ${error.message}';
    }

    if (error is SocketException) {
      return 'Network error: Could not connect to the server';
    }

    if (error is TimeoutException) {
      return 'Network error: Connection timed out';
    }

    if (error is RequestCancelledException) {
      return 'Request cancelled: ${error.message}';
    }

    return 'An unexpected error occurred';
  }

  static bool isNetworkError(Exception error) {
    return error is NetworkException ||
        error is SocketException ||
        error is TimeoutException;
  }

  static bool isAuthError(Exception error) {
    return error is UnauthorizedException || error is ForbiddenException;
  }

  static bool isValidationError(Exception error) {
    return error is ValidationException;
  }

  static bool isServerError(Exception error) {
    return error is ServerException;
  }

  static bool isNotFoundError(Exception error) {
    return error is NotFoundException;
  }

  static bool isConflictError(Exception error) {
    return error is ConflictException;
  }
}
