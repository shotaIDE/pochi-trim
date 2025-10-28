# Strictly Necessary Rules

## Before Modifying Code

Before modifying code, be sure to do the following:

1. Review any relevant coding standards. Development standards are located here:

- [doc/coding-rule/](/doc/coding-rule/)

2. Review approximately five similar existing code snippets.

## After Modifying Code

After modifying code, be sure to do the following:

1. Apply the formatter. Execute the following command:

```bash
dart format path/to/your/file.dart
```

2. Apply linter auto-fixes. Execute the following command:

```bash
dart fix --apply
```

3. Be sure to check for linter and compiler warnings. Resolve any warnings.

4. Run unit tests and verify that all tests pass.

5. If necessary, revise the documentation.

6. Think of an appropriate commit message and commit.

# Architecture

This project is an iOS and Android application, including front-end and back-end code.

## Client app

`client/` is where you put the code for the iOS and Android client app written in Flutter.

- [`./android/`](/client/android/): Product code and project settings for Android
- [`./ios/`](/client/ios/): Product code and project settings for iOS
- [`./lib/`](/client/lib/): Product code common to all OS
  - [`./data/`](/client/lib/data/): Information storage and retrieval, and interaction with the OS layer
  - [`./definition/`](/client/lib/data/definition/): Common definitions used for information storage and retrieval, and interaction with the OS layer
  - [`./model/`](/client/lib/data/model/): Domain model. Place pure data structures that are not dependent on the UI, and UI-independent `Exception`, `Error`, etc.
  - [`./repository/`](/client/lib/data/repository/): Repository. Defines the process of retaining and retrieving information while abstracting the specific destination.
  - [`./service/`](/client/lib/data/service/): Service. Defines the connection to the OS and Firebase.
- [`./ui/`](/client/lib/ui/): Defines screen drawing and display logic.
  - [`./component/`](/client/lib/ui/component/): Defines UI components shared between screens.
  - [`./feature/`](/client/lib/ui/feature/): Screens and screen logic. There are subfolders for each category.
- [`./test/`](/client/test/): Unit tests, widget tests

In this app, Swift Package Manager (SPM) is enabled and used in conjunction with CocoaPods.

SPM is enabled in Flutter itself with the following command:

```bash
flutter config --enable-swift-package-manager
```

Since SPM is a beta feature, problems may occur during builds, etc.

In that case, troubleshoot by investigating any reported issues in Flutter or considering the possibility of an unknown problem.

## Infrastructure

`infra/` is where you put the infrastructure configuration and back-end code.
