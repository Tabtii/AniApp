package com.example.animeapp.data.repo


import android.os.Build
import androidx.annotation.RequiresApi
import androidx.lifecycle.LifecycleOwner
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.remote.ApiService
import com.example.animeapp.db.AnimeDatabase
import com.example.animeapp.util.Season
import com.example.animeapp.util.Year
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.withContext
import java.security.acl.Owner


@RequiresApi(Build.VERSION_CODES.O)
class AppRepository(private val api: ApiService, private val db: AnimeDatabase) {
    private var currentSeason = Season()
    private var year = Year()
    val animeList = db.dao.getAllAnime()
    val charList = db.dao.getAllChar()
    val mangaList = db.dao.getAllManga()
    val pageList = db.dao.getAllPaging()
    val seasonNow = db.dao.getSeasonNow(year, currentSeason)

    private val limit = 25
    private var aniData : AnimeInfo? = null


    suspend fun getSeason(page: Int) {
        if (aniData == null) {
            aniData = api.getSeasonNow(page, limit)
            aniData!!.pagination?.let { db.dao.insertPaging(it) }
            db.dao.insertAnime(aniData!!.data)
        }

    }
    suspend fun getNextPage(page :Int){
        db.dao.deleteAnime()
        db.dao.deletePage()
        aniData = api.getSeasonNow(page, limit)
        aniData!!.pagination?.let { db.dao.insertPaging(it) }
        db.dao.insertAnime(aniData!!.data)
    }


    suspend fun getAnimeByID(id: Int): AnimeData {
        return withContext(Dispatchers.IO) {
            db.dao.getAnimeByID(id)
        }
    }
}