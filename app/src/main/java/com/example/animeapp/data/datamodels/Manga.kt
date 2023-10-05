package com.example.animeapp.data.datamodels

import androidx.room.Entity
import androidx.room.PrimaryKey

data class MangaInfo(
    val data: List<MangaData>
)
@Entity(tableName = "manga_table")
data class MangaData(
    @PrimaryKey
    val mal_id: Int,
    val url: String?,
    val images: Images?,
    val approved: Boolean?,
    val titles: List<Title>?,
    val title: String?,
    val title_english: String?,
    val title_japanese: String?,
    val title_synonyms: List<String>?,
    val type: String?,
    val chapters: Int?,
    val volumes: Int?,
    val status: String?,
    val publishing: Boolean?,
    val published: Published?,
    val score: Double?,
    val scored_by: Int?,
    val rank: Int?,
    val popularity: Int?,
    val members: Int?,
    val favorites: Int?,
    val synopsis: String?,
    val background: String?,
    val authors: List<Author>?,
    val serializations: List<Serialization>?,
    val genres: List<Genre>?,
    val explicit_genres: List<Any>?,
    val themes: List<Theme>?,
    val demographics: List<Demographic>?,
    var liked: Boolean = false

)





data class Published(
    val from: String?,
    val to: String?,
    val prop: PublishedProp?,
    val string: String?
)

data class PublishedProp(
    val from: PublishedDate?,
    val to: PublishedDate?
)

data class PublishedDate(
    val day: Int?,
    val month: Int?,
    val year: Int?
)

data class Author(
    val mal_id: Int?,
    val type: String?,
    val name: String?,
    val url: String?
)

data class Serialization(
    val mal_id: Int?,
    val type: String?,
    val name: String?,
    val url: String?
)





data class Demographic(
    val mal_id: Int?,
    val type: String?,
    val name: String?,
    val url: String?
){constructor(): this(
    null,
    null,
    null,
    null
)}
