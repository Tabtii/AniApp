package com.example.animeapp.data.repo


import android.annotation.SuppressLint
import android.os.Build
import androidx.annotation.RequiresApi
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.CharByIdResponse
import com.example.animeapp.data.remote.ApiService
import com.google.firebase.auth.ktx.auth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import com.google.firebase.ktx.Firebase
import retrofit2.http.Query
import java.time.Year


private const val TAG = "REPOSITORY"

@RequiresApi(Build.VERSION_CODES.O)
class AppRepository(private val api: ApiService) {
    private val unapproved = true
    private val sfw = true
    private val limit = 25
    private val database =
        FirebaseDatabase.getInstance("https://animeapp-d1c31-default-rtdb.europe-west1.firebasedatabase.app")
    private val animeTableRef: DatabaseReference = database.getReference("/users")
    private val userID = Firebase.auth.currentUser?.uid!!

    @SuppressLint("SuspiciousIndentation")
    fun saveLikedAnimeData(animeData: AniByIdResponse) {
        if (animeData.data?.like == true) {
            val mal_id = animeData.data?.mal_id.toString()
            // Speichere die Daten unter dem Pfad "users/{userId}/{animeDataKey}"
            animeTableRef.child(userID).child((mal_id)).setValue(animeData)

        }
    }

    fun removeDislikedAnimeData(animeDataId: String, userId: String) {
        // Erstelle einen Verweis auf den Pfad, unter dem die Daten gespeichert sind
        val animeDataRef = animeTableRef.child(userId).child(animeDataId)

        // Lösche die Daten aus der Datenbank
        animeDataRef.removeValue()
    }

    suspend fun getCharList(aniID: Int): CharacterList? {
        return api.getAnimeCharacters(aniID)
    }


    suspend fun getSeasonByYear(year: Int,season: String,page: Int): AnimeInfo?{
        return api.getSeasonByYear(year, season, sfw, page, limit)
    }

   suspend fun getAllAnime(

       page: Int,
       q: String?,
       type: String?,
       score: Double?,
       minScore: Double?,
       maxScore: Double?,
       status: String?,
       rating: String?,
       genres: String?,
       genresExcluded: String?,
       orderBy: String?,
       sort: String?,
       letter: String?,
       producers: String?,
       startDate: String?,
       endDate: String?
    ): AnimeInfo {

        return api.getAllAnime(
            sfw,
            unapproved,
            page,
            limit,
            q,
            type,
            score,
            minScore,
            maxScore,
            status,
            rating,
            genres,
            genresExcluded,
            orderBy,
            sort,
            letter,
            producers,
            startDate,
            endDate
        )


    }


    suspend fun getAnimeByID(id: Int): AniByIdResponse {
        return api.getAnimeFull(id)
    }

    suspend fun getCharByID(id: Int): CharByIdResponse {
        return api.getCharactersFull(id)
    }


    fun getFirebaseAnimeData(): List<AniByIdResponse> {
        val animeDataRef: DatabaseReference = database.getReference("/users/$userID")
        val dataList: MutableList<AniByIdResponse> = ArrayList()

        animeDataRef.addListenerForSingleValueEvent(object : ValueEventListener {
            override fun onDataChange(dataSnapshot: DataSnapshot) {
                for (dataSnapshotChild in dataSnapshot.children) {
                    val data: AniByIdResponse? =
                        dataSnapshotChild.getValue(AniByIdResponse::class.java)
                    if (data != null) {
                        dataList.add(data)
                    }
                }
            }

            override fun onCancelled(databaseError: DatabaseError) {
            }
        })

        Thread.sleep(100)

        return dataList
    }
}