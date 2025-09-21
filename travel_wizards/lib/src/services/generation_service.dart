import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enforces generation limits by subscription tier and simulates generation.
class GenerationService {
  GenerationService._();
  static final GenerationService instance = GenerationService._();

  static const _keyLastDate = 'gen_last_date';
  static const _keyCount = 'gen_daily_count';

  /// Returns the current usage count for today.
  Future<int> getTodayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastDate);
    final today = _todayString();
    if (lastDate != today) return 0;
    return prefs.getInt(_keyCount) ?? 0;
  }

  /// Checks whether a generation is allowed for the given tier and increments usage if allowed.
  /// Returns remaining quota after increment on success, or throws StateError on limit exceeded.
  Future<int> checkAndConsume({required String tier}) async {
    final limit = _limitForTier(tier);
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_keyLastDate);
    int count = (lastDate == today) ? (prefs.getInt(_keyCount) ?? 0) : 0;
    if (count >= limit) {
      throw StateError('Daily limit reached for tier: $tier');
    }
    count += 1;
    await prefs.setString(_keyLastDate, today);
    await prefs.setInt(_keyCount, count);
    return limit - count;
  }

  /// Simulates a generation call; in future, call backend/MCP here.
  Future<void> generateTripPlan({required Map<String, dynamic> payload}) async {
    // Simulate a short delay for generation.
    await Future.delayed(const Duration(seconds: 2));
    if (kDebugMode) {
      // ignore: avoid_print
      print('Generated trip with payload: $payload');
    }
  }

  static int _limitForTier(String tier) {
    switch (tier) {
      case 'enterprise':
        return 10;
      case 'pro':
        return 5;
      case 'free':
      default:
        return 1;
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
