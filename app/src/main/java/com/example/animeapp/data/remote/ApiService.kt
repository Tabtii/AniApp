package com.example.animeapp.data.remote

import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.datamodels.CharacterData
import com.example.animeapp.data.datamodels.MangaData
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET


// Die Konstante enthält die URL der API
const val BASE_URL = "https://api.jikan.moe/v4/"

// Moshi konvertiert Serverantworten in Kotlin Objekte
private val moshi = Moshi.Builder()
    .add(KotlinJsonAdapterFactory())
    .build()

// Retrofit übernimmt die Kommunikation und übersetzt die Antwort
private val retrofit = Retrofit.Builder()
    .addConverterFactory(MoshiConverterFactory.create(moshi))
    .baseUrl(BASE_URL)
    .build()

// Das Interface bestimmt, wie mit dem Server kommuniziert wird
interface ApiService {


    @GET("anime")
    suspend fun getAllAnime() : AnimeInfo

    @GET("characters")
    suspend fun getAllCharacter() : CharacterData

    @GET("manga")
    suspend fun getAllManga() : MangaData
}
object AnimeApi {
    val retrofitService: ApiService by lazy { retrofit.create(ApiService::class.java) }
}