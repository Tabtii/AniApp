package com.example.animeapp.ui.detail

import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.AnimeCharacter
import com.example.animeapp.databinding.FragmentAnimeDetailBinding
import com.example.animeapp.databinding.FragmentCharDetailBinding
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.squareup.picasso.Picasso
private const val TAG = "CharDetail"

class CharDetailFragment : Fragment() {
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentCharDetailBinding
    private var id = 0
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            id = it.getInt("CharID")
            Log.d(TAG, "$id")

            viewModel.loadCharByID(id)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        binding = FragmentCharDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        viewModel.charDetail.observe(viewLifecycleOwner){
            val item = it

            val imageUrl = item?.data?.images?.jpg?.image_url
            Picasso.get().load(imageUrl).into(binding.IVCharDetailImage)

            if (item != null) {
                binding.TVCharDetailName.text = item.data.name
            }
        }
    }
}