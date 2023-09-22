package com.example.animeapp.ui

import android.app.Application
import android.util.Log
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.viewModelScope
import com.example.animeapp.data.AppRepository
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.data.datamodels.MangaData
import com.example.animeapp.data.remote.AnimeApi
import com.example.animeapp.db.getDatabase

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainViewmodel(app: Application) : AndroidViewModel(app) {

    private val repository = AppRepository(AnimeApi.retrofitService, getDatabase(app))


    val animeList : LiveData<List<AnimeData>> = repository.animeList
    val charList : LiveData<List<Character>> = repository.charList
    val mangaList : LiveData<List<MangaData>> = repository.mangaList

    init {
        loadList()
    }


    fun loadList() {
        viewModelScope.launch(Dispatchers.IO) {
            repository.getAnimeList()
            repository.getCharList()
            repository.getMangaList()
        }
    }

}