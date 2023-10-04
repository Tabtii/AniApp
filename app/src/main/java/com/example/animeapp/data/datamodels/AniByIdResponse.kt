package com.example.animeapp.data.datamodels

data class AniByIdResponse(
    val data: Data?
)

data class Data(
    val aired: Aired?,
    val airing: Boolean?,
    val approved: Boolean?,
    val background: Any?,
    val broadcast: Broadcast?,
    val demographics: List<Demographic>?,
    val duration: String?,
    val episodes: Any?,
    val explicit_genres: List<Any>?,
    val `external`: List<External>?,
    val favorites: Int?,
    val genres: List<Genre>?,
    val images: Images?,
    var key: String = "",
    val licensors: List<Any>?,
    var like: Boolean = false,
    var mal_id: Int,
    val members: Int?,
    val popularity: Int?,
    val producers: List<Producer>?,
    val rank: Any?,
    val rating: String?,
    val relations: List<Relation>?,
    val score: Any?,
    val scored_by: Any?,
    val season: String?,
    val source: String?,
    val status: String?,
    val streaming: List<Any>?,
    val studios: List<Studio>?,
    val synopsis: String?,
    val theme: Theme?,
    val themes: List<Theme>?,
    val title: String?,
    val title_english: Any?,
    val title_japanese: String?,
    val title_synonyms: List<Any>?,
    val titles: List<Title>?,
    val trailer: Trailer?,
    val type: String?,
    val url: String?,
    val year: Int?
){
    constructor() : this(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        "",
        null,
        like = false,
        0,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
    )
}



data class External(
    val name: String?,
    val url: String?
)


data class Relation(
    val entry: List<Entry?>?,
    val relation: String?
)


data class Prop(
    val from: From?,
    val to: To?
)

data class From(
    val day: Int?,
    val month: Int?,
    val year: Int?
)

data class To(
    val day: Any?,
    val month: Any?,
    val year: Any?
)

data class Jpg(
    val image_url: String?,
    val large_image_url: String?,
    val small_image_url: String?
)

data class Webp(
    val image_url: String?,
    val large_image_url: String?,
    val small_image_url: String?
)

data class Entry(
    val mal_id: Int?,
    val name: String?,
    val type: String?,
    val url: String?
)

data class ImagesX(
    val image_url: String?,
    val large_image_url: String?,
    val maximum_image_url: String?,
    val medium_image_url: String?,
    val small_image_url: String?
)