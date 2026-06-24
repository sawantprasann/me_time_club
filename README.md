# Me Time Club

Me Time Club — Your daily sanctuary. A wellness app for mothers.

---

## Prerequisites

Before running the application, make sure you have the following installed and configured:

- **Flutter SDK** (`^3.7.2` or later)
- **Dart SDK** (bundled with Flutter)
- **Xcode** (required for iOS simulator/device execution on macOS)
- **Android Studio & SDK** (required for Android emulator/device execution)

Verify your environment setup by running:
```bash
flutter doctor
```

## Getting Started & Setup

Follow these steps to run the application on your machine:

1. **Install Dependencies**
   Navigate to the project root directory and fetch the packages:
   ```bash
   flutter pub get
   ```

2. **Run the Application**
   - **Using the CLI:**
     Ensure you have a simulator/emulator running or a physical device connected. Then execute:
     ```bash
     flutter run
     ```
     If you have multiple devices connected, specify the device ID:
     ```bash
     flutter run -d <device-id>
     ```
     To list all available devices, run:
     ```bash
     flutter devices
     ```

   - **Using an IDE (VS Code / Android Studio):**
     - Open the project root folder in your IDE.
     - Ensure you have the **Flutter** and **Dart** extensions installed.
     - Select your target device from the status bar/device menu.
     - Press `F5` or click the green **Run** button to launch in debug mode.

## Development & Utility Commands

Here are some useful commands for code quality and testing:

- **Check Code Quality (Linting & Analysis):**
  ```bash
  flutter analyze
  ```

- **Run Tests:**
  ```bash
  flutter test
  ```

- **Format Code:**
  ```bash
  dart format .
  ```

---

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.
