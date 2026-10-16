# Android-Release für Google Play

Stand: Vorbereitung für den **internen Test**. Der Upload-Key gehört nie ins Repository.

## 1. Upload-Key einmalig erzeugen (lokal, von dir)

```
keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Datei und Passwörter sicher aufbewahren (Passwortmanager, Backup). Geht der Key verloren,
lässt sich der Upload-Key nur über den Play-Support zurücksetzen.
Bei „Play App Signing“ (Standard) behält Google den eigentlichen App-Signing-Key.

## 2a. Lokal bauen

`mobile/android/key.properties` anlegen (ist per `.gitignore` ausgeschlossen):

```
storeFile=upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Dann: `cd mobile && flutter build appbundle --release --dart-define-from-file=config/supabase.json`
Ergebnis: `mobile/build/app/outputs/bundle/release/app-release.aab`.

## 2b. In GitHub Actions bauen

Repository-Secrets setzen: `ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload.jks`),
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
Danach Workflow „Android release bundle“ manuell starten; das AAB liegt als Artefakt am Lauf.

## 3. Play Console

1. App anlegen (`com.tabtii.aniapp`), Standardsprache Deutsch.
2. Testing → Interner Test → Testerliste anlegen → neues Release → AAB hochladen.
3. App-Inhalt: Datenschutzerklärung-URL, Datensicherheit, Zielgruppe, Anzeigen (keine), Inhaltseinstufung.
4. Vor einem geschlossenen/öffentlichen Test: Platzhalter in `docs/PRIVACY.md` füllen und veröffentlichen.

`versionCode` kommt aus `pubspec.yaml` (`version: 0.5.0+15`); pro Upload die Zahl nach dem `+` erhöhen.
