package com.example.animeapp.ui

import android.app.Application
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.example.animeapp.data.repo.AppRepository
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.data.datamodels.MangaData
import com.example.animeapp.data.remote.AnimeApi
import com.example.animeapp.db.getDatabase

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.OptionalDouble.empty

@RequiresApi(Build.VERSION_CODES.O)
class MainViewmodel(app: Application) : AndroidViewModel(app) {

    private val repository = AppRepository(AnimeApi.retrofitService, getDatabase(app))


    val animeList : LiveData<List<AnimeData>> = repository.animeList
    val charList : LiveData<List<Character>> = repository.charList
    val mangaList : LiveData<List<MangaData>> = repository.mangaList
    val seasonNow : LiveData<List<AnimeData>> = repository.seasonNow
    private val _aniDetail = MutableLiveData<AnimeData>()
    val aniDetail: LiveData<AnimeData> = _aniDetail


   fun loadList() {
        viewModelScope.launch(Dispatchers.IO) {
            repository.getSeason()

        }
    }

    fun loadAnimeByID(id: Int) {
        viewModelScope.launch {
            val animeData = repository.getAnimeByID(id)
            _aniDetail.value = animeData
        }
    }
}