# AniApp — Android & iOS

The shared Flutter app is in [`mobile/`](mobile/). Version 0.3.4 adds keyless Kitsu detail metadata, images and trailer links, plus an own ADN News scraper serving short sourced previews through Supabase. It also corrects the One Piece weekly estimate using a reviewed publisher pause notice. Seasonal discovery, watchlists, multilingual dub observations, news previews and a season-independent calendar run on Android and iOS. TMDb and AniList adapters still require their [activation prerequisites](docs/DATA_SOURCES.md). See [setup and implementation status](docs/IMPLEMENTATION.md).

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
