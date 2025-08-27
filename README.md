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