# Splash Screen Feature

## Overview

A modern, animated splash screen has been added to the Flutter WebRTC demo application. The splash screen provides a professional introduction to the app with smooth animations and branding.

## Features

### Visual Design

- **Dark Theme**: Elegant dark gradient background (dark blue to black)
- **Animated Logo**: Video call icon with pulsing animation
- **Modern Typography**: Clean, readable text with proper spacing
- **Loading Indicator**: Circular progress indicator with smooth animation

### Animations

- **Fade-in Effect**: Smooth fade-in animation for all elements
- **Scale Animation**: Elastic scale animation for the main content
- **Pulse Effect**: Continuous pulsing animation for the logo
- **Gradient Background**: Subtle gradient animation

### Technical Implementation

- **Duration**: 3-second display time
- **Navigation**: Automatic transition to main app
- **Responsive**: Works on all screen sizes
- **Performance**: Optimized animations using AnimationController

## Files Modified

### New Files

- `lib/src/splash_screen.dart` - Main splash screen widget

### Modified Files

- `lib/main.dart` - Added splash screen routing and HomeScreen widget
- `android/app/src/main/res/drawable/launch_background.xml` - Updated Android launch background
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` - Updated iOS launch screen

## Usage

The splash screen automatically displays when the app starts and transitions to the main app after 3 seconds. No additional configuration is required.

## Customization

### Changing Duration

Modify the Timer duration in `splash_screen.dart`:

```dart
Timer(const Duration(seconds: 3), () {
  Navigator.of(context).pushReplacementNamed('/home');
});
```

### Changing Colors

Update the gradient colors in the Container decoration:

```dart
gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    const Color(0xFF2C3E50),
    const Color(0xFF34495E),
    const Color(0xFF1E1E1E),
  ],
),
```

### Changing Logo

Replace the Icon widget with your custom logo:

```dart
Icon(
  Icons.video_call, // Change this to your custom icon
  size: 60,
  color: Colors.white,
),
```

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Desktop (Windows, macOS, Linux)

## Dependencies

No additional dependencies were added. The splash screen uses only Flutter's built-in animation and UI components.
