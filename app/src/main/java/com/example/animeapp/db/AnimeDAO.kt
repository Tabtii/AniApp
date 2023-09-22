package com.example.animeapp.db

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.data.datamodels.MangaData

@Dao
interface AnimeDAO {
    @Query("SELECT * FROM anime_table")
    fun getAllAnime(): LiveData<List<AnimeData>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertFacts(animeList: List<AnimeData>)

    @Query("SELECT * FROM char_table")
    fun getAllChar(): LiveData<List<Character>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertChars(charList: List<Character>)

    @Query("SELECT * FROM manga_table")
    fun getAllManga(): LiveData<List<MangaData>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertManga(charList: List<MangaData>)
}