package com.example.animeapp.data.repo


import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.remote.ApiService
import com.example.animeapp.db.AnimeDatabase
import com.example.animeapp.util.Season
import com.example.animeapp.util.Year
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.withContext
import java.security.acl.Owner

private const val TAG = "REPOSITORY"
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
    private var aniData: AnimeInfo? = null
    val database = FirebaseDatabase.getInstance()
    val animeTableRef: DatabaseReference = database.getReference("/AnimeData")

    fun saveLikedAnimeData(animeData: AnimeData) {
        if (animeData.liked == true) {
            val animeDataKey = animeTableRef.push().key // Generieren Sie einen eindeutigen Schlüssel

            if (animeDataKey != null) {
                animeTableRef.child(animeDataKey).setValue(animeData)
            }
            Log.d(TAG,"$animeData")
        }
    }

    suspend fun getSeason(page: Int) {
        if (aniData == null) {
            aniData = api.getSeasonNow(page, limit)
            aniData!!.pagination?.let { db.dao.insertPaging(it) }
            db.dao.insertAnime(aniData!!.data)
        }

    }

    suspend fun getAnimeByID(id: Int): AnimeData {
        return withContext(Dispatchers.IO) {
            db.dao.getAnimeByID(id)
        }
    }

    suspend fun getAnimeLiked(): List<AnimeData> {
        return withContext(Dispatchers.IO) {
            db.dao.getAnimeLiked()
        }
    }

    suspend fun updateAnime(animeData: AnimeData) {
        db.dao.updateAnime(animeData)

    }

    fun getFirebaseAnimeData(): LiveData<List<AnimeData>> {
        val firebaseAnimeDataRef = animeTableRef // Verwenden Sie Ihre DatabaseReference hier
        val liveData = MutableLiveData<List<AnimeData>>()

        firebaseAnimeDataRef.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(dataSnapshot: DataSnapshot) {
                val animeDataList = mutableListOf<AnimeData>()
                for (snapshot in dataSnapshot.children) {
                    val animeData = snapshot.getValue(AnimeData::class.java)
                    animeData?.let { animeDataList.add(it) }
                }
                liveData.postValue(animeDataList)
            }

            override fun onCancelled(databaseError: DatabaseError) {
                // Handle Fehler hier
            }
        })

        return liveData
    }

}