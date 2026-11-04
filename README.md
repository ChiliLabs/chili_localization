# Chili Localization SDK for Flutter

## How to implement

1. Add dependency to pubspec.yaml

```agsl
  chili_localization:
    git:
      url: https://github.com/ChiliLabs/chili_localization.git
      ref: main
```

2. main.dart -> add these lines in bootstrap

```dart
void main() async {
  await bootstrap(() async {
      await configureDependencies();
      RemoteLocalizationClient.init(remoteTranslationsUrl: EnvConfig.localizationUrl);
      
      return App.withBloc(
        enableDebugView: EnvConfig.enableDebugView,
      );
  });
}
```

3. Somewhere in app_bloc on app launch call this

```dart
final currentTranslationsVersion = await _statsRepository.localTranslationsVersion ?? 0;
final remoteTranslationsVersion = await _remoteConfigRepository.remoteTranslationsVersion;
await RemoteLocalizationClient.loadTranslations(
    currentVersion: currentTranslationsVersion,
    remoteVersion: remoteTranslationsVersion,
    onAppliedNewVersion: (newVersion) async {
      await _statsRepository.setRemoteTranslationsVersion(newVersion);
    },
);
```

3. In you run_clean.sh scrip add this line at the end. First argument is input of the arb file, second argument is output dart file


```bash
flutter pub run chili_localization:gen resources/translations/app_en.arb lib/generated/translations/remote_fallback_localization.dart
```

4. Push new ARB keys to the Localization Service (optional)

A project admin generates an SDK API key in the Localization Service under Settings → SDK API key. It is shown once, so store it as a secret (for example a CI environment variable).

```bash
export CHILI_LOCALIZATION_API_KEY=<key>
dart run chili_localization:push --project <project id> --arb-dir resources/translations --dry-run
dart run chili_localization:push --project <project id> --arb-dir resources/translations
```

- Only keys that do not exist in the project yet are added. Existing keys are never changed or deleted.
- `@key.description` becomes the key's comment.
- ARB files for languages the project does not support are skipped with a warning.
- `--dry-run` prints the keys that would be added without writing anything.
- Pushing does not publish a new translations version; publish from the Localization Service as before.

## How it works

- When `RemoteLocalizationClient.loadTranslations` is called it checks if there is a new version of translations on the server with provided versions
- If new version is available, app fetches the translations from the server and saves them to local storage file
  - If failed to download, local file with translations will be used
    - If local file does not exists, local translations will be used
- If there is no new version, app will use local file if exists, otherwise local translations
