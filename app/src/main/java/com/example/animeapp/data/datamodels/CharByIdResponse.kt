package com.example.animeapp.data.datamodels

data class CharByIdResponse(
    val data: CharData
)

data class CharData(
    val about: String?,
    val anime: List<Anime>?,
    val favorites: Int?,
    val images: Images?,
    val mal_id: Int,
    val manga: List<Manga>?,
    val name: String?,
    val name_kanji: String?,
    val nicknames: List<String>?,
    val url: String?,
    val voices: List<Voice>?
)

data class Anime(
    val anime: AnimeX,
    val role: String
)


data class Manga(
    val manga: MangaData,
    val role: String
)

data class Voice(
    val language: String?,
    val person: Person?
)

data class AnimeX(
    val images: Images,
    val mal_id: Int,
    val title: String,
    val url: String
)