#!/bin/bash

###############################################################################
# MCP Automation Script for Travel Wizards
# This script orchestrates automated interactive testing across all platforms
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_CONFIG="$WORKSPACE_ROOT/.vscode/mcp-config.json"
REPORT_DIR="$WORKSPACE_ROOT/build/reports"
SCREENSHOT_DIR="$WORKSPACE_ROOT/build/screenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create output directories
create_directories() {
    log_info "Creating output directories..."
    mkdir -p "$REPORT_DIR"
    mkdir -p "$SCREENSHOT_DIR"
    mkdir -p "$WORKSPACE_ROOT/build/logs"
    log_success "Directories created"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter SDK not found"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found - web tests will be skipped"
    fi
    
    log_success "Prerequisites check complete"
}

# Run Flutter unit tests
run_unit_tests() {
    log_info "Running Flutter unit tests..."
    
    cd "$WORKSPACE_ROOT"
    
    if flutter test --reporter=json > "$REPORT_DIR/unit_test_results_$TIMESTAMP.json" 2>&1; then
        log_success "Unit tests passed"
        flutter test --coverage
        log_info "Coverage report generated at coverage/lcov.info"
        return 0
    else
        log_error "Unit tests failed - check $REPORT_DIR/unit_test_results_$TIMESTAMP.json"
        return 1
    fi
}

# Run Flutter integration tests
run_integration_tests() {
    log_info "Running Flutter integration tests..."
    
    cd "$WORKSPACE_ROOT"
    
    # Check if Chrome is available for web testing
    if command -v google-chrome &> /dev/null || command -v chromium-browser &> /dev/null; then
        log_info "Chrome detected - running web integration tests"
        
        if flutter test integration_test/ --device-id=chrome --headless \
            > "$REPORT_DIR/integration_test_results_$TIMESTAMP.log" 2>&1; then
            log_success "Integration tests passed"
            return 0
        else
            log_error "Integration tests failed - check $REPORT_DIR/integration_test_results_$TIMESTAMP.log"
            return 1
        fi
    else
        log_warning "Chrome not found - skipping integration tests"
        return 0
    fi
}

# Run web tests with Puppeteer (if available)
run_web_tests() {
    log_info "Running web tests with Puppeteer..."
    
    if [ ! -f "$WORKSPACE_ROOT/scripts/web/test_chrome_puppeteer.js" ]; then
        log_warning "Puppeteer test script not found - skipping web tests"
        return 0
    fi
    
    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found - skipping web tests"
        return 0
    fi
    
    cd "$WORKSPACE_ROOT/scripts/web"
    
    # Install puppeteer if not present
    if [ ! -d "node_modules/puppeteer" ]; then
        log_info "Installing Puppeteer..."
        npm install puppeteer
    fi
    
    if node test_chrome_puppeteer.js > "$REPORT_DIR/web_test_results_$TIMESTAMP.log" 2>&1; then
        log_success "Web tests passed"
        return 0
    else
        log_error "Web tests failed - check $REPORT_DIR/web_test_results_$TIMESTAMP.log"
        return 1
    fi
}

# Start Firebase emulators
start_firebase_emulators() {
    log_info "Starting Firebase emulators..."
    
    if ! command -v firebase &> /dev/null; then
        log_warning "Firebase CLI not found - skipping emulator setup"
        return 0
    fi
    
    cd "$WORKSPACE_ROOT"
    firebase emulators:start --only firestore,auth,storage --project demo-test &
    FIREBASE_PID=$!
    
    # Wait for emulators to start
    sleep 5
    
    log_success "Firebase emulators started (PID: $FIREBASE_PID)"
    echo $FIREBASE_PID > "$WORKSPACE_ROOT/build/.firebase_pid"
}

# Stop Firebase emulators
stop_firebase_emulators() {
    if [ -f "$WORKSPACE_ROOT/build/.firebase_pid" ]; then
        FIREBASE_PID=$(cat "$WORKSPACE_ROOT/build/.firebase_pid")
        log_info "Stopping Firebase emulators (PID: $FIREBASE_PID)..."
        kill $FIREBASE_PID 2>/dev/null || true
        rm "$WORKSPACE_ROOT/build/.firebase_pid"
        log_success "Firebase emulators stopped"
    fi
}

# Generate comprehensive test report
generate_report() {
    log_info "Generating comprehensive test report..."
    
    REPORT_FILE="$REPORT_DIR/MCP_TEST_REPORT_$TIMESTAMP.md"
    
    cat > "$REPORT_FILE" << EOF
# MCP Automated Test Report
**Generated:** $(date)
**Workspace:** Travel Wizards
**Platform:** Linux ($(uname -m))
**Flutter Version:** $(flutter --version | head -n 1)

---

## Test Execution Summary

### Unit Tests
- **Status:** $UNIT_TEST_STATUS
- **Report:** unit_test_results_$TIMESTAMP.json
- **Coverage:** coverage/lcov.info

### Integration Tests
- **Status:** $INTEGRATION_TEST_STATUS
- **Report:** integration_test_results_$TIMESTAMP.log

### Web Tests (Puppeteer)
- **Status:** $WEB_TEST_STATUS
- **Report:** web_test_results_$TIMESTAMP.log

---

## Artifacts

- **Reports Directory:** $REPORT_DIR
- **Screenshots Directory:** $SCREENSHOT_DIR
- **Test Logs:** build/logs/

---

## Next Steps

EOF

    if [ "$UNIT_TEST_STATUS" == "FAILED" ] || \
       [ "$INTEGRATION_TEST_STATUS" == "FAILED" ] || \
       [ "$WEB_TEST_STATUS" == "FAILED" ]; then
        cat >> "$REPORT_FILE" << EOF
⚠️ **Some tests failed!** Please review the individual test reports above.

### Recommended Actions:
1. Check failing test logs in \`$REPORT_DIR\`
2. Review screenshots in \`$SCREENSHOT_DIR\` for visual failures
3. Run specific test suites with: \`flutter test <test_file>\`
4. Fix failures and re-run: \`./scripts/mcp_automation.sh\`
EOF
    else
        cat >> "$REPORT_FILE" << EOF
✅ **All tests passed successfully!**

### Recommended Actions:
1. Review coverage report: \`coverage/lcov.info\`
2. Deploy to staging environment
3. Update travel_wizards/README.md with latest results
4. Commit test reports to version control
EOF
    fi
    
    log_success "Test report generated: $REPORT_FILE"
    cat "$REPORT_FILE"
}

# Main execution
main() {
    log_info "═══════════════════════════════════════════════════════"
    log_info "  MCP Automated Interactive Testing"
    log_info "  Travel Wizards - Full Test Suite Execution"
    log_info "═══════════════════════════════════════════════════════"
    echo
    
    create_directories
    check_prerequisites
    
    # Start Firebase emulators
    start_firebase_emulators
    
    # Run all test suites
    UNIT_TEST_STATUS="PASSED"
    INTEGRATION_TEST_STATUS="PASSED"
    WEB_TEST_STATUS="PASSED"
    
    if ! run_unit_tests; then
        UNIT_TEST_STATUS="FAILED"
    fi
    
    if ! run_integration_tests; then
        INTEGRATION_TEST_STATUS="FAILED"
    fi
    
    if ! run_web_tests; then
        WEB_TEST_STATUS="FAILED"
    fi
    
    # Stop Firebase emulators
    stop_firebase_emulators
    
    # Generate report
    generate_report
    
    echo
    log_info "═══════════════════════════════════════════════════════"
    log_info "  Test Execution Complete"
    log_info "═══════════════════════════════════════════════════════"
    
    # Exit with appropriate code
    if [ "$UNIT_TEST_STATUS" == "FAILED" ] || \
       [ "$INTEGRATION_TEST_STATUS" == "FAILED" ] || \
       [ "$WEB_TEST_STATUS" == "FAILED" ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
