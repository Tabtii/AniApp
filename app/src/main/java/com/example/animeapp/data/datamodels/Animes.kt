package com.example.animeapp.data.datamodels

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass


data class AnimeInfo(
    val pagination: Pagination?,
    val data: List<Data>
)



@JsonClass(generateAdapter = true)
data class AnimeData(
    @Json
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
    val licensors: List<Any>?,
    val mal_id: Int?,
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
) {
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
        null,
        null,
        null
    )
}




data class Aired(
    val from: String?,
    val to: String?,
    val prop: AiredProp?,
    val string: String?
){
    constructor() : this(
        null,
        null,
        null,
        null
    )
}

data class AiredProp(
    val from: AiredDate?,
    val to: AiredDate?
){
    constructor() : this(
        null,
        null,

    )
}

data class AiredDate(
    val day: Int?,
    val month: Int?,
    val year: Int?
){
    constructor() : this(
        null,
        null,
        null
    )
}

data class Broadcast(
    val day: String?,
    val time: String?,
    val timezone: String?,
    val string: String?
){
    // Argumentloser Konstruktor hinzufügen
    constructor() : this(
        null,
        null,
        null,
        null
    )
}

data class Producer(
    val mal_id: Int?,
    val type: String?,
    val name: String?,
    val url: String?
){
    constructor() : this(
        null,
        null,
        null,
        null
    )
}

data class Licensor(
    val mal_id: Int?,
    val type: String?,
    val name: String?,
    val url: String?
){
    constructor() : this(
        null,
        null,
        null,
        null
    )
}

data class Studio(
    val mal_id: Int?,
    val type: String?,
    val name: String?,
    val url: String?
){
    constructor() : this(
        null,
        null,
        null,
        null
    )
}

data class Trailer(
    val youtube_id: String?,
    val embed_url: String?,
    val images: TrailerImages?
) {
    constructor() : this(
        null,
        null,
        null

    )
}

data class TrailerImages(
    val image_url: String?,
    val small_image_url: String?,
    val medium_image_url: String?,
    val large_image_url: String?,
    val maximum_image_url: String?
) {    constructor() : this(
        null,
        null,
        null,
        null,
    null
    )
}



