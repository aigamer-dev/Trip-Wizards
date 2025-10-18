import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GenerationJobState { queued, running, succeeded, failed }

class GenerationJobSnapshot {
  const GenerationJobSnapshot({
    required this.id,
    required this.type,
    required this.state,
    required this.startedAt,
    required this.progress,
    required this.payload,
    this.message,
  });

  final String id;
  final String type;
  final GenerationJobState state;
  final DateTime startedAt;
  final double progress;
  final Map<String, dynamic> payload;
  final String? message;

  Map<String, dynamic> toSummaryMap() => {
    'id': id,
    'type': type,
    'status': state.name,
    'queuedAt': startedAt.toIso8601String(),
    'progress': progress,
    'payload': payload,
    if (message != null) 'message': message,
  };
}

class _GenerationJob {
  _GenerationJob({required this.id, required this.type, required this.payload})
    : startedAt = DateTime.now(),
      state = GenerationJobState.queued,
      progress = 0;

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime startedAt;
  GenerationJobState state;
  double progress;
  String? message;

  GenerationJobSnapshot snapshot() => GenerationJobSnapshot(
    id: id,
    type: type,
    state: state,
    startedAt: startedAt,
    progress: progress,
    payload: payload,
    message: message,
  );
}

/// Enforces generation limits by subscription tier and simulates generation.
class GenerationService {
  GenerationService._();
  static final GenerationService instance = GenerationService._();

  static const _keyLastDate = 'gen_last_date';
  static const _keyCount = 'gen_daily_count';

  final Map<String, _GenerationJob> _jobs = {};
  final ValueNotifier<List<GenerationJobSnapshot>> _activeJobsNotifier =
      ValueNotifier<List<GenerationJobSnapshot>>([]);

  ValueListenable<List<GenerationJobSnapshot>> get activeJobsListenable =>
      _activeJobsNotifier;

  List<GenerationJobSnapshot> get activeJobs =>
      List<GenerationJobSnapshot>.unmodifiable(_activeJobsNotifier.value);

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
    final job = _registerJob(type: 'trip_plan', payload: payload);

    try {
      _markJobRunning(job.id);

      // Simulated staged progress updates for richer UI feedback.
      await Future.delayed(const Duration(milliseconds: 500));
      _updateProgress(job.id, 0.35);
      await Future.delayed(const Duration(milliseconds: 700));
      _updateProgress(job.id, 0.7);
      await Future.delayed(const Duration(milliseconds: 800));
      _resolveJob(job.id, GenerationJobState.succeeded);

      if (kDebugMode) {
        // ignore: avoid_print
        print('Generated trip with payload: $payload');
      }
    } catch (e) {
      _resolveJob(job.id, GenerationJobState.failed, message: e.toString());
      rethrow;
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

  _GenerationJob _registerJob({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    final jobId =
        'gen_${DateTime.now().millisecondsSinceEpoch}_${_jobs.length + 1}';
    final job = _GenerationJob(id: jobId, type: type, payload: payload);
    _jobs[jobId] = job;
    _rebuildActiveJobs();
    return job;
  }

  void _markJobRunning(String id) {
    final job = _jobs[id];
    if (job == null) return;
    job.state = GenerationJobState.running;
    job.progress = job.progress > 0 ? job.progress : 0.1;
    _rebuildActiveJobs();
  }

  void _updateProgress(String id, double progress) {
    final job = _jobs[id];
    if (job == null || job.state != GenerationJobState.running) return;
    job.progress = progress.clamp(0, 1);
    _rebuildActiveJobs();
  }

  void _resolveJob(String id, GenerationJobState state, {String? message}) {
    final job = _jobs[id];
    if (job == null) return;
    job.state = state;
    job.message = message;
    if (state == GenerationJobState.succeeded) {
      job.progress = 1;
    }

    if (state == GenerationJobState.succeeded ||
        state == GenerationJobState.failed) {
      // Remove completed jobs from the active set after notifying listeners.
      final snapshot = job.snapshot();
      _jobs.remove(id);
      _rebuildActiveJobs(previousSnapshot: snapshot);
      return;
    }

    _rebuildActiveJobs();
  }

  void _rebuildActiveJobs({GenerationJobSnapshot? previousSnapshot}) {
    final active =
        _jobs.values
            .where(
              (job) =>
                  job.state == GenerationJobState.queued ||
                  job.state == GenerationJobState.running,
            )
            .map((job) => job.snapshot())
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    if (previousSnapshot != null &&
        (previousSnapshot.state == GenerationJobState.succeeded ||
            previousSnapshot.state == GenerationJobState.failed)) {
      // Briefly surface the completed job so UI can animate completion states.
      active.insert(0, previousSnapshot);
      Future.microtask(() => _rebuildActiveJobs());
    }

    _activeJobsNotifier.value = active;
  }
}
