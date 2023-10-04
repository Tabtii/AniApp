package com.example.animeapp.data.remote

import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.datamodels.CharacterData
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.data.datamodels.MangaInfo
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.AnimeData
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import retrofit2.Call
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query


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
    suspend fun getAllAnime(
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): AnimeInfo

    @GET("characters")
    suspend fun getAllCharacter(
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): CharacterData

    @GET("manga")
    suspend fun getAllManga(
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): MangaInfo

    @GET("seasons/now")
    suspend fun getSeasonNow(
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): AnimeInfo

    @GET("anime/{id}/full")
    suspend fun getAnimeFull(@Path("id") id: Int): AniByIdResponse

    @GET("anime/{id}/characters")
    suspend fun getAnimeCharacters(@Path("id") id: Int): Call<CharacterList>
}

object AnimeApi {
    val retrofitService: ApiService by lazy { retrofit.create(ApiService::class.java) }
}