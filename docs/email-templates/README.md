# E-Mail-Vorlagen (Deutsch) für Supabase Auth

Einfügen im Supabase-Dashboard unter **Authentication → Email Templates**. Pro Vorlage den
Betreff setzen und den Inhalt der HTML-Datei in das Feld „Message body“ kopieren.
Die Platzhalter (`{{ .ConfirmationURL }}`, `{{ .Token }}`, `{{ .Email }}`, `{{ .NewEmail }}`)
ersetzt Supabase selbst. Sie enthalten keine Geheimnisse.

| Supabase-Vorlage | Betreff | Datei |
|---|---|---|
| Confirm sign up | Bestätige deine E-Mail-Adresse für AniApp | `confirm-signup.html` |
| Reset password | Passwort für AniApp zurücksetzen | `reset-password.html` |
| Magic link | Dein Anmeldelink für AniApp | `magic-link.html` |
| Change email address | E-Mail-Adresse bei AniApp ändern | `change-email.html` |
| Reauthentication | Dein Bestätigungscode für AniApp | `reauthentication.html` |

Die Vorlage „Invite user“ wird nicht verwendet (Einladungen laufen über die App-Datenbank).
Nach dem Speichern einen Passwort-Reset in der App auslösen und die Mail prüfen.
