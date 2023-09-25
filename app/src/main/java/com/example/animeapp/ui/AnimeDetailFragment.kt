package com.example.animeapp.ui

import android.os.Build
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.viewModelScope
import androidx.navigation.fragment.findNavController
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.databinding.FragmentAnimeDetailBinding
import com.example.animeapp.databinding.FragmentThisSeasonBinding
import com.squareup.picasso.Picasso
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


class AnimeDetailFragment : Fragment() {
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentAnimeDetailBinding

    private lateinit var anime: AnimeData

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            val index = it.getInt("IDAnime")
            viewModel.loadAnimeByID(index)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        binding = FragmentAnimeDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        viewModel.aniDetail.observe(viewLifecycleOwner) {
            val imageUrl = it.images?.jpg?.image_url
            Picasso.get().load(imageUrl).into(binding.IVAnimeDetail)
            if (it.title_english == null){
                binding.TVAnimeDetailTitle.text = it.title
            }else{
                binding.TVAnimeDetailTitle.text = it.title_english
            }

        }
        binding.IBTNBack.setOnClickListener {
            findNavController().navigateUp()
        }

    }

}