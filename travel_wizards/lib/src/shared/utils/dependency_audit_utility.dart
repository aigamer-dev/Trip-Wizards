import 'package:flutter/foundation.dart';
import '../services/dependency_management_service.dart';

/// Utility class for running dependency audits and handling results
class DependencyAuditUtility {
  static final DependencyManagementService _dependencyService =
      DependencyManagementService.instance;

  /// Run a comprehensive dependency audit and print results
  static Future<void> runDependencyAudit({bool printVerbose = false}) async {
    try {
      debugPrint('🔍 Starting dependency audit...');

      // Check if running on web platform
      if (kIsWeb) {
        debugPrint('⚠️  Dependency audit is not available on web platform');
        debugPrint(
          '   File system operations are not supported in web browsers',
        );
        debugPrint('   Please run the audit on mobile or desktop platforms');
        debugPrint('');
        debugPrint('🌐 Showing web-specific information instead...');
        return;
      }

      // Initialize the service
      await _dependencyService.initialize();

      // Run the audit
      final report = await _dependencyService.auditDependencies(
        checkSecurity: true,
        checkConflicts: true,
        checkUnused: false, // Disabled for performance
      );

      // Print summary
      final summary = report.getSummary();
      debugPrint('\n📊 Dependency Audit Summary:');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Total Dependencies: ${summary['total_dependencies']}');
      debugPrint(
        'Total Dev Dependencies: ${summary['total_dev_dependencies']}',
      );
      debugPrint('Outdated Dependencies: ${summary['outdated_dependencies']}');
      debugPrint('Security Issues: ${summary['security_issues']}');
      debugPrint('Discontinued Packages: ${summary['discontinued_packages']}');
      debugPrint(
        'High Priority Recommendations: ${summary['high_priority_recommendations']}',
      );

      // Calculate health score
      final healthScore = _dependencyService.calculateHealthScore(report);
      debugPrint('\n💊 Dependency Health Score: $healthScore/100');

      String healthStatus;
      if (healthScore >= 90) {
        healthStatus = '🟢 Excellent';
      } else if (healthScore >= 75) {
        healthStatus = '🟡 Good';
      } else if (healthScore >= 50) {
        healthStatus = '🟠 Needs Attention';
      } else {
        healthStatus = '🔴 Critical Issues';
      }
      debugPrint('Health Status: $healthStatus');

      // Print high priority issues
      if (summary['security_issues'] > 0 ||
          summary['discontinued_packages'] > 0) {
        debugPrint('\n⚠️  Critical Issues Found:');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        for (final dep in report.dependencies) {
          if (dep.hasSecurityIssues) {
            debugPrint(
              '🔒 SECURITY: ${dep.name} v${dep.currentVersion} has security vulnerabilities',
            );
          }
          if (dep.isDiscontinued) {
            debugPrint('🚫 DISCONTINUED: ${dep.name} is no longer maintained');
          }
        }
      }

      // Print outdated dependencies
      if (summary['outdated_dependencies'] > 0) {
        debugPrint('\n📦 Outdated Dependencies:');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        for (final dep in report.dependencies.where((d) => d.isOutdated)) {
          debugPrint(
            '📊 ${dep.name}: ${dep.currentVersion} → ${dep.latestVersion ?? 'unknown'}',
          );
        }
      }

      // Print optimization recommendations
      if (report.optimizationRecommendations.isNotEmpty) {
        debugPrint('\n💡 Optimization Recommendations:');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        for (final rec in report.optimizationRecommendations) {
          final priorityIcon = _getPriorityIcon(rec.priority);
          debugPrint('$priorityIcon ${rec.title}');
          debugPrint('   ${rec.description}');
          debugPrint('   Action: ${rec.action}');
          debugPrint('');
        }
      }

      // Print verbose details if requested
      if (printVerbose) {
        debugPrint('\n📋 Detailed Dependency List:');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        for (final dep in report.dependencies) {
          debugPrint('\n📦 ${dep.name} v${dep.currentVersion}');
          if (dep.description != null) {
            debugPrint('   ${dep.description}');
          }
          if (dep.latestVersion != null) {
            debugPrint('   Latest: ${dep.latestVersion}');
          }
          if (dep.popularity != null) {
            debugPrint('   Popularity: ${(dep.popularity! * 100).toInt()}%');
          }
          if (dep.pubPoints != null) {
            debugPrint('   Pub Points: ${dep.pubPoints}/160');
          }
          if (dep.auditError != null) {
            debugPrint('   ⚠️ Audit Error: ${dep.auditError}');
          }
        }
      }

      debugPrint('\n✅ Dependency audit completed successfully!');
    } catch (e) {
      debugPrint('❌ Error during dependency audit: $e');
    }
  }

  /// Get priority icon for recommendations
  static String _getPriorityIcon(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.critical:
        return '🚨';
      case RecommendationPriority.high:
        return '⚠️ ';
      case RecommendationPriority.medium:
        return '🔔';
      case RecommendationPriority.low:
        return 'ℹ️ ';
    }
  }
}
