package com.example.animeapp.ui

import android.app.Application
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.liveData
import androidx.lifecycle.viewModelScope
import com.example.animeapp.adapter.AnimeLikeAdapder
import com.example.animeapp.data.repo.AppRepository
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.data.datamodels.MangaData
import com.example.animeapp.data.datamodels.MangaInfo
import com.example.animeapp.data.datamodels.Pagination
import com.example.animeapp.data.remote.AnimeApi
import com.example.animeapp.db.getDatabase
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.internal.notify
import java.util.OptionalDouble.empty

@RequiresApi(Build.VERSION_CODES.O)
class MainViewmodel(app: Application) : AndroidViewModel(app) {

    private val repository = AppRepository(AnimeApi.retrofitService, getDatabase(app))


    val animeList: LiveData<List<AnimeData>> = repository.animeList
    val charList: LiveData<List<Character>> = repository.charList
    val mangaList: LiveData<List<MangaData>> = repository.mangaList
    val seasonNow: LiveData<List<AnimeData>> = repository.seasonNow
    val paging: LiveData<Pagination> = repository.pageList
    private val _aniDetail = MutableLiveData<AnimeData>()
    val aniDetail: LiveData<AnimeData> = _aniDetail
    private val _aniLiked = MutableLiveData<List<AnimeData>>()
    val aniLiked: LiveData<List<AnimeData>> = _aniLiked
    val database = FirebaseDatabase.getInstance()
    val reference = database.getReference("anime_table")

    init {
        loadSeasonNow(1)
    }

    fun getFirebaseAnimeData(): LiveData<List<AnimeData>> {
        return repository.getFirebaseAnimeData()
    }
    fun getLikedAnimeData(): LiveData<List<AnimeData>> {
        return liveData {
            val animeList = repository.getAnimeLiked()
            emit(animeList)
        }
    }
    fun markAnimeAsLiked(animeData: AnimeData) {
        animeData.liked = true
        repository.saveLikedAnimeData(animeData)
    }
    fun loadSeasonNow(page: Int) {
        viewModelScope.launch(Dispatchers.IO) {
            repository.getSeason(page)
        }
    }

    fun updateAnime(animeData: AnimeData){
        viewModelScope.launch(Dispatchers.IO){
            repository.updateAnime(animeData)

        }
    }

    fun loadLikedAnime(){
        viewModelScope.launch {
           _aniLiked.value= repository.getAnimeLiked()
        }
    }

    fun loadAnimeByID(id: Int) {
        viewModelScope.launch {
            val animeData = repository.getAnimeByID(id)
            _aniDetail.value = animeData
        }
    }





}