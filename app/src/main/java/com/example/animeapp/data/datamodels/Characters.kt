package com.example.animeapp.data.datamodels

import androidx.room.Entity
import androidx.room.PrimaryKey

data class CharacterData(
    val pagination: Pagination,
    val data: List<Character>
)



@Entity(tableName = "char_table")
data class Character(
    @PrimaryKey
    val mal_id: Int,
    val url: String,
    val images: Images,
    val name: String,
    val name_kanji: String?,
    val nicknames: List<String>?,
    val favorites: Int?,
    val about: String?
)




