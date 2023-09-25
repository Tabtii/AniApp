package com.example.animeapp.data.repo


import android.os.Build
import androidx.annotation.RequiresApi
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.remote.ApiService
import com.example.animeapp.db.AnimeDatabase
import com.example.animeapp.util.Season
import com.example.animeapp.util.Year
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext


@RequiresApi(Build.VERSION_CODES.O)
class AppRepository(private val api: ApiService, private val db: AnimeDatabase) {
    private var currentSeason = Season()
    private var year = Year()
    val animeList = db.dao.getAllAnime()
    val charList = db.dao.getAllChar()
    val mangaList = db.dao.getAllManga()
    val seasonNow = db.dao.getSeasonNow(year, currentSeason)



    suspend fun getSeason() {
        db.dao.insertFacts(api.getSeasonNow(1, 25).data)
    }
    suspend fun getAnimeByID(id : Int):AnimeData{
         return withContext(Dispatchers.IO) {
             db.dao.getAnimeByID(id)
         }
    }
}