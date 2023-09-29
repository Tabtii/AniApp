package com.example.animeapp.db

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.data.datamodels.MangaData
import com.example.animeapp.data.datamodels.Pagination

@Dao
interface AnimeDAO {
    @Query("SELECT * FROM anime_table")
    fun getAllAnime(): LiveData<List<AnimeData>>

    @Query("SELECT * FROM anime_table WHERE mal_id = :id")
    fun getAnimeByID(id: Int): AnimeData

    @Query("SELECT * FROM anime_table WHERE liked = 1")
    fun getAnimeLiked(): List<AnimeData>
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAnime(animeList: List<AnimeData>)
    @Update
    fun updateAnime(animeData: AnimeData)
    @Query("DELETE FROM anime_table")
    fun deleteAnime()
    @Query("SELECT * FROM char_table")
    fun getAllChar(): LiveData<List<Character>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertChars(charList: List<Character>)

    @Query("SELECT * FROM manga_table")
    fun getAllManga(): LiveData<List<MangaData>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertManga(mangaList: List<MangaData>)

    @Query("SELECT * FROM anime_table WHERE year = :year AND season = :currentSeason")
    fun getSeasonNow(year: Int,currentSeason: String): LiveData<List<AnimeData>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertSeasonNow(seasonList: List<AnimeData>)

    @Query("SELECT * FROM paging_table")
    fun getAllPaging(): LiveData<Pagination>
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertPaging(page: Pagination)

    @Query("DELETE FROM paging_table")
    fun deletePage()

}