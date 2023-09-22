package com.example.animeapp.db

import androidx.room.TypeConverter
import com.example.animeapp.data.datamodels.Aired
import com.example.animeapp.data.datamodels.Broadcast
import com.example.animeapp.data.datamodels.Genre
import com.example.animeapp.data.datamodels.Images
import com.example.animeapp.data.datamodels.Licensor
import com.example.animeapp.data.datamodels.Producer
import com.example.animeapp.data.datamodels.Studio
import com.example.animeapp.data.datamodels.Theme
import com.example.animeapp.data.datamodels.Title
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class Converters {
    //ImageConverter
    @TypeConverter
    fun fromImages(images: Images): String {
        return Gson().toJson(images)
    }

    @TypeConverter
    fun toImages(imagesJson: String): Images {
        return Gson().fromJson(imagesJson, Images::class.java)
    }

    //TitleConverter
    @TypeConverter
    fun fromTitleList(titleList: List<Title>?): String? {
        if (titleList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Title>>() {}.type
        return gson.toJson(titleList, type)
    }

    @TypeConverter
    fun toTitleList(titleListJson: String?): List<Title>? {
        if (titleListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Title>>() {}.type
        return gson.fromJson(titleListJson, type)
    }

    @TypeConverter
    fun fromStringList(stringList: List<String>?): String? {
        if (stringList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<String>>() {}.type
        return gson.toJson(stringList, type)
    }

    @TypeConverter
    fun toStringList(stringListJson: String?): List<String>? {
        if (stringListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<String>>() {}.type
        return gson.fromJson(stringListJson, type)
    }

    @TypeConverter
    fun fromAired(aired: Aired): String {
        val gson = Gson()
        return gson.toJson(aired)
    }

    @TypeConverter
    fun toAired(airedJson: String): Aired {
        val gson = Gson()
        return gson.fromJson(airedJson, Aired::class.java)
    }

    @TypeConverter
    fun fromBroadcast(broadcast: Broadcast): String {
        val gson = Gson()
        return gson.toJson(broadcast)
    }

    @TypeConverter
    fun toBroadcast(broadcastJson: String): Broadcast {
        val gson = Gson()
        return gson.fromJson(broadcastJson, Broadcast::class.java)
    }

    @TypeConverter
    fun fromProducerList(producerList: List<Producer>?): String? {
        if (producerList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Producer>>() {}.type
        return gson.toJson(producerList, type)
    }

    @TypeConverter
    fun toProducerList(producerListJson: String?): List<Producer>? {
        if (producerListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Producer>>() {}.type
        return gson.fromJson(producerListJson, type)
    }

    @TypeConverter
    fun fromLicensorList(licensorList: List<Licensor>?): String? {
        if (licensorList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Licensor>>() {}.type
        return gson.toJson(licensorList, type)
    }

    @TypeConverter
    fun toLicensorList(licensorListJson: String?): List<Licensor>? {
        if (licensorListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Licensor>>() {}.type
        return gson.fromJson(licensorListJson, type)
    }

    @TypeConverter
    fun fromStudioList(studioList: List<Studio>?): String? {
        if (studioList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Studio>>() {}.type
        return gson.toJson(studioList, type)
    }

    @TypeConverter
    fun toStudioList(studioListJson: String?): List<Studio>? {
        if (studioListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Studio>>() {}.type
        return gson.fromJson(studioListJson, type)
    }

    @TypeConverter
    fun fromGenreList(genreList: List<Genre>?): String? {
        if (genreList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Genre>>() {}.type
        return gson.toJson(genreList, type)
    }

    @TypeConverter
    fun toGenreList(genreListJson: String?): List<Genre>? {
        if (genreListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Genre>>() {}.type
        return gson.fromJson(genreListJson, type)
    }

    @TypeConverter
    fun fromObjectList(objectList: List<Any>?): String? {
        if (objectList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Any>>() {}.type
        return gson.toJson(objectList, type)
    }

    @TypeConverter
    fun toObjectList(objectListJson: String?): List<Any>? {
        if (objectListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Any>>() {}.type
        return gson.fromJson(objectListJson, type)
    }

    @TypeConverter
    fun fromThemeList(themeList: List<Theme>?): String? {
        if (themeList == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Theme>>() {}.type
        return gson.toJson(themeList, type)
    }

    @TypeConverter
    fun toThemeList(themeListJson: String?): List<Theme>? {
        if (themeListJson == null) {
            return null
        }
        val gson = Gson()
        val type = object : TypeToken<List<Theme>>() {}.type
        return gson.fromJson(themeListJson, type)
    }
}