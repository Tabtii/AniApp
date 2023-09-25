package com.example.animeapp.ui

import android.os.Bundle
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup

import androidx.fragment.app.activityViewModels
import com.example.animeapp.adapter.Adapter
import com.example.animeapp.databinding.FragmentHomeBinding


class HomeFragment : Fragment() {


    private lateinit var binding: FragmentHomeBinding
    private val viewmodel: MainViewmodel by activityViewModels()


    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {



        binding = FragmentHomeBinding.inflate(layoutInflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.RvAnime.setHasFixedSize(true)
        binding.RvCharakter.setHasFixedSize(true)
        binding.RvManga.setHasFixedSize(true)
        binding.RvFavorite.setHasFixedSize(true)




    }
}