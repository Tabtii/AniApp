# Datenrechte und Freigaben — 12. Oktober 2026

**Keine pauschale kommerzielle Freigabe.** Öffentliche Erreichbarkeit, ein API-Key,
robots.txt oder die Lizenz eines Scraper-Programms ersetzen keine Nutzungsrechte
an den gelieferten Daten, Texten und Bildern. Die bisherigen Live-Integrationen
sind ein Entwicklungsstand; ihre technische Funktion ist keine Rechtsfreigabe.

## Dokumentierte Grundlage und tatsächliche Anfragen

| Quelle | Nachweis / Ansprechpartner | Stand | Konsequenz |
| --- | --- | --- | --- |
| MyDubList JSON-Datensätze | [README / Lizenz](https://github.com/Joelis57/MyDubList#attribution--license) | CC BY 4.0 ausdrücklich dokumentiert; kommerzielle Nutzung der lizenzierten Datensätze möglich | Quellenname, Link, Lizenz und Änderungshinweis sind in der App vorhanden. Keine daraus abgeleitete Bilder-, Provider- oder Terminlizenz. |
| AniList | [Terms](https://docs.anilist.co/guide/terms-of-use), `contact@anilist.co` | Anfrage am 12.10.2026 über Gmail versendet; keine Zusage | Tracker-/Wettbewerbsregel ausdrücklich angesprochen. Die Umsatzgrenze hebt diese nicht auf. Adapter bleibt deaktiviert. |
| Tenrai / MAL-Katalog | [API-Dokumentation](https://api.tenrai.org/documentation), `contact@tenrai.org` | Anfrage am 12.10.2026 versendet; keine Zusage | API, Caching, Texte, Bilder, Monetarisierung und Rechte der vorgelagerten Quellen getrennt angefragt. |
| TMDb / JustWatch | [FAQ](https://developer.themoviedb.org/docs/faq), `sales@themoviedb.org` | Anfrage am 12.10.2026 versendet; keine Zusage | Nichtkommerzielle Bedingungen mit Attribution dokumentiert; Entwicklungsphase mit Monetarisierungsabsicht, Bilder und JustWatch separat klären. Keine Bestellung oder kostenpflichtige Lizenz angenommen. |
| Anime2You | [Impressum](https://www.anime2you.de/impressum/), `info@anime2you.de` | Anfrage am 12.10.2026 versendet; keine Zusage | Feed, Überschrift, kurze Vorschau, Bilder, automatischer Artikelabruf und strukturierte Dub-Sachangaben ausdrücklich getrennt angefragt. |
| AniNews | [Impressum](https://www.aninews.de/impressum/), `info@aninews.de` | Anfrage am 12.10.2026 versendet; keine Zusage | Gleicher genauer Nutzungsumfang wie Anime2You; kein Artikelvolltext in der App. |
| MyAnimeList direkt / Jikan | [API agreement](https://myanimelist.net/static/apiagreement.html), [Support](https://myanimelist.net/about.php?go=support) | Direkte projektspezifische Genehmigung offen; nicht als versendet markieren | Tenrai/Jikan umgehen keine Rechte der ursprünglichen Quelle. MAL-Bedingungen enthalten spezifische kommerzielle Regeln/Ausnahmen; das geplante Modell einzeln prüfen lassen. |
| AnimeSchedule | [API terms](https://animeschedule.net/api-terms-of-use), [Kontakt](https://animeschedule.net/contact) | Schriftliche Klärung offen; Kontaktseite hier zugriffsbeschränkt | Token allein genügt nicht. Kein Zugriff über interne Endpunkte oder fremde Credentials. |
| Crunchyroll DE/EN, ADN | [Crunchyroll](https://www.crunchyroll.com/tos), [ADN](https://animationdigitalnetwork.com/) | Feed-/Kalenderzugriff technisch vorhanden; Wiederverwendung und Monetarisierung nicht vollständig geklärt | Vor kommerziellem Start konkrete Freigabe für Abruf, Vorschauen, Bilder, Caching und abgeleitete Kalenderdaten einholen. |
| Kitsu | [API-Dokumentation](https://kitsu.docs.apiary.io/) | Öffentlich erreichbar; kommerzielle Inhaltsrechte offen | API-Verfügbarkeit nicht als Bilder-/Textlizenz ausgeben. |
| Anime News Network | [Feed-Bedingungen](https://www.animenewsnetwork.com/newsfeed/terms-of-use.php) | Bedingungen mit Attribution/registrierter URL; Mobile-/Backend-Weitergabe offen | Neuer Adapter bleibt gesperrt. |
| HIDIVE | [Offizielle Dub-News](https://news.hidive.com/dubs) | Wiederverwendungsrechte offen | Neuer Adapter bleibt gesperrt; englischer Artikel bedeutet keine Verfügbarkeit in jedem Land. |
| Netflix Tudum | [Offizielle Anime-Übersicht](https://www.netflix.com/tudum/articles/new-anime-shows-on-netflix), [Audio-Hilfe](https://help.netflix.com/en/node/101798) | Automatisierte Nutzung/Bilder offen | Neuer Adapter bleibt gesperrt; globale Premiere ist kein bestätigter Dub-Termin. |
| Joyn / ProSieben MAXX | [Anime-News](https://www.joyn.de/bts/themen/anime) | Automatisierte Nutzung/Bilder offen | Neuer Adapter bleibt gesperrt; TV- und Streamingrechte getrennt behandeln. Die frühere MAXX-Seite leitet jetzt zu Joyn weiter. |

Die fünf versendeten Nachrichten sind konkrete Informations- und Freigabeanfragen,
keine Verträge. Antworten stehen aus. Private Korrespondenz und Kontoadressen
werden nicht in diesem öffentlichen Repository veröffentlicht.

## Technische Umsetzung

- `source_rights` unterscheidet `review_required`, `permission_requested`,
  `approved` und `blocked`. Ein Versand setzt nur `permission_requested`.
- Die neuen offiziellen News-Adapter führen **vor** `approved` **und**
  `ingestion_enabled=true` keinerlei Abrufe aus. Bestehende Testintegrationen
  erhalten dadurch nicht rückwirkend eine Genehmigung.
- Neue Adapter veröffentlichen nach Freischaltung zunächst nur validierte
  Überschriften, Datum, Quellenname und Original-Link; keine Bilder oder kopierten
  Artikeltexte. Index-/Metadatenformate müssen bei Freischaltung erneut live
  geprüft werden. JS-only/gesperrte Seiten liefern einen Fehlerstatus.
- Es gibt keinen externen Firecrawl-Aufruf und keine kostenpflichtige Crawl-API
  in der Produktionspipeline. Grenzen: drei neue Artikelseiten pro Quelle/Lauf,
  Tagescache, feste Hosts/Pfade, robots-Prüfung, Zeit-/Größenlimits und Abbruch
  bei Sperren. Kein Login-/Paywall-/Anti-Bot-Umgehen.
- Quellenstatus ist öffentlich und enthält nur Zeitpunkt/Zustand/Prüfanzahl.
  Artikelbelege, Review-Verlauf, Abos und Mitteilungen sind geschützt.
- Vor einem kommerziellen Build müssen **alle tatsächlich verwendeten** Quellen
  im konkreten Umfang freigegeben sein. `source_rights` ist ein Register und kein
  automatisches Rechtsgutachten oder allgemeiner Abschalter aller Altadapter.

## Eine Zusage verarbeiten

1. Genaue erlaubte Inhalte, Länder, App-Modell, Gebühren, Laufzeit, Attribution,
   Cache-Fristen, Abruflimits und Bildrechte aus der Antwort festhalten.
2. Vollständigen Nachweis privat aufbewahren; im Register nur eine sachliche,
   nicht vertrauliche Zusammenfassung hinterlegen.
3. Erst nach Prüfung des konkreten Umfangs Status und einzelne Schalter ändern.
   Bei kostenpflichtigem Angebot zunächst ausdrückliche Budgetentscheidung des
   Projektinhabers einholen.
4. Betroffenen Adapter mit aktuellen realen Antworten überprüfen; Quelle bei
   Widerruf/Änderung deaktivieren und vorgeschriebene Löschungen durchführen.

## Monetarisierung

Premium-Komfortfunktionen, Werbung und Affiliate-Links bleiben bis zur passenden
Datenfreigabe sowie Store-/Datenschutzvorbereitung deaktiviert. Keine Zahlung,
kein Werbe-SDK und kein Tracking wurden eingebaut. Ein erster kostenfreier Test
ist nicht automatisch nichtkommerziell, wenn der Dienst bereits auf spätere
Einnahmen ausgerichtet ist — diese Frage ist ausdrücklich Teil der Anfragen.
