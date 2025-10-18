# Travel Wizards Design System Specification

## Design Principles

### 1. Material Design 3 Foundation
- Surface container hierarchy for depth
- Color roles for semantic meaning
- Tonal elevation instead of shadows
- Consistent spacing (8dp grid)
- Proper touch targets (48x48dp minimum)

### 2. Responsive Layout Strategy

#### Mobile (<600px)
- Full-width content
- Bottom navigation bar
- Hamburger menu for additional items
- AppBar with title
- Vertical stacking

#### Tablet/Desktop (≥600px)
- Fixed 240px sidebar navigation
- 80px top bar (search + actions)
- Content area takes remaining space
- Horizontal layout with clear zones
- FAB in bottom-right

## Layout Components

### Desktop/Tablet Structure

```dart
Scaffold(
  body: Row(
    children: [
      // Fixed Sidebar (240px)
      Container(
        width: 240,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          )),
        ),
        child: Column(
          children: [
            Header(height: 80),
            Divider(height: 1),
            Expanded(child: NavigationMenu()),
          ],
        ),
      ),
      // Main Content Area
      Expanded(
        child: Column(
          children: [
            TopBar(height: 80),
            Expanded(child: Content()),
          ],
        ),
      ),
    ],
  ),
)
```

### Top Bar (80px height)

```dart
Container(
  height: 80,
  padding: EdgeInsets.symmetric(horizontal: 24),
  decoration: BoxDecoration(
    color: scheme.surface,
    border: Border(bottom: BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.2),
    )),
  ),
  child: Row(
    children: [
      // Page title or search
      Expanded(child: ...),
      // Action buttons
      IconButton(...),
      // Profile avatar
      ProfileAvatar(...),
    ],
  ),
)
```

## Color System

### Surface Hierarchy
```dart
// Darkest to lightest (dark mode reversed)
surface              // Base background
surfaceContainer     // Slight elevation
surfaceContainerLow  // Navigation sidebar
surfaceContainerHigh // Cards, elevated elements
surfaceContainerHighest // Emphasized cards

// Usage Examples:
- Main background: scheme.surface
- Sidebar: scheme.surfaceContainerLow
- Cards: scheme.surfaceContainerHigh
- Emphasized sections: scheme.secondaryContainer.withValues(alpha: 0.3)
```

### Interactive Elements
```dart
// Buttons
primaryContainer / onPrimaryContainer      // Primary actions
secondaryContainer / onSecondaryContainer  // Secondary actions
tertiaryContainer / onTertiaryContainer    // Tertiary actions

// Selection States
secondaryContainer.withValues(alpha: 0.5)  // Selected items
surfaceContainerHighest                    // Hover states
```

### Borders & Dividers
```dart
outlineVariant.withValues(alpha: 0.2)  // Subtle borders
outlineVariant.withValues(alpha: 0.3)  // Card borders
outline                                 // Emphasized borders
```

## Typography System

### Hierarchy
```dart
displayLarge  // Hero titles (32-40px)
displayMedium // Large headings (28-32px)
displaySmall  // Section titles (24-28px)

headlineLarge  // Page titles (24px)
headlineMedium // Subsection titles (20px)
headlineSmall  // Card titles (18px)

titleLarge   // List item titles (18px)
titleMedium  // Navigation items (16px)
titleSmall   // Compact titles (14px)

bodyLarge    // Main content (16px)
bodyMedium   // Default text (14px)
bodySmall    // Helper text (12px)

labelLarge   // Button text (14px)
labelMedium  // Chip text (12px)
labelSmall   // Caption text (11px)
```

### Font Weights
```dart
FontWeight.w400  // Regular (body text)
FontWeight.w500  // Medium (labels, unselected items)
FontWeight.w600  // SemiBold (titles, selected items)
FontWeight.w700  // Bold (headings, emphasis)
FontWeight.w800  // ExtraBold (hero text)
```

## Spacing System (8dp Grid)

```dart
// Constants
const double spaceXs = 4.0;    // 4dp
const double spaceSm = 8.0;    // 8dp
const double spaceMd = 16.0;   // 16dp
const double spaceLg = 24.0;   // 24dp
const double spaceXl = 32.0;   // 32dp
const double space2xl = 48.0;  // 48dp
const double space3xl = 64.0;  // 64dp

// Usage Guidelines
- Component padding: 16-24px
- Section margins: 24-32px
- Card spacing: 12-16px
- Icon-text gap: 12-16px
- Button padding: 16-20px horizontal, 12-16px vertical
- List item height: 48-72px
```

## Border Radius System

```dart
// Standard radii
BorderRadius.circular(4)   // Chips, small elements
BorderRadius.circular(8)   // Small cards, inputs
BorderRadius.circular(12)  // List items, buttons
BorderRadius.circular(16)  // Medium cards
BorderRadius.circular(20)  // Action cards
BorderRadius.circular(24)  // Large cards, search bars
BorderRadius.circular(28)  // Hero sections
BorderRadius.circular(32)  // Extra large cards
```

## Card System

### Standard Card
```dart
Card(
  elevation: 0,
  color: scheme.surfaceContainerHigh,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(
      color: scheme.outlineVariant.withValues(alpha: 0.3),
    ),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: ...,
  ),
)
```

### Emphasized Card (with selection)
```dart
Card(
  elevation: 0,
  color: isSelected 
    ? scheme.secondaryContainer.withValues(alpha: 0.3)
    : scheme.surfaceContainerHigh,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(
      color: isSelected
        ? scheme.secondary.withValues(alpha: 0.5)
        : scheme.outlineVariant.withValues(alpha: 0.3),
      width: isSelected ? 2 : 1,
    ),
  ),
)
```

### List Item Card
```dart
Card(
  elevation: 0,
  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
  color: scheme.surfaceContainerHigh,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: InkWell(
    onTap: ...,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Row(...),
    ),
  ),
)
```

## Button System

### Primary Action
```dart
FilledButton.icon(
  onPressed: ...,
  icon: Icon(Icons.add),
  label: Text('Create Trip'),
  style: FilledButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  ),
)
```

### Secondary Action
```dart
FilledButton.tonalIcon(
  onPressed: ...,
  icon: Icon(Icons.edit),
  label: Text('Edit'),
)
```

### Tertiary Action
```dart
OutlinedButton.icon(
  onPressed: ...,
  icon: Icon(Icons.delete),
  label: Text('Delete'),
)
```

### Text Button
```dart
TextButton.icon(
  onPressed: ...,
  icon: Icon(Icons.close),
  label: Text('Cancel'),
)
```

## Icon System

### Sizes
```dart
18.0  // Small icons (inline with text)
20.0  // Default icons
24.0  // Navigation icons, standard buttons
28.0  // Large touch targets
32.0  // Hero icons, branding
```

### Colors
```dart
scheme.primary               // Primary actions
scheme.onPrimaryContainer    // Icons in primary containers
scheme.onSurface             // Default icons
scheme.onSurfaceVariant      // Secondary icons
scheme.error                 // Error/warning icons
```

## Input System

### Search Bar
```dart
SearchBar(
  hintText: 'Search...',
  leading: Padding(
    padding: EdgeInsets.only(left: 8),
    child: Icon(Icons.search),
  ),
  elevation: WidgetStatePropertyAll(0),
  backgroundColor: WidgetStatePropertyAll(
    scheme.surfaceContainerHigh,
  ),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  ),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 16),
  ),
)
```

### Text Field
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Destination',
    hintText: 'Where to?',
    prefixIcon: Icon(Icons.place),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: scheme.surfaceContainerHigh,
  ),
)
```

## Navigation System

### Sidebar Menu Item
```dart
InkWell(
  onTap: ...,
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: isSelected
        ? scheme.secondaryContainer.withValues(alpha: 0.5)
        : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          isSelected ? selectedIcon : icon,
          size: 24,
          color: isSelected
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),
)
```

## Animation System

### Durations
```dart
Duration.milliseconds(150)  // Quick feedback (ripples)
Duration.milliseconds(280)  // Standard transitions
Duration.milliseconds(320)  // Complex animations
Duration.milliseconds(500)  // Hero transitions
```

### Curves
```dart
Curves.easeOutCubic   // Enter animations
Curves.easeInCubic    // Exit animations
Curves.easeInOutCubic // Bidirectional
Curves.easeOutBack    // Playful enter
```

### Route Transitions
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 280),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
  child: KeyedSubtree(
    key: ValueKey(routePath),
    child: child,
  ),
)
```

## Accessibility Guidelines

### Touch Targets
- Minimum: 48x48dp
- Recommended: 56x56dp for primary actions
- Spacing between targets: 8dp minimum

### Contrast Ratios
- Body text: 4.5:1 minimum (WCAG AA)
- Large text: 3:1 minimum
- Interactive elements: 3:1 minimum

### Focus States
- Visible outline on keyboard focus
- Clear visual feedback
- Logical tab order

## Content Patterns

### Empty State
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.inbox_outlined,
        size: 64,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      SizedBox(height: 16),
      Text(
        'No items yet',
        style: theme.textTheme.titleLarge,
      ),
      SizedBox(height: 8),
      Text(
        'Get started by creating your first item',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      SizedBox(height: 24),
      FilledButton.icon(
        onPressed: ...,
        icon: Icon(Icons.add),
        label: Text('Create Item'),
      ),
    ],
  ),
)
```

### Loading State
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text(
        'Loading...',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    ],
  ),
)
```

### Error State
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.error_outline,
        size: 64,
        color: scheme.error,
      ),
      SizedBox(height: 16),
      Text(
        'Something went wrong',
        style: theme.textTheme.titleLarge,
      ),
      SizedBox(height: 8),
      Text(
        errorMessage,
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: retry,
        icon: Icon(Icons.refresh),
        label: Text('Try Again'),
      ),
    ],
  ),
)
```

## Page Templates

### Standard Page (Desktop/Tablet)
```dart
// In nav_shell, content is already wrapped properly
// Your page just needs to provide scrollable content
SingleChildScrollView(
  padding: EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Page header
      Text(
        'Page Title',
        style: theme.textTheme.headlineLarge,
      ),
      SizedBox(height: 24),
      // Content sections with spacing
      ...sections,
    ],
  ),
)
```

### Standard Page (Mobile)
```dart
// Uses existing ModernPageScaffold
ModernPageScaffold(
  showBackButton: true,
  hero: HeroWidget(),
  sections: [
    ModernSection(
      title: 'Section Title',
      subtitle: 'Description',
      icon: Icons.star,
      child: Content(),
    ),
  ],
)
```

## Implementation Checklist

For each screen update:
- [ ] Remove custom AppBar if using desktop layout
- [ ] Use consistent padding (24px on desktop, 16px on mobile)
- [ ] Apply surface container colors appropriately
- [ ] Use standardized card styles
- [ ] Implement proper spacing (8dp grid)
- [ ] Ensure minimum touch targets (48dp)
- [ ] Add proper border styling
- [ ] Use consistent border radius
- [ ] Apply typography hierarchy
- [ ] Test at mobile, tablet, and desktop sizes
- [ ] Verify color contrast ratios
- [ ] Check keyboard navigation
- [ ] Test with screen reader

## Priority Screens for Update

1. **Settings Screen** - User settings and preferences
2. **Explore Screen** - Destination browsing
3. **Trip Planning Screen** - Create new trips
4. **Trip Details Screen** - View trip information
5. **Bookings Screen** - Manage bookings
6. **Notifications Screen** - User notifications
7. **Profile Screen** - User profile management

## Notes

- Desktop layout already handles nav sidebar and top bar
- Mobile layout uses existing ModernPageScaffold
- Focus on content area design consistency
- All screens should work in both layouts
- Test responsiveness thoroughly
