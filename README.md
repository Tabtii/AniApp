# AniApp — Android & iOS

The new shared Flutter app is in [`mobile/`](mobile/). Version 0.3.3 adds MyDubList language observations and prepared TMDb/JustWatch and AniList adapters (see [activation requirements](docs/DATA_SOURCES.md)), alongside a season-independent provider calendar, automatically refreshed ADN episode dates and reviewed Netflix/aniverse slots, plus a custom AniApp mark and sourced dub-announcement details alongside a cover-led discovery screen, real news image previews, a poster timeline, and a refreshed light/dark design. It includes seasonal discovery, watchlists and the Supabase integration for news, release dates and language availability. See [setup and implementation status](docs/IMPLEMENTATION.md).

The original Kotlin application below remains as a historical training reference.

# AniMe

Keep track of current and past anime and add your favorites to a list. You will also find information about the animes and their characters.
This is a training project for Syntax Institute, it is not intended to publish the app.

<p align="center">
<img height="300" src="Screenshot_20231113_112516.png">
<img height="300" src="Screenshot_20231113_112540.png">
<img height="300" src="Screenshot_20231113_112557.png">
<img height="300" src="Screenshot_20231113_112618.png">
<img height="300" src="Screenshot_20231113_112634.png">
<p />

## Features

*Animes of the current and old seasons

*Information on genre, number of episodes, first broadcast and characters and their voice actors

*Create a list of your favorite anime

## Features that are still missing

*Detailed view of the voice actors 

*Character and Manga Search 

*More filter options


Live content (0.2.4): hourly free RSS/API news from Anime2You and MyAnimeList/Tenrai, an automatically refreshed Japanese broadcast calendar, and dated provider-verified language observations. All displayed production content comes from real sources. See [implementation details and coverage](docs/IMPLEMENTATION.md).
