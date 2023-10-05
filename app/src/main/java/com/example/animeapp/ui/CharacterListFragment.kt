package com.example.animeapp.ui

import android.os.Build
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.LiveData
import com.example.animeapp.adapter.CharacterAdapter
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.databinding.FragmentCharacterListBinding
import com.example.animeapp.ui.viewmodel.MainViewmodel


class CharacterListFragment : Fragment() {
    private lateinit var binding: FragmentCharacterListBinding
    private val viewModel: MainViewmodel by activityViewModels()
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            val index = it.getInt("AniID")
            viewModel.loadCharacterList(index)
        }
    }
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {

        binding = FragmentCharacterListBinding.inflate(layoutInflater, container, false)
        return binding.root
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.RVCharList1.setHasFixedSize(true)
        viewModel.charList.observe(viewLifecycleOwner){
            binding.RVCharList1.adapter= CharacterAdapter(it,viewModel)
        }
    }
}