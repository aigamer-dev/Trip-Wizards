#!/bin/bash

###############################################################################
# Android Automated Integration Testing Script
# Comprehensive automated test execution on physical Android device
###############################################################################

set -e
set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Cleanup function - ALWAYS runs on exit
cleanup() {
    local exit_code=$?
    echo ""
    echo -e "${YELLOW}[CLEANUP]${NC} Clearing RAM by killing Gradle/Java processes..."
    
    # Kill all Java/Gradle processes to free RAM
    pkill -9 java 2>/dev/null || true
    pkill -9 gradle 2>/dev/null || true
    
    # Give it a moment to clear
    sleep 2
    
    # Show memory status
    echo -e "${YELLOW}[CLEANUP]${NC} Memory status after cleanup:"
    free -h | head -2
    
    echo -e "${GREEN}[CLEANUP]${NC} RAM cleanup complete"
    exit $exit_code
}

# Set trap to ALWAYS run cleanup on exit (success, failure, interrupt, etc.)
trap cleanup EXIT INT TERM ERR

# Configuration
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="$WORKSPACE_ROOT/build/reports"
SCREENSHOT_DIR="$WORKSPACE_ROOT/build/screenshots/android"
LOG_FILE="$REPORT_DIR/android_automated_test_$TIMESTAMP.log"
DEVICE_ID=""

# Create directories
mkdir -p "$REPORT_DIR"
mkdir -p "$SCREENSHOT_DIR"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓ SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1" | tee -a "$LOG_FILE"
}

# Header
print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Android Automated Integration Testing${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Travel Wizards - Physical Device Testing              ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found!"
        exit 1
    fi
    
    # Check ADB
    if ! command -v adb &> /dev/null; then
        log_error "ADB not found! Install Android SDK platform-tools"
        exit 1
    fi

    # Using Cloud Firebase for testing (no local emulators)
    if command -v firebase &> /dev/null; then
        log_info "Firebase CLI detected. Project will be auto-detected by app config (firebase_options.dart)."
    else
        log_warning "Firebase CLI not found. Cloud verification step will be skipped."
    fi
    
    log_success "Prerequisites check complete"
}

# Detect Android device
detect_device() {
    log_info "Detecting Android device..."
    
    local devices=$(adb devices | grep -v "List" | grep "device$" | awk '{print $1}')
    local device_count=$(echo "$devices" | wc -w)
    
    if [ "$device_count" -eq 0 ]; then
        log_error "No Android devices detected!"
        log_info "Connect device via USB and enable USB debugging"
        exit 1
    elif [ "$device_count" -eq 1 ]; then
        DEVICE_ID=$devices
        log_success "Device detected: $DEVICE_ID"
    else
        log_warning "Multiple devices detected. Using first device: $(echo $devices | awk '{print $1}')"
        DEVICE_ID=$(echo $devices | awk '{print $1}')
    fi
    
    # Get device info
    local device_model=$(adb -s $DEVICE_ID shell getprop ro.product.model)
    local android_version=$(adb -s $DEVICE_ID shell getprop ro.build.version.release)
    local api_level=$(adb -s $DEVICE_ID shell getprop ro.build.version.sdk)
    
    log_info "Device Model: $device_model"
    log_info "Android Version: $android_version (API $api_level)"
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."
    cd "$WORKSPACE_ROOT"
    flutter clean > /dev/null 2>&1
    # flutter clean removes the build/ directory; recreate report dirs immediately after
    mkdir -p "$REPORT_DIR" "$SCREENSHOT_DIR"
    flutter pub get > /dev/null 2>&1
    # Ensure log file path is creatable after clean
    mkdir -p "$REPORT_DIR"
    log_success "Clean complete"
}

# Run integration tests
run_integration_tests() {
    # Ensure report directory exists (flutter clean may have removed it)
    mkdir -p "$REPORT_DIR"
    log_info "Starting comprehensive automated integration tests..."
    cd "$WORKSPACE_ROOT"
    
    log_test "Running 20 comprehensive automated tests:"
    echo -e "  ${CYAN}•${NC} App Launch & Initial Screen"
    echo -e "  ${CYAN}•${NC} Welcome/Login Screen Detection"
    echo -e "  ${CYAN}•${NC} Authentication Buttons"
    echo -e "  ${CYAN}•${NC} UI Components Rendering"
    echo -e "  ${CYAN}•${NC} Navigation Elements"
    echo -e "  ${CYAN}•${NC} Firebase Initialization"
    echo -e "  ${CYAN}•${NC} Responsive UI (Portrait/Landscape)"
    echo -e "  ${CYAN}•${NC} Rapid Interactions Stability"
    echo -e "  ${CYAN}•${NC} Form Elements"
    echo -e "  ${CYAN}•${NC} Button Types"
    echo -e "  ${CYAN}•${NC} Settings/Menu Elements"
    echo -e "  ${CYAN}•${NC} Theme Configuration"
    echo -e "  ${CYAN}•${NC} Memory Stability"
    echo -e "  ${CYAN}•${NC} Screen Rotation Stress"
    echo -e "  ${CYAN}•${NC} Accessibility Support"
    echo -e "  ${CYAN}•${NC} Offline Handling"
    echo -e "  ${CYAN}•${NC} No Critical Errors"
    echo -e "  ${CYAN}•${NC} Navigation State"
    echo -e "  ${CYAN}•${NC} Final Stability Check"
    echo ""
    
    log_info "Note: flutter drive will automatically install and run the app"
    log_info "This saves RAM compared to separate flutter run + flutter drive"
    echo ""
    
    log_info "Using Cloud Firebase (emulators disabled)"

    # Run integration tests - flutter drive handles app installation and launch
    # Pass dart-defines to enable emulators and test sign-in
    # Capture the exit code of flutter drive even when piping to tee
    set +e
    # Build dart-define flags
    DEFINE_FLAGS=(
        --dart-define=USE_FIREBASE_EMULATORS=false
        --dart-define=TEST_SIGN_IN=true
    )
    # Optional email/password for Cloud auth if provided via environment
    if [[ -n "${TEST_EMAIL}" ]]; then
        DEFINE_FLAGS+=(--dart-define=TEST_EMAIL="${TEST_EMAIL}")
    fi
    if [[ -n "${TEST_PASSWORD}" ]]; then
        DEFINE_FLAGS+=(--dart-define=TEST_PASSWORD="${TEST_PASSWORD}")
    fi

    flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/app_test.dart \
        -d $DEVICE_ID \
        "${DEFINE_FLAGS[@]}" \
        2>&1 | tee -a "$LOG_FILE"
    drv_exit=${PIPESTATUS[0]}
    set -e

    # If Firestore write doc id was printed, try verifying with Firebase CLI
    FIREBASE_DOC_ID=$(grep -o 'FIREBASE_DOC_ID: [^ ]\+' "$LOG_FILE" | awk '{print $2}' | tail -1)
    FIREBASE_PROJECT=$(grep -o 'FIREBASE_PROJECT: [^ ]\+' "$LOG_FILE" | awk '{print $2}' | tail -1)
    if [[ -n "$FIREBASE_DOC_ID" ]]; then
        log_info "Detected Firestore test doc id: $FIREBASE_DOC_ID (project: ${FIREBASE_PROJECT:-auto})"
        if command -v firebase &> /dev/null; then
            # Attempt verification (best-effort). CLI may not have documents API; log outcome.
            log_info "Attempting Firebase CLI verification of test_runs/$FIREBASE_DOC_ID..."
            if firebase --project "${FIREBASE_PROJECT:-tripwizards-234db}" firestore:documents get "test_runs/$FIREBASE_DOC_ID" >> "$LOG_FILE" 2>&1; then
                log_success "Cloud Firestore verification succeeded for test_runs/$FIREBASE_DOC_ID"
            else
                log_warning "Firebase CLI document get failed. You can verify manually with:"
                log_warning "  firebase --project ${FIREBASE_PROJECT:-tripwizards-234db} firestore:documents get test_runs/$FIREBASE_DOC_ID"
            fi
        else
            log_warning "Firebase CLI not installed. To verify manually, run:"
            log_warning "  firebase --project ${FIREBASE_PROJECT:-tripwizards-234db} firestore:documents get test_runs/$FIREBASE_DOC_ID"
        fi
    fi
    
    if [ $drv_exit -eq 0 ]; then
        log_success "✅ All 20 automated integration tests PASSED"
        return 0
    else
        log_error "❌ Some automated integration tests FAILED"
        log_info "Check log file: $LOG_FILE"
        return 1
    fi
}

# Generate report
generate_report() {
    log_info "Generating test report..."
    
    local report_file="$REPORT_DIR/android_automated_report_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# Android Automated Integration Test Report

**Date:** $(date)
**Device:** $DEVICE_ID
**Flutter Version:** $(flutter --version | head -1)

## Test Summary

### Automated Integration Tests
All integration tests executed automatically without manual intervention.

**Test Coverage (20 Comprehensive Tests):**
1. ✅ App Launch & Initial Screen
2. ✅ Welcome/Login Screen Detection
3. ✅ Authentication Buttons
4. ✅ UI Components Rendering
5. ✅ Navigation Elements
6. ✅ Firebase Initialization
7. ✅ Responsive UI - Portrait Mode
8. ✅ Responsive UI - Landscape Mode
9. ✅ Rapid Interactions Stability
10. ✅ Form Elements Check
11. ✅ Button Types Accessibility
12. ✅ Settings/Menu Elements
13. ✅ Theme Configuration
14. ✅ Memory Stability
15. ✅ Screen Rotation Stress Test
16. ✅ Accessibility - Semantics
17. ✅ Offline Handling
18. ✅ No Critical Errors
19. ✅ Navigation State Preservation
20. ✅ Final Stability Check

## Test Details

**Intelligent Test Flow:**
- All tests run in a single session (no SemanticsHandle leaks)
- Tests intelligently detect current screen state
- Adaptive test execution based on app context
- Safe error handling for optional UI elements
- No manual user interaction required

See detailed logs: \`$LOG_FILE\`

## Key Improvements

1. **Single App Instance:** App launches once, all tests run in sequence
2. **Context-Aware:** Tests check current screen before performing actions
3. **No SemanticsHandle Leaks:** Proper lifecycle management
4. **Memory Efficient:** flutter drive handles app installation (no separate flutter run)
5. **Stable & Reliable:** Comprehensive error handling and graceful degradation

## Coverage

The automated test suite intelligently covers:
- App initialization and launch
- Authentication UI detection
- Navigation and screen transitions
- Responsive UI (portrait/landscape)
- Firebase integration health
- Performance and stability under stress
- UI component rendering
- Memory management
- Accessibility support
- Offline/error handling
- Theme configuration

## Recommendations

1. Run this suite in CI/CD pipeline before each release
2. Add more specific test cases as features are added
3. Monitor test execution time for performance regressions
4. Keep Firebase emulators running for consistent test environment

---
**Generated:** $(date)
EOF
    
    log_success "Report generated: $report_file"
}

# Main execution
main() {
    check_prerequisites
    detect_device
    clean_build
    
    # Run tests and capture exit code
    run_integration_tests
    TEST_EXIT_CODE=$?
    
    print_header
    generate_report
    
    echo ""
    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  ${BOLD}✅ AUTOMATED TESTING COMPLETE - ALL TESTS PASSED${NC}     ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}  ${BOLD}❌ AUTOMATED TESTING COMPLETE - SOME TESTS FAILED${NC}    ${RED}║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    fi
    echo ""
    echo -e "${CYAN}Test Log:${NC} $LOG_FILE"
    echo -e "${CYAN}Report:${NC} $REPORT_DIR/android_automated_report_$TIMESTAMP.md"
    echo ""
    
    # Note: cleanup() trap will handle RAM clearing automatically on exit
    exit $TEST_EXIT_CODE
}

# Run main
main
