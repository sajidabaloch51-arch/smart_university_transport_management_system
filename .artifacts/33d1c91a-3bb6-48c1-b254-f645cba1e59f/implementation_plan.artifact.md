# Fix Git Ignore and Clean Staging

The project is currently missing standard ignore patterns for Flutter and Android build artifacts. This causes Git to track temporary files in the `build/` and `.dart_tool/` directories, leading to unnecessary warnings and large, cluttered commits.

## Proposed Changes

### Project Root

#### [MODIFY] [.gitignore](file:///C:/Users/PC/AndroidStudioProjects/smart%20university%20transport%20management%20system/.gitignore)
Update the root `.gitignore` to include standard Flutter, Dart, and general IDE ignore patterns.

### Android Module

#### [MODIFY] [android/.gitignore](file:///C:/Users/PC/AndroidStudioProjects/smart%20university%20transport%20management%20system/android/.gitignore)
Update the Android-specific ignore file to ensure Android build artifacts are correctly excluded.

## Verification Plan

### Manual Verification
1.  Run `git reset` to clear the current staging area.
2.  Run `git add .` again and verify that the `build/` directory warnings no longer appear and that build files are not staged.
3.  Run `git status` to ensure only source files are being tracked.
