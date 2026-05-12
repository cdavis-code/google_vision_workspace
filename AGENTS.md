# AGENTS.md

## Project overview

Melos-managed Dart monorepo for Google Vision API. Symlinked source material at `google_vision_workspace/` (points to `../google_vision_workspace`).

## Current structure

```
.
├── google_vision_workspace/  → ../google_vision_workspace  (source reference)
├── packages/
│   ├── google_vision/        — Core REST client library
│   ├── google_vision_cli/    — CLI tool (extracted from source)
│   └── google_vision_flutter/ — Flutter widget
├── pubspec.yaml              — Root workspace + Melos config
└── AGENTS.md
```

## Workspace commands

| Action | Command |
|--------|---------|
| Get deps | `melos run dep` |
| Analyze | `melos run analyze` |
| Format | `melos run format` |
| Build (codegen) | `melos run build` |
| Run CLI | `dart run vision` (from any package dir) or `dart run google_vision_cli:vision` |

## Package details

### `google_vision` (core)

- Entrypoint: `GoogleVision` singleton (`lib/src/google_vision_base.dart`)
- Auth: `withApiKey(key)`, `withJwt(credentialsJson)`, or `withGenerator(generator)`
- API via Retrofit: `ImagesClient` (`POST /v1/images:annotate`), `FilesClient` (`POST /v1/files:annotate`), `OAuthClient` (`POST /o/oauth2/token`)
- Image methods: `googleVision.image.labelDetection(...)`, `faceDetection`, `textDetection`, etc.
- File methods: `googleVision.file.labelDetection(...)` (uses `InputConfig` instead of `JsonImage`)
- HTTP via `dio` with optional `LoggyDioInterceptor`
- Codegen: `build_runner` + `json_serializable` (models) + `retrofit_generator` (API clients). Generated `.g.dart` files excluded from analysis.
- **No tests exist** in any package.
- Analysis: `package:lints`, excludes `lib/**.g.dart`
- Release: `grinder` + `publish_tools` via `tool/grind.dart`

### `google_vision_cli` (CLI)

- Entrypoint: `bin/vision.dart` (registered as `executables: vision: vision`)
- 7 commands: crop_hint, detect, highlight, safe_search, score, version, (helper base class)
- Depends on `google_vision` (core) via path dependency
- Key deps: `args`, `dio`, `image`, `loggy`

### `google_vision_flutter` (Flutter)

- Depends on `google_vision` via path dependency
- `withAsset()` loads JWT from Flutter asset bundle
- `flutter_image_converter` for image conversion
- Re-exports `package:google_vision` minus `Color | GoogleVision | JsonImage | InputConfig`

## Key packages used

- `retrofit` + `retrofit_generator` — API client interfaces
- `json_annotation` + `json_serializable` — model serialization
- `dio` — HTTP client
- `jose_plus` + `crypto_keys_plus` — JWT/Google auth
- `grinder` + `publish_tools` — release automation
- `flutter_loggy_dio` + `loggy` — logging
