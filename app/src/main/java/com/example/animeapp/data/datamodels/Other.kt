package com.example.animeapp.data.datamodels

import androidx.room.Entity
import androidx.room.PrimaryKey

data class Title(
    val type: String?,
    val title: String?
){
    constructor() : this(
        null,
        null,

    )
}


data class Theme(
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

@Entity(tableName = "paging_table")
data class Pagination(
    @PrimaryKey
    val current_page: Int?,
    val last_visible_page: Int?,
    val has_next_page: Boolean?,
    val items: Items?
)

data class PaginationItems(
    val count: Int,
    val total: Int,
    val per_page: Int
)

data class ImageInfo(
    val image_url: String?,
    val small_image_url: String? = null
){
    constructor() : this(
        null,
        null,

    )
}

data class Images(
    val jpg: ImageInfo?,
    val webp: ImageInfo?
){
    constructor() : this(
        null,
        null

    )
}

data class Genre(
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

data class Items(
    val count: Int,
    val total: Int,
    val per_page: Int
)
