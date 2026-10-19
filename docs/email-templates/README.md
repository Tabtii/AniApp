# E-Mail-Vorlagen (Deutsch/Englisch) für Supabase Auth

Einfügen im Supabase-Dashboard unter **Authentication → Email Templates**. Pro Vorlage den
Betreff setzen und den Inhalt der HTML-Datei in das Feld „Message body“ kopieren.
Jede Vorlage ist zweisprachig (Deutsch oben, Englisch darunter), weil Supabase pro Vorlage nur einen Text verschickt.
Die Platzhalter (`{{ .ConfirmationURL }}`, `{{ .Token }}`, `{{ .Email }}`, `{{ .NewEmail }}`)
ersetzt Supabase selbst. Sie enthalten keine Geheimnisse.

| Supabase-Vorlage | Betreff | Datei |
|---|---|---|
| Confirm sign up | Bestätige deine E-Mail-Adresse / Confirm your email – AniApp | `confirm-signup.html` |
| Reset password | Passwort zurücksetzen / Reset your password – AniApp | `reset-password.html` |
| Magic link | Dein Anmeldelink / Your sign-in link – AniApp | `magic-link.html` |
| Change email address | E-Mail-Adresse ändern / Change your email – AniApp | `change-email.html` |
| Reauthentication | Bestätigungscode / Confirmation code – AniApp | `reauthentication.html` |

Die Vorlage „Invite user“ wird nicht verwendet (Einladungen laufen über die App-Datenbank).
Nach dem Speichern einen Passwort-Reset in der App auslösen und die Mail prüfen.
