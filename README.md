# Sahaj

> Train steady.

Men's sexual wellness training app. Solo dev, zero budget, India-first.

Two source-of-truth docs in `docs/`:

- [`synthesis.md`](docs/synthesis.md) — product brief: thesis, twelve principles, MVP, pricing, validation.
- [`solo_dev_roadmap.md`](docs/solo_dev_roadmap.md) — build plan: stack, data model, content pipeline, phase-by-phase tasks.

Read both before touching code. Phase progress in [`docs/CHANGELOG.md`](docs/CHANGELOG.md).

## Stack

Flutter 3.35 · Riverpod · Drift · Hive CE · Firebase · RevenueCat · just_audio · Sentry · Mixpanel.
Android first. iOS deferred to Phase 2.

## Run

```sh
flutter pub get
flutter run
```

## Layout

```
lib/
  core/        theme, constants, utils, errors
  data/        models, repositories, datasources
  features/    one folder per feature
  shared/      widgets, hooks
  l10n/        ARB files
content/       articles + audio scripts (source-of-truth content)
tool/          dart/python scripts (content pipeline)
docs/          synthesis, roadmap, changelog
```

## Status

Phase 0 complete (2026-04-29). Phase 1 next: design system + showcase screen.
