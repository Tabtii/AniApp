package com.example.animeapp.data

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.example.animeapp.data.datamodels.AnimeData

import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.remote.ApiService
import com.example.animeapp.db.AnimeDatabase


class AppRepository(private val api: ApiService, private val db: AnimeDatabase) {

    val animeList = db.dao.getAllAnime()
    lateinit var apiAniList: List<AnimeData>
    suspend fun getAnimeList() {
        apiAniList = api.getAllAnime().data
        db.dao.insertFacts(apiAniList)
    }

}