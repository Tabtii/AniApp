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
| Tenrai / MAL-Katalog | [Bedingungen §§ 3, 6](https://tenrai.org/terms), Antwort vom 12.10.2026 privat geprüft | API-Dienst auch kommerziell erlaubt; Inhaltsrechte ausdrücklich nicht erteilt | Teilfreigabe dokumentiert. MAL-Metadaten, Texte, News und Bilder bleiben separat zu klären; keine pauschale kommerzielle Inhaltsfreigabe. |
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
keine Verträge. Tenrai hat geantwortet; für die übrigen vier Anfragen ist hier
noch keine Freigabe dokumentiert. Private Korrespondenz und Kontoadressen
werden nicht in diesem öffentlichen Repository veröffentlicht.

## Nachprüfung nach der Tenrai-Antwort

Stand: 12.10.2026, nach Eingang der Antwort. Absender und Originalnachricht wurden
im bestehenden privaten Mail-Thread geprüft. Die vollständige Mail bleibt dort.

### API-Dienst und Inhalte getrennt

Tenrais [Dokumentation](https://api.tenrai.org/documentation) bezeichnet den
Katalog als MyAnimeList-Daten. [Bedingungen §§ 3, 5, 6](https://tenrai.org/terms)
erlauben persönliche/kommerzielle Anwendungen und anwendungseigene Caches unter
Beachtung technischer Grenzen und fremder Rechte. Ein konkurrierender öffentlicher
Rohdaten-Proxy benötigt eine eigene Zustimmung. Die Antwort bestätigt nur den
Dienstzugriff, keine Rechte an Drittinhalten. Quellenhinweise allein ersetzen
diese nicht. Dokumentierte öffentliche Limits: 120 Anfragen/Minute und 4/Sekunde;
bei 429 ist Retry-After zu beachten.

Das Live-Register enthält deshalb für `tenrai` jetzt `review_required` statt
`permission_requested` samt Erklärung der Teilfreigabe. Die drei Freigabeschalter
bleiben false: Sie bewerten die vollständige Inhaltsquelle, nicht bloß den
API-Dienst. Speicherung wurde zurückgelesen. Die bestehenden Testadapter werden
durch dieses Register nicht automatisch abgeschaltet.

### Tatsächliche Verwendung in AniApp

| Inhalt | Vorhandener Datenweg | Noch zu klärender Umfang |
| --- | --- | --- |
| Titel, MAL-ID, Genres, Episodenzahl, Score, Japan-Sendezeit | `catalog/providers.ts`: offizielles MAL bei konfigurierter Client-ID, sonst Tenrai | Katalog-/Datenbanknutzung, Cache, kommerzielles App-Modell; einzelne Fakten getrennt von Texten/Bildern bewerten |
| Inhaltsbeschreibung | MAL `synopsis` bzw. Tenrai-Katalog | Anzeige, Kürzung, Übersetzung und Offline-Speicherung |
| Poster | MAL `main_picture` / Tenrai `images` | Berechtigung für konkrete Artwork-Nutzung und ggf. weitere Rechteinhaber; eine Bild-URL ist kein Lizenznachweis |
| Englische News | Tenrai `/v1/news` → MAL-Original-URL; `content.ts:malNews` | Überschrift, kurzer Auszug und CDN-Vorschaubild jeweils gesondert |
| Kalender | Tenrai-Schedule plus getrennte Provider-/Dub-Belege | Japan-Sendezeit ist kein DE-/EN-Dub-Termin; Wiederverwendung der jeweiligen Anbieterquelle separat |

### MyAnimeList: konkrete Vertragsfragen

Das [API Agreement](https://myanimelist.net/static/apiagreement.html) wurde am
12.10.2026 direkt gelesen (angezeigte Fassung: 08.08.2019; Websuch-Abruf scheiterte,
normaler HTTP-Abruf gelang). Für den offiziellen API-Weg sind insbesondere relevant:

- § 1(h/i), § 3(a)(xiv): kommerzielle Anwendungen benötigen schriftliche
  Zustimmung. Bestimmte nicht störende Klick-/View-Anzeigen können unter die
  nichtkommerzielle Definition fallen; daraus folgt keine pauschale Freigabe
  für Premium-Abos oder unser geplantes Gesamtmodell.
- § 3(a)(xii): Bearbeitung/Übersetzung von MAL-Inhalten ausdrücklich klären.
- § 3(c/e): besondere Grenzen für serverseitig gespeicherte Nutzerinhalte;
  Lösch-/Änderungsaufforderungen grundsätzlich innerhalb von 24 Stunden umsetzen.
- § 4(b): Veröffentlichung und wesentliche Änderungen sind mitzuteilen;
  insbesondere neue Werbung oder Wechsel zum kommerziellen Modell.

Diese API-Vereinbarung ist nicht automatisch ein Lizenzvertrag für den Bezug
über Tenrai. Gerade diesen Unterschied sowie die Reichweite bei Bildern muss
MAL schriftlich bestätigen. Keine Zustimmung wurde aus Schweigen oder einem
Client-ID-Eintrag abgeleitet.

### Vorbereitete Anfrage an MyAnimeList — noch nicht versendet

Offizieller Weg laut API Agreement: [Customer Support](https://myanimelist.net/about.php?go=support).
Keine verifizierte separate Lizenz-E-Mail-Adresse ermittelt; keine Adresse geraten.

**Subject: AniApp — permission for catalogue content, images and future commercial use**

Hello MyAnimeList team,

I am developing AniApp, an Android/iOS Flutter anime companion, initially in
German and English, with watchlists, episode progress, sourced release dates and
linked news. Project: https://github.com/Tabtii/AniApp/tree/feature/anime-companion

Our prototype uses Tenrai's MAL catalogue fallback and supports your official
API when a project client ID is configured. Tenrai permits use of its API service
but explicitly does not license the underlying content.

Could you confirm whether AniApp may retrieve, display and cache the following,
and whether permission differs between the official API and Tenrai?
1. MAL identifiers, titles, genres, scores, episode counts and broadcast metadata.
2. Synopses, including shortened or translated versions.
3. Poster and news-preview images, distinguishing remote display from caching.
4. Linked news headlines and short excerpts, without full article republication.

We propose bounded on-demand catalogue caching up to 24 hours and hourly
incremental news/schedule updates, not a bulk mirror or public data-resale API.
Please specify attribution, refresh/deletion obligations and any third-party
permissions that remain necessary, especially for artwork and authored news.

Please distinguish the free testing phase from a possible later model with
optional paid convenience features, advertising or affiliate links. Does any
advertising-only option qualify under section 1(i), and what written approval
and application review are required for premium features and launch?

Please advise the correct licensing route and any free or low-volume option.
This is a non-binding enquiry, not acceptance of fees or a contract.

Thank you,
AniApp project

### Ausweichmöglichkeiten mit dokumentierter Rechtebasis

- [Wikidata](https://www.wikidata.org/wiki/Wikidata:Licensing): strukturierte
  Daten unter CC0 als Kandidat für Stammdaten und ID-Zuordnung. Nicht integriert;
  Abdeckung und exakte Staffelzuordnung noch zu prüfen. Verlinkte Bilder und
  Originalquellen übernehmen nicht automatisch CC0.
- [Wikimedia Commons](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia):
  Bilder einzeln anhand Dateiseite, Urheber, Lizenz und weiterer Rechte prüfen.
  Kein belegter vollständiger Ersatz für Anime-Poster.
- [TMDb FAQ](https://developer.themoviedb.org/docs/faq): kommerzielles Projekt
  benötigt entsprechende Klärung; TMDb beansprucht selbst kein Eigentum an den
  gelieferten Bildern/Daten. Die bereits versendete Anfrage zu Bildrechten bleibt
  daher relevant. Kein automatischer Wechsel als vermeintlich sichere Lösung.
- Eigene redaktionelle Kurztexte und einzeln belegte Kalenderangaben vermeiden
  die ungeprüfte Übernahme fremder Formulierungen. Der automatisierte Zugriff
  auf die jeweilige Quelle und etwaige Datenbankrechte bleiben separat zu prüfen.

## Weitere Quellen und Versandversuch — 12.10.2026 nachmittags

**MyAnimeList-Anfrage nicht versendet:** Der Projektinhaber hat den Versand
ausdrücklich beauftragt. Der offizielle Support-Link führt zu
https://help.myanimelist.net/hc/en-us/requests/new.
Die Sicherheitsrichtlinie des Cloud-Browsers hat den Seitenaufruf blockiert;
es erfolgte keine Formulareingabe und kein Versand. Kein Ausweichen auf
HTTP-Formular-POSTs, andere Browser oder geratene E-Mail-Adressen.
Der oben vorbereitete Text ist für die manuelle Einreichung durch den
Projektinhaber fertig. Eine Suche nach bereits versendeten MAL-Anfragen
ergab keinen Treffer. Dieser Status ist kein Warten auf eine MAL-Antwort.

### Kandidatenvergleich

| Quelle | Daten und Nutzen | Dokumentierte Bedingungen / Grenze | Entscheidung |
| --- | --- | --- | --- |
| [TVmaze API](https://www.tvmaze.com/api) | Serien, Staffeln, Folgen, TV-/Streaming-Kalender und externe IDs | Öffentliche API unter CC BY-SA; Attribution und ShareAlike beachten. [Administrator zur Bildnutzung](https://www.tvmaze.com/threads/6552/using-posters-and-data-from-tvmaze-api-on-a-commercial-website) empfiehlt direkte Bild-URLs; keine pauschale Rechtegarantie für jedes Artwork daraus ableiten. | Stärkster neuer Kandidat für Episoden-Metadaten; Datenherkunft getrennt halten und ShareAlike-Auswirkungen vor Zusammenführung prüfen. |
| [bangumi-data](https://github.com/bangumi-data/bangumi-data) | Anime-, Sende- und Website-Zuordnungen als JSON-Datensatz | Daten ausdrücklich CC BY 4.0 mit Quellenangabe; von bangumi/Archive und der Bangumi-API unterscheiden. Lizenz gilt nicht automatisch für Inhalte verlinkter Websites. | Ergänzung für Stammdaten/Zuordnung; aktuelle Season-Abdeckung vor Import messen. Kein belegter vollständiger Dub-Kalender. |
| [TheTVDB](https://thetvdb.com/api-information) | Serien- und Episoden-Metadaten | Aktuelle Preistabelle: unter USD 50.000 Unternehmensjahresumsatz kostenlos mit Attribution; Projekt-Key/konkrete Vertragsbedingungen erforderlich. [API-Bedingungen](https://thetvdb.com/tos) schließen Bild-, Trailer- und Programmrechte ausdrücklich aus. | Zweite Katalogoption, kein Ersatz für Artwork-Freigaben. Keine Registrierung oder kostenpflichtige Bestellung erfolgt. |
| [anime-offline-database](https://github.com/manami-project/anime-offline-database) | Historische Stammdaten und Zuordnungen verschiedener Anime-Datenbanken | ODbL 1.0 + DbCL 1.0, nicht pauschal CC0. Repository seit 04.07.2026 archiviert; dokumentierter Stand KW 27/2026. Vorgelagerte Inhalte separat bewerten. | Höchstens geprüfter Mapping-Startbestand; nicht als laufende Quelle für neue Seasons/Dubs einplanen. |
| [Crunchyroll News](https://www.crunchyroll.com/hi/news/about) | Mehrsprachige Originalankündigungen und RSS | Offizieller Kontakt für Partnerschaften: editorial@crunchyroll.com, Betreff PARTNERSHIP. RSS-Verfügbarkeit allein erlaubt keine beliebige Wiederveröffentlichung. | Bestehende Quelle; konkret Überschriften, Vorschaubilder und DE/EN-Terminextraktion klären. In diesem Schritt keine weitere Mail versendet. |
| [AnimeNachrichten](https://www.animenachrichten.de/impressum) | Zusätzliche deutsche Anime-/Streaming-News | Keine freie kommerzielle Wiederverwendungslizenz gefunden; Impressum verlangt für weitergehende Verwertung schriftliche Zustimmung. | Kein neuer freigegebener Adapter. |
| Anime News Network / Anime UK News | Kandidaten für englische News | Aktuelle Feed-/Wiederverwendungsbedingungen waren bei dieser Nachprüfung nicht ausreichend abrufbar. | Keine neue Freigabe behaupten; bestehende Einschränkungen bleiben bestehen. |

### TVmaze: Live-Stichprobe und Dub-Grenze

Am 12.10.2026 wurden vier öffentliche API-Abfragen durchgeführt:
- Suche nach One Piece: Anime-ID 1505, daneben unter anderem Live-Action-ID 46065.
  Ein Titelvergleich allein würde hier falsche Serien verbinden.
- Suche nach Frieren: Hauptserie ID 69956, zusätzlich ein eigener Kurzserien-Eintrag.
- `/shows/1505/alternatelists` und `/shows/69956/alternatelists`: beide leere Listen.

Laut [Alternate-Episode-Richtlinie](https://www.tvmaze.com/faq/40/alternate-episodes)
umfasst die Sprachpremiere ausdrücklich Untertitel **oder** Dub; die dort
dokumentierte Sprachoption ist Englisch. Daraus darf weder ein deutscher noch
ein englischer Dub ohne zusätzlichen Audiobeleg erzeugt werden. Diese zwei
Stichproben belegen keine allgemeine Vollständigkeit oder Abwesenheit von Dubs.

### Priorität für AniApp

1. TVmaze als ergänzende Episodenquelle evaluieren: exakte externe ID/Staffel-
   Zuordnung, Lizenz-/Attributionsfelder und gesonderte Datenherkunft.
2. bangumi-data und bereits recherchierte Wikidata-Daten für Katalogzuordnungen
   testen; Trefferquote und Aktualität statt nur Datenmenge messen.
3. Dub-Veröffentlichungen weiter nur aus sprach-, regions- und folgenbezogenen
   Originalbelegen übernehmen. Subtitel, Katalogsprache und Originalpremiere
   dürfen keinen Dub-Termin erzeugen.
4. News-Vorschauen nur im tatsächlich erlaubten Umfang übernehmen; originale
   Anbieterankündigungen und bestätigte Publisher-Freigaben priorisieren.

Alle neu genannten Quellen sind Recherchekandidaten, nicht bereits in die App
eingebaute oder pauschal freigegebene Integrationen. Es wurde kein Vertrag
angenommen, keine kostenpflichtige API aktiviert und kein zusätzlicher
Lizenzkontakt ohne passenden Versandauftrag angeschrieben.

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
