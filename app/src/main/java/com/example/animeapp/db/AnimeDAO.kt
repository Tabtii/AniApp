package com.example.animeapp.db

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.animeapp.data.datamodels.AnimeData

@Dao
interface AnimeDAO {
    @Query("SELECT * FROM anime_table")
    fun getAllAnime(): LiveData<List<AnimeData>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    fun insertFacts(animeList: List<AnimeData>)
}