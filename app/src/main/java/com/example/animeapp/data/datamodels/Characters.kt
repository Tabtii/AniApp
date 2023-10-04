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
    val about: String?,
    var liked: Boolean = false
)

data class CharacterList(
    val data: List<AnimeCharacter>
)
data class AnimeCharacter(
    val character: Character,
    val role: String,
    val favorites: Int,
    val voiceActors: List<VoiceActor>
)





data class Image(
    val imageUrl: String,
    val smallImageUrl: String? = null
)

data class VoiceActor(
    val person: Person,
    val language: String
)

data class Person(
    val malId: Int,
    val url: String,
    val images: PersonImages,
    val name: String
)

data class PersonImages(
    val jpg: Image
)





