package com.example.animeapp.ui.viewmodel

import android.app.Application
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.example.animeapp.data.repo.AppRepository
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.CharByIdResponse
import com.example.animeapp.data.remote.AnimeApi
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase


import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val TAG = "MAINVIEWMODEL"

@RequiresApi(Build.VERSION_CODES.O)
class MainViewmodel(app: Application) : AndroidViewModel(app) {

    private val repository = AppRepository(AnimeApi.retrofitService)


    private val _seasonNow = MutableLiveData<AnimeInfo?>()
    val seasonNow: LiveData<AnimeInfo?> = _seasonNow
    private val _aniDetail = MutableLiveData<AniByIdResponse?>()
    val aniDetail: LiveData<AniByIdResponse?> = _aniDetail
    private val _charDetail = MutableLiveData<CharByIdResponse?>()
    val charDetail: LiveData<CharByIdResponse?> = _charDetail
    private val _charList = MutableLiveData<CharacterList?>()
    val charList: LiveData<CharacterList?> = _charList
    private val _searchResults = MutableLiveData<AnimeInfo?>()
    val searchResults: LiveData<AnimeInfo?> = _searchResults
    private val userId = Firebase.auth.currentUser?.uid
    private val _firebaseAnimeData = MutableLiveData<List<AniByIdResponse>>()
    val firebaseAnimeData: LiveData<List<AniByIdResponse>> = _firebaseAnimeData


    fun markAnimeAsDisLiked(animeData: AniByIdResponse) {
        if (userId != null) {
            repository.removeDislikedAnimeData(animeData.data?.mal_id.toString(), userId)
        }
    }

    fun markAnimeAsLiked(animeData: AniByIdResponse) {
        if (userId != null) {
            repository.saveLikedAnimeData(animeData)
        }
    }


    fun loadSeasonByYear(year: Int, season: String, page: Int) {
        viewModelScope.launch(Dispatchers.IO) {
            _seasonNow.postValue(repository.getSeasonByYear(year, season, page))
        }

    }

    fun loadLikedData() {
        viewModelScope.launch(Dispatchers.IO) {
            _firebaseAnimeData.postValue(repository.getFirebaseAnimeData())
        }
    }

    fun loadAnimeByID(id: Int) {
        viewModelScope.launch {
            _aniDetail.postValue(repository.getAnimeByID(id))
        }
    }

    fun loadCharByID(id: Int) {
        viewModelScope.launch {
            _charDetail.postValue(repository.getCharByID(id))
        }
    }

    fun loadCharacterList(aniId: Int) {
        viewModelScope.launch {
            _charList.postValue(repository.getCharList(aniId))
        }
    }

    fun fetchAnimeData(
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
    ) {
        viewModelScope.launch(Dispatchers.IO) {
            _searchResults.postValue(
                repository.getAllAnime(
                    page,
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
            )
        }


    }
}