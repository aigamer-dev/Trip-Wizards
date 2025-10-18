# 🎯 **Travel Wizards Flutter App - Complete Architecture Guide**

## 📱 **Core App Configuration**

| File | Purpose | Edit For |
|------|---------|----------|
| **main.dart** | App entry point, initializes everything | App startup logic, global configs |
| **firebase_options.dart** | Firebase configuration | Firebase settings, API keys |

---

## 🎨 **UI Foundation & Theming**

**Location: `src/app/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **app.dart** | Main app widget, MaterialApp setup | App-wide settings, initial route |
| **theme.dart** | App theme configuration | Colors, fonts, component styles |
| **travel_colors.dart** | Color palette definitions | Brand colors, UI color scheme |
| **travel_icons.dart** | Custom icon definitions | Icon assets, custom icons |
| **travel_typography.dart** | Font styles and text themes | Text sizes, font families |
| **settings_controller.dart** | App settings state management | Theme switching, user preferences |

---

## 🏗️ **Architecture & Dependency Management**

**Location: `src/architecture/` & `src/di/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **service_locator.dart** | Basic dependency injection | Service registration |
| **enhanced_service_locator.dart** | Advanced DI with lifecycle | Complex service management |
| **service_factory.dart** | Service instantiation logic | Creating service instances |
| **travel_wizards_service_registry.dart** | App-specific service registry | App service configuration |

---

## 🎮 **State Management & Controllers**

**Location: `src/controllers/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **base_controller.dart** | Common controller functionality | Shared controller logic |
| **auth_controller.dart** | Authentication state | Login/logout, user sessions |
| **explore_controller.dart** | Explore screen business logic | Travel discovery features |
| **trip_planning_controller.dart** | Trip planning state | Trip creation, planning flow |

---

## 📊 **Data Layer & State Stores**

**Location: `src/data/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **profile_store.dart** | User profile data management | Profile info, preferences |
| **explore_store.dart** | Explore screen data | Travel destinations, search |
| **plan_trip_store.dart** | Trip planning data | Trip details, itinerary |
| **brainstorm_session_store.dart** | AI brainstorming sessions | Idea generation, sessions |
| **conversation_controller.dart** | Chat/conversation state | AI chat, messaging |
| **onboarding_state.dart** | User onboarding flow | First-time user experience |
| **trip_planning_wizard_controller.dart** | Step-by-step trip creation | Wizard navigation, data |

---

## 📱 **Screen Components**

**Location: `src/screens/`**

### **Authentication Screens**

| File | Purpose | Edit For |
|------|---------|----------|
| **login_landing_screen.dart** | Main login page | Login UI, auth options |
| **email_login_screen.dart** | Email-based login | Email authentication form |
| **google_signin_debug_screen.dart** | Google auth debugging | OAuth troubleshooting |

### **Main App Screens**

| File | Purpose | Edit For |
|------|---------|----------|
| **home_screen.dart** | App dashboard/home | Main navigation, overview |
| **explore_screen.dart** | Basic travel exploration | Destination browsing |
| **enhanced_explore_screen.dart** | Advanced explore features | Enhanced discovery UI |
| **plan_trip_screen.dart** | Trip planning interface | Trip creation workflow |
| **settings_screen.dart** | App settings | User preferences, config |

### **Feature-Specific Screen Folders**

| Folder | Purpose | Edit For |
|--------|---------|----------|
| **onboarding/** | First-time user setup | Welcome flow, user setup |
| **brainstorm/** | AI-powered idea generation | Trip brainstorming UI |
| **trip/** | Trip management | Trip details, itinerary |
| **booking/** | Travel bookings | Hotel/flight booking |
| **bookings/** | Booking management | Booking history, status |
| **social/** | Social features | Sharing, collaboration |
| **map/** | Map functionality | Interactive maps, location |
| **payments/** | Payment processing | Payment forms, transactions |
| **notifications/** | App notifications | Push notifications, alerts |
| **emergency/** | Emergency features | Safety, emergency contacts |
| **concierge/** | Concierge services | Premium assistance |
| **sharing/** | Content sharing | Social sharing features |
| **static/** | Static content pages | About, terms, privacy |
| **settings/** | Settings sub-screens | Detailed settings pages |

---

## 🌍 **Internationalization (i18n)**

**Location: `src/l10n/`**

| File Type | Purpose | Edit For |
|-----------|---------|----------|
| **app_*.arb** | Translation strings (11 languages) | Adding new text, translations |
| **app_localizations_*.dart** | Generated localization classes | Auto-generated, don't edit |
| **app_localizations.dart** | Main localization class | Auto-generated, don't edit |

**Supported Languages:** English, Hindi, Bengali, Telugu, Marathi, Tamil, Urdu, Gujarati, Malayalam, Kannada, Odia

---

## 🗂️ **Data Models**

**Location: `src/models/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **user.dart** | User data structure | User properties, methods |
| **trip.dart** | Trip data model | Trip structure, properties |
| **trip_location.dart** | Location data model | Places, coordinates |
| **collaborative_trip.dart** | Shared trip features | Group travel, collaboration |
| **social_models.dart** | Social feature models | Sharing, social interactions |

---

## 🔄 **Data Access Layer**

**Location: `src/repositories/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **base_repository.dart** | Common repository functionality | Shared data access logic |
| **ideas_repository.dart** | Trip ideas data access | AI suggestions, ideas |
| **ideas_remote_repository.dart** | Remote ideas API | API calls for ideas |

---

## 🧭 **Navigation & Routing**

**Location: `src/routing/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **router.dart** | App route definitions | Adding new routes, navigation |
| **nav_shell.dart** | Navigation shell/wrapper | Navigation bar, drawer |
| **app_bar_title_controller.dart** | Dynamic app bar titles | Page titles, headers |
| **transitions.dart** | Page transition animations | Custom animations |

---

## ⚙️ **Services & Business Logic**

**Location: `src/services/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **accessibility_service.dart** | Accessibility features | Screen readers, a11y |
| **adk_service.dart** | Analytics/tracking | User analytics, events |
| **dependency_management_service.dart** | Dependency monitoring | Package management |

---

## 🛠️ **Utilities & Helpers**

**Location: `src/utils/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **dependency_audit_utility.dart** | Package health monitoring | Dependency checks, audits |

---

## 🧩 **Reusable Widgets**

**Location: `src/widgets/` & `src/common/widgets/`**

- Custom UI components
- Reusable elements across screens
- Common form elements, buttons, cards

---

## ⚙️ **Configuration**

**Location: `src/config/`**

| File | Purpose | Edit For |
|------|---------|----------|
| **env.dart** | Environment configuration | API endpoints, feature flags |

---

## 🎯 **Quick Edit Guide**

### **To Update UI:**

1. **Colors/Theme** → `src/app/travel_colors.dart`, `theme.dart`
2. **Screen Layout** → `src/screens/[screen_name].dart`
3. **Widgets** → `src/widgets/` or `src/common/widgets/`
4. **Text/Translations** → `src/l10n/app_en.arb` (then run `flutter gen-l10n`)

### **To Add Functionality:**

1. **New Screen** → Create in `src/screens/`
2. **Business Logic** → Add controller in `src/controllers/`
3. **Data Model** → Create in `src/models/`
4. **API Service** → Add to `src/services/`
5. **Navigation** → Update `src/routing/router.dart`

### **To Modify Data Flow:**

1. **State Management** → `src/data/` stores
2. **API Calls** → `src/repositories/`
3. **Service Logic** → `src/services/`
