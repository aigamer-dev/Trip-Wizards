import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized error handling service for the Travel Wizards app.
///
/// Provides consistent error handling, logging, and user-friendly error messages
/// throughout the application.
class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  static ErrorHandlingService get instance => _instance;
  ErrorHandlingService._internal();

  /// Error reporting callback for external services (e.g., Crashlytics)
  Function(Object error, StackTrace? stackTrace)? _errorReporter;

  /// Initialize the error handling service
  void init({Function(Object error, StackTrace? stackTrace)? errorReporter}) {
    _errorReporter = errorReporter;
  }

  /// Handle an error with optional context and user feedback
  void handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = false,
    BuildContext? userContext,
    String? userMessage,
  }) {
    // Log the error
    _logError(error, stackTrace: stackTrace, context: context);

    // Report to external services if configured
    _errorReporter?.call(error, stackTrace);

    // Show user-friendly message if requested
    if (showToUser && userContext != null && userContext.mounted) {
      _showUserError(
        userContext,
        userMessage ?? _getUserFriendlyMessage(error),
      );
    }
  }

  /// Handle async operations with proper error handling
  Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    BuildContext? userContext,
    String? userErrorMessage,
    bool showUserError = true,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        showToUser: showUserError,
        userContext: userContext,
        userMessage: userErrorMessage,
      );
      return fallbackValue;
    }
  }

  /// Handle sync operations with proper error handling
  T? handleSync<T>(
    T Function() operation, {
    String? context,
    BuildContext? userContext,
    String? userErrorMessage,
    bool showUserError = true,
    T? fallbackValue,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace: stackTrace,
        context: context,
        showToUser: showUserError,
        userContext: userContext,
        userMessage: userErrorMessage,
      );
      return fallbackValue;
    }
  }

  /// Log error with appropriate level based on environment
  void _logError(Object error, {StackTrace? stackTrace, String? context}) {
    final message = context != null ? '[$context] $error' : error.toString();

    if (kDebugMode) {
      // In debug mode, use developer.log for better debugging
      developer.log(
        message,
        name: 'TravelWizards.Error',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // In release mode, use print for basic logging
      // In production, this should be replaced with proper logging service
      debugPrint('ERROR: $message');
      if (stackTrace != null) {
        debugPrint('STACK TRACE: $stackTrace');
      }
    }
  }

  /// Show user-friendly error message
  void _showUserError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Convert technical errors to user-friendly messages (public method)
  String getUserFriendlyMessage(Object error) {
    return _getUserFriendlyMessage(error);
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    // Firebase errors
    if (errorStr.contains('firebase') || errorStr.contains('auth')) {
      return 'Authentication error. Please try logging in again.';
    }

    // Payment errors
    if (errorStr.contains('payment') || errorStr.contains('stripe')) {
      return 'Payment processing failed. Please try again or use a different payment method.';
    }

    // Permission errors
    if (errorStr.contains('permission')) {
      return 'This feature requires additional permissions. Please check your device settings.';
    }

    // Storage errors
    if (errorStr.contains('storage') || errorStr.contains('file')) {
      return 'Storage error. Please check available space and try again.';
    }

    // Format errors
    if (errorStr.contains('format') || errorStr.contains('parse')) {
      return 'Data format error. Please try refreshing the app.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again later.';
  }

  /// Handle specific error types with custom logic
  void handleNetworkError(
    Object error, {
    BuildContext? context,
    String? customMessage,
  }) {
    handleError(
      error,
      context: 'Network Operation',
      showToUser: context != null,
      userContext: context,
      userMessage:
          customMessage ??
          'Please check your internet connection and try again.',
    );
  }

  void handleAuthError(
    Object error, {
    BuildContext? context,
    String? customMessage,
  }) {
    handleError(
      error,
      context: 'Authentication',
      showToUser: context != null,
      userContext: context,
      userMessage:
          customMessage ??
          'Authentication failed. Please try logging in again.',
    );
  }

  void handlePaymentError(
    Object error, {
    BuildContext? context,
    String? customMessage,
  }) {
    handleError(
      error,
      context: 'Payment Processing',
      showToUser: context != null,
      userContext: context,
      userMessage:
          customMessage ??
          'Payment failed. Please try again or use a different payment method.',
    );
  }

  void handleDataError(
    Object error, {
    BuildContext? context,
    String? customMessage,
  }) {
    handleError(
      error,
      context: 'Data Operation',
      showToUser: context != null,
      userContext: context,
      userMessage:
          customMessage ?? 'Data processing failed. Please try refreshing.',
    );
  }
}

/// Convenience extensions for easier error handling
extension AsyncErrorHandling<T> on Future<T> {
  /// Handle errors in async operations with context
  Future<T?> handleErrors({
    String? context,
    BuildContext? userContext,
    String? userErrorMessage,
    bool showUserError = true,
    T? fallbackValue,
  }) {
    return ErrorHandlingService.instance.handleAsync(
      () => this,
      context: context,
      userContext: userContext,
      userErrorMessage: userErrorMessage,
      showUserError: showUserError,
      fallbackValue: fallbackValue,
    );
  }
}

/// Error types for better categorization
enum AppErrorType {
  network,
  authentication,
  payment,
  storage,
  permission,
  data,
  unknown,
}

/// Custom application errors with additional context
class AppError implements Exception {
  final String message;
  final AppErrorType type;
  final Object? originalError;
  final String? context;

  const AppError(
    this.message, {
    this.type = AppErrorType.unknown,
    this.originalError,
    this.context,
  });

  @override
  String toString() {
    return context != null ? '[$context] $message' : message;
  }

  /// Create network error
  factory AppError.network(
    String message, {
    Object? originalError,
    String? context,
  }) {
    return AppError(
      message,
      type: AppErrorType.network,
      originalError: originalError,
      context: context,
    );
  }

  /// Create authentication error
  factory AppError.auth(
    String message, {
    Object? originalError,
    String? context,
  }) {
    return AppError(
      message,
      type: AppErrorType.authentication,
      originalError: originalError,
      context: context,
    );
  }

  /// Create payment error
  factory AppError.payment(
    String message, {
    Object? originalError,
    String? context,
  }) {
    return AppError(
      message,
      type: AppErrorType.payment,
      originalError: originalError,
      context: context,
    );
  }

  /// Create data error
  factory AppError.data(
    String message, {
    Object? originalError,
    String? context,
  }) {
    return AppError(
      message,
      type: AppErrorType.data,
      originalError: originalError,
      context: context,
    );
  }
}
