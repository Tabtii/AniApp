package com.example.animeapp.data.datamodels

data class CharacterData(
    val pagination: Pagination,
    val data: List<Character>
)


data class PaginationItems(
    val count: Int,
    val total: Int,
    val per_page: Int
)

data class Character(
    val mal_id: Int,
    val url: String,
    val images: Images,
    val name: String,
    val name_kanji: String,
    val nicknames: List<String>,
    val favorites: Int,
    val about: String
)




