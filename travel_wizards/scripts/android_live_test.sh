#!/bin/bash

###############################################################################
# Android Live Interactive Testing Script
# Comprehensive test execution on physical Android device
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="$WORKSPACE_ROOT/build/reports"
SCREENSHOT_DIR="$WORKSPACE_ROOT/build/screenshots/android"
LOG_FILE="$REPORT_DIR/android_test_$TIMESTAMP.log"
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

log_user_action() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${YELLOW}║  ⚠️  USER ACTION REQUIRED  ⚠️                              ║${NC}" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
    echo -e "${BOLD}${YELLOW}$1${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Header
print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Android Live Interactive Testing${NC}                      ${CYAN}║${NC}"
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
    
    # Check Firebase emulators
    if ! pgrep -f "firebase.*emulator" > /dev/null; then
        log_warning "Firebase emulators not running - starting them..."
        # Firebase config is in parent directory
        FIREBASE_DIR="$(dirname "$WORKSPACE_ROOT")"
        cd "$FIREBASE_DIR"
        firebase emulators:start --only auth,firestore,database --import=./firebase/emulator --export-on-exit > /dev/null 2>&1 &
        sleep 10
        cd "$WORKSPACE_ROOT"
    fi
    
    log_success "Prerequisites check complete"
}

# Detect Android device
detect_device() {
    log_info "Detecting Android devices..."
    
    # List all devices
    adb devices -l
    
    # Get device ID
    DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        log_error "No Android device connected!"
        echo ""
        echo "Please connect your Android device and:"
        echo "  1. Enable USB Debugging in Developer Options"
        echo "  2. Accept USB debugging authorization on device"
        echo "  3. Run: adb devices"
        echo ""
        exit 1
    elif [ "$DEVICE_COUNT" -eq 1 ]; then
        DEVICE_ID=$(adb devices | grep "device$" | awk '{print $1}')
        log_success "Found device: $DEVICE_ID"
    else
        log_warning "Multiple devices found. Using first device."
        DEVICE_ID=$(adb devices | grep "device$" | head -1 | awk '{print $1}')
    fi
    
    # Get device info
    log_info "Device Information:"
    echo "  Model: $(adb -s $DEVICE_ID shell getprop ro.product.model)"
    echo "  Android: $(adb -s $DEVICE_ID shell getprop ro.build.version.release)"
    echo "  API Level: $(adb -s $DEVICE_ID shell getprop ro.build.version.sdk)"
    echo "  Brand: $(adb -s $DEVICE_ID shell getprop ro.product.brand)"
    echo ""
}

# Run app on device (hot reload enabled)
run_app_on_device() {
    log_info "Running app on device (this saves RAM compared to building APK)..."
    
    cd "$WORKSPACE_ROOT"
    
    # Recreate directories
    mkdir -p "$REPORT_DIR" "$SCREENSHOT_DIR"
    
    log_user_action "The app will now launch on your device.
Please keep the app running throughout the testing process.
Press Ctrl+C ONLY when instructed to do so."
    
    read -p "Press ENTER to start the app on your device..."
    
    # Run app in background
    log_info "Starting app on device $DEVICE_ID..."
    flutter run -d "$DEVICE_ID" --dart-define=FLUTTER_WEB_USE_SKIA=true > "$REPORT_DIR/flutter_run_$TIMESTAMP.log" 2>&1 &
    FLUTTER_PID=$!
    
    log_info "Waiting for app to start (60 seconds)..."
    sleep 60
    
    # Check if app is running
    if ps -p $FLUTTER_PID > /dev/null; then
        log_success "App is running on device (PID: $FLUTTER_PID)"
    else
        log_error "App failed to start!"
        cat "$REPORT_DIR/flutter_run_$TIMESTAMP.log"
        exit 1
    fi
}

# Run integration tests on device
run_integration_tests() {
    log_info "Running integration tests on device..."
    
    cd "$WORKSPACE_ROOT"
    
    if [ -f "integration_test/app_test.dart" ]; then
        log_test "Executing integration_test/app_test.dart..."
        
        flutter drive \
            --driver=test_driver/integration_test.dart \
            --target=integration_test/app_test.dart \
            -d "$DEVICE_ID" \
            2>&1 | tee -a "$LOG_FILE"
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            log_success "Integration tests passed!"
            return 0
        else
            log_error "Integration tests failed!"
            return 1
        fi
    else
        log_warning "No integration test found at integration_test/app_test.dart"
        return 0
    fi
}

# Interactive test scenarios
run_interactive_tests() {
    log_info "═══════════════════════════════════════════════════════════"
    log_info "  INTERACTIVE TEST SCENARIOS"
    log_info "  Please perform the following tests manually on the device"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Test 1: Onboarding Flow
    log_test "TEST 1: Onboarding Flow"
    log_user_action "On your device, perform these steps:
  1. The app should already be running on your device
  2. Go through all onboarding steps
  3. Verify: Welcome screen, Travel style selection, Progress indicator
  4. Tap 'Get Started!' on final step"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 2: Authentication
    log_test "TEST 2: Authentication (Google Sign-In)"
    log_user_action "On your device, perform these steps:
  1. Tap 'Sign in with Google'
  2. Select Google account
  3. Verify: Successful authentication, user profile loaded
  4. Check: User name/email displayed in profile"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Authentication" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Authentication" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 3: I18N Language Switching
    log_test "TEST 3: I18N - Language Switching"
    echo "  1. Go to Settings"
    echo "  2. Change language to Hindi (हिंदी)"
    echo "  3. Verify: All UI text changes to Hindi"
    echo "  4. Change to Tamil (தமிழ்)"
    echo "  5. Verify: All UI text changes to Tamil"
    echo "  6. Change to Telugu (తెలుగు)"
    echo "  7. Verify: All UI text changes to Telugu"
    echo "  8. Change back to English"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: I18N Language Switching" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: I18N Language Switching" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 4: RTL Support (Urdu)
    log_test "TEST 4: RTL Support - Urdu (اردو)"
    echo "  1. Go to Settings"
    echo "  2. Change language to Urdu (اردو)"
    echo "  3. Verify: UI layout is right-to-left"
    echo "  4. Verify: Text alignment is correct (right-aligned)"
    echo "  5. Verify: Icons/buttons mirrored appropriately"
    echo "  6. Change back to English"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: RTL Support" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: RTL Support" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 5: Calendar Permission Revocation
    log_test "TEST 5: Calendar Permission - Mid-Session Revocation"
    echo "  1. Grant calendar permission when prompted"
    echo "  2. Navigate to a feature that uses calendar"
    echo "  3. Go to Android Settings > Apps > Travel Wizards > Permissions"
    echo "  4. Revoke Calendar permission"
    echo "  5. Return to app (don't restart)"
    echo "  6. Verify: App handles permission revocation gracefully"
    echo "  7. Verify: User is prompted to re-grant permission"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Calendar Permission Revocation" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Calendar Permission Revocation" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 6: Tier Limits (Free Tier)
    log_test "TEST 6: Tier Limits - Free Tier (1 generation/day)"
    echo "  1. Ensure user is on Free tier"
    echo "  2. Generate first trip itinerary"
    echo "  3. Verify: Generation succeeds"
    echo "  4. Attempt to generate second trip"
    echo "  5. Verify: Error message 'Free tier: 1 generation per day limit reached'"
    echo "  6. Verify: User is prompted to upgrade to Pro"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Free Tier Limit" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Free Tier Limit" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 7: Payment - Consolidated Invoice
    log_test "TEST 7: Payment - Consolidated Invoice Display"
    echo "  1. Go to Profile > Billing"
    echo "  2. View payment history"
    echo "  3. Verify: All charges displayed in consolidated invoice"
    echo "  4. Verify: Line items include: trip generation, premium features, add-ons"
    echo "  5. Verify: Total matches sum of all line items"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Consolidated Invoice" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Consolidated Invoice" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 8: Booking API Failure Handling
    log_test "TEST 8: Booking API Failure Handling"
    log_user_action "On your device, perform these steps:
  1. Enable Airplane mode on device
  2. Attempt to book a hotel/flight
  3. Verify: Error message displayed
  4. Verify: User can retry booking
  5. Disable Airplane mode
  6. Retry booking
  7. Verify: Booking succeeds"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Booking API Failure" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Booking API Failure" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 9: Pause Account Search
    log_test "TEST 9: Settings - Pause Account Search"
    echo "  1. Go to Settings"
    echo "  2. Use search bar to find 'Pause Account'"
    echo "  3. Verify: Search result appears"
    echo "  4. Tap on 'Pause Account' result"
    echo "  5. Verify: Navigates to Account Pause screen"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Pause Account Search" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Pause Account Search" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 10: Parental Controls Search
    log_test "TEST 10: Settings - Parental Controls Search"
    echo "  1. Go to Settings"
    echo "  2. Use search bar to find 'Parental Controls'"
    echo "  3. Verify: Search result appears"
    echo "  4. Tap on 'Parental Controls' result"
    echo "  5. Verify: Navigates to Parental Controls screen"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Parental Controls Search" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Parental Controls Search" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 11: Onboarding Data Validation
    log_test "TEST 11: Onboarding - Mandatory Field Validation"
    echo "  1. Clear app data and restart"
    echo "  2. Go through onboarding"
    echo "  3. Try to skip mandatory fields"
    echo "  4. Verify: Cannot proceed without filling required fields"
    echo "  5. Verify: Error messages displayed for empty fields"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Onboarding Validation" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Onboarding Validation" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 12: App Drawer Navigation
    log_test "TEST 12: App Drawer - External App Links"
    echo "  1. Open app drawer (if available)"
    echo "  2. Tap on external app links (Maps, Calendar, etc.)"
    echo "  3. Verify: Correct external app launches"
    echo "  4. Return to Travel Wizards"
    echo "  5. Verify: App state preserved"
    read -p "  Press ENTER when test is complete (or type 'fail' if failed): " result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: App Drawer Navigation" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: App Drawer Navigation" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 13: Trip Planning - Create New Trip
    log_test "TEST 13: Trip Planning - Create New Trip"
    log_user_action "On your device, perform these steps:
  1. Tap 'Plan Trip' or FAB button
  2. Enter destination (e.g., 'Paris, France')
  3. Select travel dates (future dates)
  4. Choose number of travelers
  5. Select budget range (Budget-friendly/Mid-range/Luxury)
  6. Verify: Trip generation starts
  7. Verify: Loading animation/progress indicator shown"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Trip Planning" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Trip Planning" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 14: Trip Details - View and Edit
    log_test "TEST 14: Trip Details - View and Edit Itinerary"
    log_user_action "On your device, perform these steps:
  1. Open an existing trip from Trip History
  2. Verify: Trip details displayed (dates, destination, budget)
  3. Verify: Daily itinerary shown with activities
  4. Tap 'Edit' on an activity
  5. Modify activity (time/location/description)
  6. Verify: Changes saved successfully
  7. Tap 'Add Activity' button
  8. Add custom activity to itinerary"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Trip Details Edit" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Trip Details Edit" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 15: Trip Collaboration - Sharing
    log_test "TEST 15: Trip Collaboration - Share with Travel Buddies"
    log_user_action "On your device, perform these steps:
  1. Open trip details
  2. Tap 'Share' or 'Collaborate' button
  3. Select sharing method (Email/Link/Contacts)
  4. Verify: Share dialog opens
  5. Share trip with contact
  6. Verify: Confirmation message shown
  7. Go to 'Shared Trips' section
  8. Verify: Shared trip appears with collaborators"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Trip Collaboration" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Trip Collaboration" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 16: Explore Screen - Discover Destinations
    log_test "TEST 16: Explore Screen - Destination Discovery"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Explore' tab/screen
  2. Verify: Featured destinations displayed with images
  3. Scroll through destination cards
  4. Tap on a destination card
  5. Verify: Destination details shown (attractions, weather, tips)
  6. Tap 'Plan Trip' from destination details
  7. Verify: Trip planning screen opens with pre-filled destination"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Explore Screen" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Explore Screen" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 17: Concierge Chat - AI Assistant
    log_test "TEST 17: Concierge Chat - AI Travel Assistant"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Concierge' or 'Chat' screen
  2. Verify: Chat interface displayed
  3. Send message: 'Recommend restaurants in Tokyo'
  4. Verify: AI response received with recommendations
  5. Send follow-up: 'What about vegetarian options?'
  6. Verify: Context-aware response provided
  7. Tap on a recommended restaurant
  8. Verify: Details/booking option shown"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Concierge Chat" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Concierge Chat" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 18: Bookings - Hotel/Flight Management
    log_test "TEST 18: Bookings - Hotel and Flight Management"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Bookings' screen
  2. Verify: List of all bookings displayed
  3. Filter by type (Hotels/Flights/Activities)
  4. Tap on a booking
  5. Verify: Booking details shown (confirmation #, dates, price)
  6. Verify: Action buttons (Cancel, Modify, View Ticket)
  7. Tap 'View Ticket'
  8. Verify: Ticket/confirmation displayed correctly"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Bookings Management" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Bookings Management" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 19: Emergency Screen - SOS Features
    log_test "TEST 19: Emergency Screen - SOS and Emergency Contacts"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Emergency' screen
  2. Verify: Emergency contact numbers displayed (police, hospital, embassy)
  3. Verify: Current location shown on map
  4. Verify: 'Call Emergency' button prominent
  5. Test 'Share Location' feature (without actually calling)
  6. Verify: Location sharing options available
  7. Check 'Emergency Contacts' list
  8. Verify: Can add/edit personal emergency contacts"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Emergency Screen" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Emergency Screen" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 20: Maps Integration - Location Services
    log_test "TEST 20: Maps Integration - Navigation and POI"
    log_user_action "On your device, perform these steps:
  1. Open a trip or activity with location
  2. Tap 'View on Map' or map icon
  3. Verify: Map screen opens with location marker
  4. Verify: Current location shown (blue dot)
  5. Tap 'Directions' button
  6. Verify: Navigation options shown (Google Maps/Apple Maps)
  7. Search for nearby POI (restaurants, ATMs)
  8. Verify: Search results shown on map with markers"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Maps Integration" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Maps Integration" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 21: Notifications - Push and In-App
    log_test "TEST 21: Notifications - Push and In-App Alerts"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Notifications' screen
  2. Verify: Notification list displayed
  3. Verify: Categories (Trip Updates, Bookings, Promotions)
  4. Tap on a notification
  5. Verify: Opens relevant screen (trip/booking details)
  6. Go to Settings > Notifications
  7. Verify: Can toggle notification types on/off
  8. Test notification preferences saved"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Notifications" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Notifications" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 22: Profile Screen - User Information
    log_test "TEST 22: Profile Screen - Edit User Information"
    log_user_action "On your device, perform these steps:
  1. Navigate to Profile screen
  2. Verify: User info displayed (name, email, photo)
  3. Tap 'Edit Profile' button
  4. Change display name
  5. Update profile photo (camera/gallery)
  6. Save changes
  7. Verify: Changes reflected immediately
  8. Check 'Travel Stats' section (trips, countries visited)"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Profile Screen" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Profile Screen" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 23: Settings - Appearance Customization
    log_test "TEST 23: Settings - Appearance and Theme"
    log_user_action "On your device, perform these steps:
  1. Go to Settings > Appearance
  2. Toggle Theme (Light/Dark/System)
  3. Verify: UI updates immediately
  4. Change accent color (if available)
  5. Verify: Color changes applied
  6. Toggle 'Material You' dynamic colors
  7. Verify: Colors adapt to wallpaper
  8. Test font size adjustment"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Appearance Settings" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Appearance Settings" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 24: Settings - Privacy Controls
    log_test "TEST 24: Settings - Privacy Dashboard and Controls"
    log_user_action "On your device, perform these steps:
  1. Go to Settings > Privacy & Security
  2. Verify: Privacy Dashboard displayed
  3. Check 'Data Usage' summary
  4. Verify: Shows what data is collected
  5. Toggle 'Analytics' sharing on/off
  6. Toggle 'Personalized Ads' on/off
  7. Tap 'Download My Data'
  8. Verify: Data export option available"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Privacy Controls" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Privacy Controls" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 25: Payment Options - Add/Manage Cards
    log_test "TEST 25: Payment Options - Add and Manage Payment Methods"
    log_user_action "On your device, perform these steps:
  1. Go to Settings > Payments or Profile > Payment Methods
  2. Verify: List of saved payment methods
  3. Tap 'Add Payment Method'
  4. Verify: Credit card form or Google Pay option
  5. Fill out card details (use test card if available)
  6. Save payment method
  7. Verify: New card appears in list
  8. Test 'Set as Default' option"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Payment Options" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Payment Options" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 26: Payment History - View Invoices
    log_test "TEST 26: Payment History - Transaction History and Invoices"
    log_user_action "On your device, perform these steps:
  1. Go to Profile > Payment History or Billing
  2. Verify: List of past transactions displayed
  3. Verify: Each shows date, amount, description
  4. Tap on a transaction
  5. Verify: Detailed invoice shown
  6. Verify: Line items breakdown visible
  7. Test 'Download Invoice' button
  8. Verify: PDF downloaded or shareable"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Payment History" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Payment History" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 27: Budget Tracking
    log_test "TEST 27: Budget Tracking - Set and Monitor Expenses"
    log_user_action "On your device, perform these steps:
  1. Navigate to Budget screen (from menu/profile)
  2. Tap 'Set Monthly Budget'
  3. Enter budget amount (e.g., \$2000)
  4. Save budget
  5. Verify: Budget visualization shown (circular progress/chart)
  6. Check 'Expenses' breakdown by category
  7. Verify: Categories (Accommodation, Food, Transport, etc.)
  8. Verify: Remaining budget calculated correctly"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Budget Tracking" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Budget Tracking" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 28: Trip Execution Mode
    log_test "TEST 28: Trip Execution - Live Trip Mode"
    log_user_action "On your device, perform these steps:
  1. Open an upcoming trip
  2. Tap 'Start Trip' or 'Execute Trip' button
  3. Verify: Trip execution mode activated
  4. Verify: Current day's itinerary highlighted
  5. Check off completed activities
  6. Verify: Progress tracked visually
  7. Tap 'Add Expense' during trip
  8. Verify: Can log expenses on-the-go"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Trip Execution" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Trip Execution" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 29: Drafts - Save Incomplete Trips
    log_test "TEST 29: Drafts - Save and Resume Planning"
    log_user_action "On your device, perform these steps:
  1. Start creating a new trip
  2. Fill partial information (destination only)
  3. Tap back button or 'Save as Draft'
  4. Verify: Draft save confirmation shown
  5. Navigate to 'Drafts' section
  6. Verify: Draft trip appears in list
  7. Tap on draft
  8. Verify: Returns to planning with saved data"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Drafts" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Drafts" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 30: Social Features - Travel Buddies
    log_test "TEST 30: Social Features - Find Travel Buddies"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Social' or 'Travel Buddies' screen
  2. Verify: List of potential buddies or connections
  3. Use search/filter (by destination, dates, interests)
  4. Verify: Search results update
  5. Tap on a user profile
  6. Verify: Profile details shown (travel style, past trips)
  7. Tap 'Send Friend Request' or 'Connect'
  8. Verify: Request sent confirmation"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Social Features" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Social Features" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 31: Brainstorm Feature
    log_test "TEST 31: Brainstorm - Trip Idea Generator"
    log_user_action "On your device, perform these steps:
  1. Navigate to 'Brainstorm' screen
  2. Verify: Prompt/input for trip preferences
  3. Enter preferences (budget, season, activities)
  4. Tap 'Generate Ideas'
  5. Verify: AI generates destination suggestions
  6. Verify: Each suggestion shows key highlights
  7. Tap 'Plan This Trip' on a suggestion
  8. Verify: Opens trip planning with pre-filled data"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Brainstorm Feature" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Brainstorm Feature" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 32: Subscription Management
    log_test "TEST 32: Subscription - Upgrade to Pro/Enterprise"
    log_user_action "On your device, perform these steps:
  1. Go to Settings > Subscription
  2. Verify: Current tier displayed (Free/Pro/Enterprise)
  3. Verify: Tier comparison table shown
  4. Tap 'Upgrade to Pro'
  5. Verify: Subscription plans displayed with pricing
  6. Verify: Features comparison clear
  7. Tap plan (don't actually purchase)
  8. Verify: Payment flow initiates correctly"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Subscription Management" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Subscription Management" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 33: Tickets Screen - Support Requests
    log_test "TEST 33: Support Tickets - Create and Track Issues"
    log_user_action "On your device, perform these steps:
  1. Navigate to Settings > Help & Support > Tickets
  2. Verify: List of existing tickets (if any)
  3. Tap 'Create New Ticket'
  4. Select issue category (Booking, Payment, Technical)
  5. Enter issue description and details
  6. Attach screenshot (optional)
  7. Submit ticket
  8. Verify: Ticket created with confirmation number"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Support Tickets" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Support Tickets" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 34: Static Pages - About, Help, Legal
    log_test "TEST 34: Static Pages - About, Help, FAQ, Legal"
    log_user_action "On your device, perform these steps:
  1. Go to Settings > About
  2. Verify: App version, credits displayed
  3. Go to Settings > Help
  4. Verify: Help articles/guides shown
  5. Go to Settings > FAQ
  6. Verify: FAQs displayed, expandable sections work
  7. Go to Settings > Legal/Privacy Policy
  8. Verify: Legal text displayed, scrollable"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Static Pages" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Static Pages" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 35: Email Login Alternative
    log_test "TEST 35: Authentication - Email/Password Login"
    log_user_action "On your device, perform these steps:
  1. Sign out if logged in
  2. On login screen, tap 'Sign in with Email'
  3. Verify: Email/password form displayed
  4. Try invalid email format
  5. Verify: Validation error shown
  6. Try incorrect password
  7. Verify: Authentication error shown
  8. Use correct credentials (if available)"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Email Login" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Email Login" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 36: Deep Links and Navigation
    log_test "TEST 36: Deep Links - External Link Handling"
    log_user_action "On your device, perform these steps:
  1. Send app a deep link via ADB or another app:
     adb shell am start -a android.intent.action.VIEW -d 'travelwizards://trip/123'
  2. Verify: App opens to correct screen (trip details)
  3. Test another deep link (booking, profile)
  4. Verify: Navigation handled correctly
  5. Test invalid deep link
  6. Verify: Graceful fallback (home or error)"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Deep Links" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Deep Links" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 37: Accessibility Features
    log_test "TEST 37: Accessibility - Screen Reader and TalkBack"
    log_user_action "On your device, perform these steps:
  1. Enable TalkBack (Settings > Accessibility)
  2. Navigate through app screens
  3. Verify: All buttons/elements have labels
  4. Verify: Content descriptions are meaningful
  5. Test focus order is logical
  6. Test form inputs with TalkBack
  7. Verify: Error messages are announced
  8. Disable TalkBack when done"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Accessibility" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Accessibility" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 38: Offline Mode and Sync
    log_test "TEST 38: Offline Mode - Data Sync and Caching"
    log_user_action "On your device, perform these steps:
  1. While online, open several trips and bookings
  2. Enable Airplane mode
  3. Navigate through previously viewed content
  4. Verify: Cached data still accessible
  5. Try to create new trip offline
  6. Verify: 'Offline mode' message shown
  7. Disable Airplane mode
  8. Verify: App syncs automatically, shows sync indicator"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Offline Mode" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Offline Mode" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 39: Memory and Performance
    log_test "TEST 39: Performance - Memory Usage and Responsiveness"
    log_user_action "On your device, perform these steps:
  1. Open Developer Options > Show Layout Bounds
  2. Navigate through 5-10 different screens rapidly
  3. Verify: No visible lag or stuttering
  4. Open Recent Apps to check memory usage
  5. Verify: App doesn't crash or reload
  6. Create trip with many activities (10+)
  7. Verify: Scrolling remains smooth
  8. Check battery usage (Settings > Battery)"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Performance" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Performance" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
    
    # Test 40: Edge Cases - Boundary Testing
    log_test "TEST 40: Edge Cases - Boundary and Stress Testing"
    log_user_action "On your device, perform these steps:
  1. Try creating trip with past dates
  2. Verify: Validation error shown
  3. Try extremely long destination name (100+ chars)
  4. Verify: Input limited or handled gracefully
  5. Try creating trip for 99+ travelers
  6. Verify: Reasonable limit enforced
  7. Test form with all fields empty
  8. Verify: All required field errors shown
  9. Rapidly tap buttons 10+ times
  10. Verify: No duplicate actions/crashes"
    read -p "${BOLD}Press ENTER when test is complete (or type 'fail' if failed): ${NC}" result
    if [[ "$result" == "fail" ]]; then
        echo "FAILED: Edge Cases" >> "$REPORT_DIR/manual_test_results.txt"
    else
        echo "PASSED: Edge Cases" >> "$REPORT_DIR/manual_test_results.txt"
    fi
    echo ""
}

# Capture device screenshots
capture_screenshots() {
    log_info "Capturing device screenshots..."
    
    mkdir -p "$SCREENSHOT_DIR"
    
    for i in {1..5}; do
        SCREENSHOT="$SCREENSHOT_DIR/screenshot_${TIMESTAMP}_${i}.png"
        adb -s "$DEVICE_ID" shell screencap -p > "$SCREENSHOT"
        log_info "Captured: screenshot_${i}.png"
        sleep 2
    done
    
    log_success "Screenshots saved to: $SCREENSHOT_DIR"
}

# Collect device logs
collect_logs() {
    log_info "Collecting device logs..."
    
    # Logcat
    adb -s "$DEVICE_ID" logcat -d > "$REPORT_DIR/logcat_$TIMESTAMP.txt"
    
    # App-specific logs
    adb -s "$DEVICE_ID" logcat -d | grep "travel_wizards" > "$REPORT_DIR/app_logs_$TIMESTAMP.txt" || true
    
    log_success "Logs saved to: $REPORT_DIR"
}

# Generate comprehensive report
generate_report() {
    log_info "Generating comprehensive test report..."
    
    REPORT_FILE="$REPORT_DIR/ANDROID_TEST_REPORT_$TIMESTAMP.md"
    
    cat > "$REPORT_FILE" << EOF
# Android Live Interactive Test Report

**Date:** $(date)
**Device:** $(adb -s $DEVICE_ID shell getprop ro.product.model)
**Android Version:** $(adb -s $DEVICE_ID shell getprop ro.build.version.release)
**API Level:** $(adb -s $DEVICE_ID shell getprop ro.build.version.sdk)
**Device ID:** $DEVICE_ID

---

## Test Results Summary

### Automated Tests
EOF

    # Integration test results
    if grep -q "All tests passed" "$LOG_FILE"; then
        echo "- ✅ Integration Tests: **PASSED**" >> "$REPORT_FILE"
    else
        echo "- ❌ Integration Tests: **FAILED**" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "### Manual Interactive Tests" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Manual test results
    if [ -f "$REPORT_DIR/manual_test_results.txt" ]; then
        while IFS= read -r line; do
            if [[ $line == PASSED* ]]; then
                echo "- ✅ $line" >> "$REPORT_FILE"
            else
                echo "- ❌ $line" >> "$REPORT_FILE"
            fi
        done < "$REPORT_DIR/manual_test_results.txt"
    fi
    
    cat >> "$REPORT_FILE" << EOF

---

## Device Information

- **Model:** $(adb -s $DEVICE_ID shell getprop ro.product.model)
- **Brand:** $(adb -s $DEVICE_ID shell getprop ro.product.brand)
- **Android Version:** $(adb -s $DEVICE_ID shell getprop ro.build.version.release)
- **API Level:** $(adb -s $DEVICE_ID shell getprop ro.build.version.sdk)
- **Screen Resolution:** $(adb -s $DEVICE_ID shell wm size | awk '{print $3}')
- **Density:** $(adb -s $DEVICE_ID shell wm density | awk '{print $3}')

---

## Artifacts

- **Screenshots:** $SCREENSHOT_DIR
- **Logcat:** $REPORT_DIR/logcat_$TIMESTAMP.txt
- **App Logs:** $REPORT_DIR/app_logs_$TIMESTAMP.txt
- **Test Log:** $LOG_FILE

---

## Issues Found

EOF

    # Extract failures
    if [ -f "$REPORT_DIR/manual_test_results.txt" ]; then
        grep "FAILED" "$REPORT_DIR/manual_test_results.txt" | while read -r line; do
            echo "- $line" >> "$REPORT_FILE"
        done
    fi
    
    cat >> "$REPORT_FILE" << EOF

---

## Next Steps

1. Review failed tests above
2. Check screenshots in: $SCREENSHOT_DIR
3. Analyze logs in: $REPORT_DIR
4. Update ToDo.md with issues found
5. Fix issues and re-test

---

*Generated by Android Live Interactive Testing Script*
EOF

    log_success "Report generated: $REPORT_FILE"
    
    # Display report
    cat "$REPORT_FILE"
}

# Main execution
main() {
    # Create directories first - before any logging
    mkdir -p "$REPORT_DIR" "$SCREENSHOT_DIR"
    rm -f "$REPORT_DIR/manual_test_results.txt"
    
    print_header
    
    # Run tests
    check_prerequisites
    detect_device
    run_app_on_device
    
    echo ""
    log_info "Starting comprehensive test execution..."
    echo ""
    
    # Automated tests
    run_integration_tests
    
    # Interactive tests
    run_interactive_tests
    
    log_user_action "Testing complete! 
Now stopping the app and collecting logs/screenshots.
Please wait..."
    
    # Stop the Flutter app
    if [ ! -z "$FLUTTER_PID" ] && ps -p $FLUTTER_PID > /dev/null; then
        log_info "Stopping Flutter app (PID: $FLUTTER_PID)..."
        kill $FLUTTER_PID
        wait $FLUTTER_PID 2>/dev/null || true
    fi
    
    # Collect artifacts
    capture_screenshots
    collect_logs
    
    # Generate report
    generate_report
    
    echo ""
    log_success "╔════════════════════════════════════════════════════════════╗"
    log_success "║  Android Testing Complete!                                ║"
    log_success "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Report: $REPORT_DIR/ANDROID_TEST_REPORT_$TIMESTAMP.md"
    echo ""
}

# Run main
main "$@"
