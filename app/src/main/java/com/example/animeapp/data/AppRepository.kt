package com.example.animeapp.data


import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.data.remote.ApiService
import com.example.animeapp.db.AnimeDatabase


class AppRepository(private val api: ApiService, private val db: AnimeDatabase) {

    val animeList = db.dao.getAllAnime()
    lateinit var apiAniList: List<AnimeData>

    val charList = db.dao.getAllChar()
    lateinit var apiCharList: List<Character>

    suspend fun getAnimeList() {
        apiAniList = api.getAllAnime().data
        db.dao.insertFacts(apiAniList)
    }

    suspend fun getCharList(){
        apiCharList = api.getAllCharacter().data
        db.dao.insertChars(apiCharList)
    }

}