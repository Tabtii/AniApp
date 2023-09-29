package com.example.animeapp.data.datamodels

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Relation


data class AnimeInfo(
    val pagination: Pagination?,
    val data: List<AnimeData>
)



@Entity(tableName = "anime_table")
data class AnimeData(
    @PrimaryKey
    val mal_id: Int,
    val url: String?,
    val images: Images?,
    val trailer: Trailer?,
    val approved: Boolean?,
    val titles: List<Title>?,
    val title: String?,
    val title_english: String?,
    val title_japanese: String?,
    val title_synonyms: List<String>?,
    val type: String?,
    val source: String?,
    val episodes: Int?,
    val status: String?,
    val airing: Boolean?,
    val aired: Aired?,
    val duration: String?,
    val rating: String?,
    val score: Double?,
    val scored_by: Int?,
    val rank: Int?,
    val popularity: Int?,
    val members: Int?,
    val favorites: Int?,
    val synopsis: String?,
    val background: String?,
    val season: String?,
    val year: Int?,
    val broadcast: Broadcast?,
    val producers: List<Producer>?,
    val licensors: List<Licensor>?,
    val studios: List<Studio>?,
    val genres: List<Genre>?,
    val explicit_genres: List<Any>?,
    val themes: List<Theme>?,
    val demographics: List<Any>?,
    var liked: Boolean = false
)




data class Aired(
    val from: String?,
    val to: String?,
    val prop: AiredProp?,
    val string: String?
)

data class AiredProp(
    val from: AiredDate?,
    val to: AiredDate?
)

data class AiredDate(
    val day: Int?,
    val month: Int?,
    val year: Int?
)

data class Broadcast(
    val day: String?,
    val time: String?,
    val timezone: String?,
    val string: String?
)

data class Producer(
    val mal_id: Int,
    val type: String,
    val name: String,
    val url: String
)

data class Licensor(
    val mal_id: Int,
    val type: String,
    val name: String,
    val url: String
)

data class Studio(
    val mal_id: Int,
    val type: String,
    val name: String,
    val url: String
)

data class Trailer(
    val youtube_id: String?,
    val embed_url: String?,
    val images: TrailerImages?
)

data class TrailerImages(
    val image_url: String?,
    val small_image_url: String?,
    val medium_image_url: String?,
    val large_image_url: String?,
    val maximum_image_url: String?
)



