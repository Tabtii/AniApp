package com.example.animeapp.ui.detail

import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.activityViewModels
import com.example.animeapp.R
import com.example.animeapp.databinding.FragmentAnimeDetailBinding
import com.example.animeapp.databinding.FragmentCharDetailBinding
import com.example.animeapp.ui.viewmodel.MainViewmodel

class CharDetailFragment : Fragment() {
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentCharDetailBinding


    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        binding = FragmentCharDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
    }
}