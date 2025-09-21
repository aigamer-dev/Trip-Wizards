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

  /// Get update recommendations and print them
  static Future<void> getUpdateRecommendations() async {
    try {
      debugPrint('🔄 Generating update recommendations...');

      final recommendations = await _dependencyService
          .getUpdateRecommendations();

      if (recommendations.isEmpty) {
        debugPrint('✅ All dependencies are up to date!');
        return;
      }

      debugPrint('\n📈 Update Recommendations:');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Group by update type
      final majorUpdates = recommendations
          .where((r) => r.updateType == UpdateType.major)
          .toList();
      final minorUpdates = recommendations
          .where((r) => r.updateType == UpdateType.minor)
          .toList();
      final patchUpdates = recommendations
          .where((r) => r.updateType == UpdateType.patch)
          .toList();

      if (patchUpdates.isNotEmpty) {
        debugPrint('\n🟢 Safe Patch Updates (recommended):');
        for (final rec in patchUpdates) {
          debugPrint(
            '   ${rec.packageName}: ${rec.currentVersion} → ${rec.recommendedVersion}',
          );
          debugPrint('   ${rec.description}');
        }
      }

      if (minorUpdates.isNotEmpty) {
        debugPrint('\n🟡 Minor Updates (test recommended):');
        for (final rec in minorUpdates) {
          debugPrint(
            '   ${rec.packageName}: ${rec.currentVersion} → ${rec.recommendedVersion}',
          );
          debugPrint('   ${rec.description}');
        }
      }

      if (majorUpdates.isNotEmpty) {
        debugPrint('\n🔴 Major Updates (caution - breaking changes possible):');
        for (final rec in majorUpdates) {
          debugPrint(
            '   ${rec.packageName}: ${rec.currentVersion} → ${rec.recommendedVersion}',
          );
          debugPrint('   ${rec.description}');
        }
      }

      debugPrint('\n💡 Update Commands:');
      debugPrint(
        '   flutter pub upgrade              # Update all to latest compatible',
      );
      debugPrint(
        '   flutter pub upgrade --major-versions  # Update including major versions',
      );
      debugPrint(
        '   flutter pub upgrade <package>    # Update specific package',
      );
    } catch (e) {
      debugPrint('❌ Error generating update recommendations: $e');
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

  /// Check specific security vulnerabilities
  static Future<void> checkSecurityVulnerabilities() async {
    try {
      debugPrint('🔒 Checking for security vulnerabilities...');

      final report = await _dependencyService.auditDependencies(
        checkSecurity: true,
        checkConflicts: false,
        checkUnused: false,
      );

      final vulnerableDeps = report.dependencies
          .where((dep) => dep.hasSecurityIssues)
          .toList();

      if (vulnerableDeps.isEmpty) {
        debugPrint('✅ No known security vulnerabilities found!');
        return;
      }

      debugPrint('\n🚨 Security Vulnerabilities Found:');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      for (final dep in vulnerableDeps) {
        debugPrint('\n🔒 ${dep.name} v${dep.currentVersion}');

        for (final vuln in dep.securityVulnerabilities) {
          final severityIcon = _getSeverityIcon(vuln.severity);
          debugPrint('   $severityIcon ${vuln.title}');
          debugPrint('   ${vuln.description}');
          debugPrint('   Affected: ${vuln.affectedVersions}');
          if (vuln.fixedVersion != null) {
            debugPrint('   Fixed in: ${vuln.fixedVersion}');
          }
          if (vuln.cveId != null) {
            debugPrint('   CVE: ${vuln.cveId}');
          }
        }
      }

      debugPrint('\n⚡ Immediate Actions Required:');
      debugPrint('1. Update vulnerable packages immediately');
      debugPrint('2. Review and test your application');
      debugPrint('3. Consider alternative packages if updates not available');
    } catch (e) {
      debugPrint('❌ Error checking security vulnerabilities: $e');
    }
  }

  /// Get severity icon for vulnerabilities
  static String _getSeverityIcon(VulnerabilitySeverity severity) {
    switch (severity) {
      case VulnerabilitySeverity.critical:
        return '🚨';
      case VulnerabilitySeverity.high:
        return '🔴';
      case VulnerabilitySeverity.medium:
        return '🟠';
      case VulnerabilitySeverity.low:
        return '🟡';
    }
  }

  /// Print usage instructions
  static void printUsageInstructions() {
    debugPrint('\n📚 Dependency Management Usage:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('1. Add to your app initialization:');
    debugPrint('   await DependencyAuditUtility.runDependencyAudit();');
    debugPrint('');
    debugPrint('2. For detailed output:');
    debugPrint(
      '   await DependencyAuditUtility.runDependencyAudit(printVerbose: true);',
    );
    debugPrint('');
    debugPrint('3. Check for updates:');
    debugPrint('   await DependencyAuditUtility.getUpdateRecommendations();');
    debugPrint('');
    debugPrint('4. Security scan only:');
    debugPrint(
      '   await DependencyAuditUtility.checkSecurityVulnerabilities();',
    );
    debugPrint('');
    debugPrint('💡 Tips:');
    debugPrint('- Run audit during development to catch issues early');
    debugPrint('- Check security vulnerabilities before production releases');
    debugPrint('- Update dependencies regularly but test thoroughly');
    debugPrint('- Monitor for discontinued packages');
  }
}
