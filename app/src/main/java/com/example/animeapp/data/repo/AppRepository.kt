package com.example.animeapp.data.repo


import android.annotation.SuppressLint
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.Data
import com.example.animeapp.data.remote.ApiService
import com.google.firebase.auth.ktx.auth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import retrofit2.Response
import java.util.Objects


private const val TAG = "REPOSITORY"

@RequiresApi(Build.VERSION_CODES.O)
class AppRepository(private val api: ApiService) {
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
            animeTableRef.child(userID).child(mal_id).setValue(animeData)

        }
    }

    fun removeDislikedAnimeData(animeDataId: String, userId: String) {
        // Erstelle einen Verweis auf den Pfad, unter dem die Daten gespeichert sind
        val animeDataRef = animeTableRef.child(userId).child(animeDataId)

        // Lösche die Daten aus der Datenbank
        animeDataRef.removeValue()
    }

    suspend fun getCharList(aniID: Int): CharacterList? {
        return withContext(Dispatchers.IO) {
            try {
                val response: Response<CharacterList> = api.getAnimeCharacters(aniID).execute()
                if (response.isSuccessful) {
                    Log.d(TAG, "${response.body()}")
                    response.body()
                } else {
                    // Hier kannst du Fehlerbehandlung durchführen, z.B. Loggen oder eine Exception werfen
                    null
                }
            } catch (e: Exception) {
                // Hier kannst du Netzwerkfehler behandeln, z.B. Loggen oder eine Exception werfen
                null
            }
        }
    }

    suspend fun getSeason(page: Int): AnimeInfo? {
        return api.getSeasonNow(page, limit)

    }

    suspend fun getAnimeByID(id: Int): AniByIdResponse {
        return api.getAnimeFull(id)

    }


    fun getFirebaseAnimeData(): List<Data> {
        val animeDataRef: DatabaseReference = database.getReference("/users/$userID")
        val dataList: MutableList<Data> = ArrayList()

        animeDataRef.addListenerForSingleValueEvent(object : ValueEventListener {
            override fun onDataChange(dataSnapshot: DataSnapshot) {
                for (dataSnapshotChild in dataSnapshot.children) {
                    val data: Data? = dataSnapshotChild.getValue(Data::class.java)
                    if (data != null) {
                        dataList.add(data)
                    }
                }
            }

            override fun onCancelled(databaseError: DatabaseError) {
                // Handle database errors here
            }
        })

        // Wait for onDataChange to be called (asynchronously) and then return the list
        // Note: This is not the recommended way to do it, but it simplifies the code.
        // In a real application, you should handle this asynchronously.
        Thread.sleep(2000) // Wait for 2 seconds (adjust as needed)

        return dataList
    }
}