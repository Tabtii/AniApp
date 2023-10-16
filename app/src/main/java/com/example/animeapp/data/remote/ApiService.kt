package com.example.animeapp.data.remote

import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.datamodels.CharacterData
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.data.datamodels.MangaInfo
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.AnimeCharacter
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.CharByIdResponse
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
        @Query("sfw") sfw : Boolean,
        @Query("unapproved")unapproved: Boolean,
        @Query("page") page: Int?,
        @Query("limit") limit: Int?,
        @Query("q") q: String?,
        @Query("type") type: String?,
        @Query("score") score: Double?,
        @Query("minScore") minScore: Double?,
        @Query("maxScore") maxScore: Double?,
        @Query("status") status: String?,
        @Query("rating") rating: String?,
        @Query("genres") genres: String?,
        @Query("genresExcluded") genresExcluded: String?,
        @Query("orderBy") orderBy: String?,
        @Query("sort") sort: String?,
        @Query("letter") letter: String?,
        @Query("producers") producers: String?,
        @Query("startDate") startDate: String?,
        @Query("endDate") endDate: String?
        ): AnimeInfo

    @GET("characters")
    suspend fun getAllCharacter(
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): CharacterData


    @GET("seasons/now")
    suspend fun getSeasonNow(
        @Query("sfw") sfw : Boolean,
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): AnimeInfo

    @GET ("seasons/{year}/{season}")
    suspend fun getSeasonByYear(
        @Path("year") year : Int,
        @Path("season") season: String,
        @Query("sfw") sfw : Boolean,
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): AnimeInfo

    @GET("anime/{id}/full")
    suspend fun getAnimeFull(@Path("id") id: Int): AniByIdResponse

    @GET("anime/{id}/characters")
    suspend fun getAnimeCharacters(@Path("id") id: Int): CharacterList

    @GET("characters/{id}/full")
    suspend fun  getCharactersFull(@Path("id")id: Int): CharByIdResponse


}

object AnimeApi {
    val retrofitService: ApiService by lazy { retrofit.create(ApiService::class.java) }
}