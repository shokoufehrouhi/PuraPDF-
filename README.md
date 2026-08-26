# PuraPDF

Cross-platform PDF toolkit built with Flutter — runs on iOS (iPhone/iPad), Android (mobile/tablet), and macOS from a single codebase.

## Features (planned — see roadmap)
Merge, split, compress, image↔PDF conversion, document scanning, digital signatures, page editing, encryption, watermarking, OCR (Pro), and Google Drive sync.

## Architecture

```
lib/
├── core/                  # theme, constants, error handling
├── data/                  # datasources, repositories
├── domain/                # entities, usecases (pure business logic)
├── presentation/          # UI + Riverpod state management
│   └── features/          # merge, split, compress, scan, drive_sync
└── main.dart
```

- **State management:** Riverpod
- **PDF processing:** on-device (no server dependency for core operations)
- **Platforms:** iOS, Android, macOS

## Getting started

```bash
flutter pub get
flutter run
```

## Status

Phase 0 (project scaffold) complete. See project roadmap docs for phased feature rollout.
