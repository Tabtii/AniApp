package com.example.animeapp.data.datamodels

import androidx.room.Entity
import androidx.room.PrimaryKey

data class Title(
    val type: String,
    val title: String
)


data class Theme(
    val mal_id: Int,
    val type: String,
    val name: String,
    val url: String
)

@Entity(tableName = "paging_table")
data class Pagination(
    @PrimaryKey(autoGenerate = true)
    val id : Long = 1,
    val last_visible_page: Int,
    val has_next_page: Boolean,
    val current_page: Int,
    val items: Items
)

data class PaginationItems(
    val count: Int,
    val total: Int,
    val per_page: Int
)

data class ImageInfo(
    val image_url: String,
    val small_image_url: String? = null
)

data class Images(
    val jpg: ImageInfo,
    val webp: ImageInfo
)

data class Genre(
    val mal_id: Int,
    val type: String,
    val name: String,
    val url: String
)

data class Items(
    val count: Int,
    val total: Int,
    val per_page: Int
)
