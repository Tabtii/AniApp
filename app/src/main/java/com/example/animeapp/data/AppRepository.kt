package com.example.animeapp.data


import android.util.Log

import com.example.animeapp.data.remote.ApiService
import com.example.animeapp.db.AnimeDatabase


class AppRepository(private val api: ApiService, private val db: AnimeDatabase) {

    var animeList = db.dao.getAllAnime()
    val charList = db.dao.getAllChar()
    val mangaList = db.dao.getAllManga()


    suspend fun getAnimeList() {

        if (animeList.value.isNullOrEmpty()) {
            Log.d("AppRepository", "$animeList")
            db.dao.insertFacts(api.getAllAnime().data)
        }
        animeList = db.dao.getAllAnime()
    }

    suspend fun getCharList(){
       if(charList.value.isNullOrEmpty()) {
           db.dao.insertChars(api.getAllCharacter().data)
       }
    }

    suspend fun getMangaList(){
        if(mangaList.value.isNullOrEmpty()) {
            db.dao.insertManga(api.getAllManga().data)
        }
    }

}