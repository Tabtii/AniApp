package com.example.animeapp.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.example.animeapp.data.datamodels.AnimeData

@Database(entities = [AnimeData::class], version = 1)
@TypeConverters(Converters::class)
abstract class AnimeDatabase : RoomDatabase() {
    abstract val dao: AnimeDAO
}

private lateinit var INSTANCE: AnimeDatabase

fun getDatabase(context: Context): AnimeDatabase {

    synchronized(AnimeDatabase::class.java) {
        if (!::INSTANCE.isInitialized) {


            //Neue Datenbank Instanz erstellen
            INSTANCE = Room.databaseBuilder(
                context.applicationContext,
                AnimeDatabase::class.java,
                "anime_table"
            )
                .build()
        }

        return INSTANCE
    }

}