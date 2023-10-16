package com.example.animeapp.ui

import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.View.GONE
import android.view.View.VISIBLE
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import com.example.animeapp.R
import com.example.animeapp.adapter.Adapter
import com.example.animeapp.adapter.FavoriteAdapter
import com.example.animeapp.databinding.FragmentThisSeasonBinding
import com.example.animeapp.db.AnimeSearchQueryOrderBy
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.example.animeapp.util.Season
import com.example.animeapp.util.Year

private const val TAG = "TSFragment"

@RequiresApi(Build.VERSION_CODES.O)
class ThisSeasonFragment : Fragment() {

    private var currentSeason = Season()
    private var year = Year()
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentThisSeasonBinding

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {
        viewModel.loadSeasonByYear(year,currentSeason,1)
        binding = FragmentThisSeasonBinding.inflate(inflater, container, false)
        return binding.root
    }


    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val yearSpinner = binding.SPYear

        val yearOptions = listOf(1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,
            2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,
            2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,
            2020,2021,2022,2023)

        val orderByAdapter = ArrayAdapter(requireContext(), android.R.layout.simple_spinner_item, yearOptions)
        orderByAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        yearSpinner.adapter = orderByAdapter


        yearSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                val selectedItem = yearOptions[position]
                year = selectedItem
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
            }
        }


        val seasonSpinner = binding.SPSeason

        val seasonOptions = listOf("spring", "summer","fall", "winter")

        val sortAdapter = ArrayAdapter(requireContext(), android.R.layout.simple_spinner_item, seasonOptions)
        sortAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        seasonSpinner.adapter = sortAdapter


        seasonSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                val selectedItem = seasonOptions[position]
                currentSeason = selectedItem
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
            }
        }

        binding.BTNSearch2.setOnClickListener {
            viewModel.loadSeasonByYear(year,currentSeason,1)
        }

        binding.MCVSeasonView.setOnClickListener {
            when(binding.BTNSearch2.visibility){
                GONE -> {
                    binding.SPSeason.visibility = VISIBLE
                    binding.SPYear.visibility = VISIBLE
                    binding.YearTV2.visibility = VISIBLE
                    binding.SeasonTV2.visibility = VISIBLE
                    binding.BTNSearch2.visibility = VISIBLE
                }
                VISIBLE ->{
                    binding.SPSeason.visibility = GONE
                    binding.SPYear.visibility = GONE
                    binding.YearTV2.visibility = GONE
                    binding.SeasonTV2.visibility = GONE
                    binding.BTNSearch2.visibility = GONE
                }
            }
        }

        viewModel.seasonNow.observe(viewLifecycleOwner) { anime ->
            when (currentSeason) {
                "winter" -> {
                    binding.IVSeason.setImageResource(R.drawable.imgbin_anime_mangaka_4chan_png)
                    binding.TVSeason.text = "Winter\n" +
                            "Season\n" +
                            "$year"
                }

                "spring" -> {
                    binding.IVSeason.setImageResource(R.drawable.imgbin_manga_my_hero_academia_fan_art_anime_png)
                    binding.TVSeason.text = "Spring\n" +
                            "Season\n" +
                            "$year"

                }

                "summer" -> {
                    binding.IVSeason.setImageResource(R.drawable.imgbin_monkey_d_luffy_roronoa_zoro_logo_one_piece_character_png)
                    binding.TVSeason.text = "Summer\nSeason\n$year"

                }

                "fall" -> {
                    binding.IVSeason.setImageResource(R.drawable.imgbin_re_zero_starting_life_in_another_world_r_e_m_anime_manga_png)
                    binding.TVSeason.text = "Fall\n" +
                            "Season\n" +
                            "$year"

                }
            }

            binding.TVPagination.text =
                viewModel.seasonNow.value?.pagination?.current_page.toString()
            binding.TVFirstPage2.text = "1"
            binding.TVLastPage2.text = anime?.pagination?.last_visible_page.toString()

            if (anime != null) {
                binding.RVSeason.adapter = Adapter(anime, viewModel)
                when (anime.pagination?.has_next_page) {
                    true -> binding.BTNNext.visibility = View.VISIBLE
                    false -> binding.BTNNext.visibility = View.GONE
                    else -> binding.BTNNext.visibility = View.GONE
                }
                when (anime.pagination?.current_page) {
                    1 -> {
                        binding.TVLastPage2.visibility = View.VISIBLE
                        binding.BTNPrev.visibility = View.GONE
                        binding.TVFirstPage2.visibility = View.GONE
                        binding.TVPagination.visibility = View.VISIBLE
                    }

                    anime.pagination?.last_visible_page -> {
                        binding.TVLastPage2.visibility = View.GONE
                        binding.TVFirstPage2.visibility = View.VISIBLE
                        binding.BTNPrev.visibility = View.VISIBLE
                    }

                    null -> {
                        binding.TVLastPage2.visibility = View.GONE
                        binding.TVPagination.visibility = View.GONE
                        binding.TVFirstPage2.visibility = View.GONE
                    }

                    else -> {
                        binding.TVLastPage2.visibility = View.VISIBLE
                        binding.TVFirstPage2.visibility = View.VISIBLE
                        binding.BTNPrev.visibility = View.VISIBLE
                        binding.TVPagination.visibility = View.VISIBLE
                    }
                }
            }

        }

        binding.TVFirstPage2.setOnClickListener {
            viewModel.loadSeasonByYear(year, currentSeason,1)
        }

        binding.TVLastPage2.setOnClickListener {
            viewModel.loadSeasonByYear(year,currentSeason,viewModel.seasonNow.value?.pagination?.last_visible_page!!)
        }

        binding.BTNNext.setOnClickListener {
            var currentPage = viewModel.seasonNow.value?.pagination?.current_page
            if (currentPage != null) {
                try {
                    viewModel.loadSeasonByYear(year,currentSeason,currentPage + 1)
                    binding.TVPagination.text =
                        viewModel.seasonNow.value?.pagination?.current_page.toString()
                } catch (e: Exception) {
                    Toast.makeText(requireContext(), "Wait", Toast.LENGTH_SHORT)
                }

            }

        }
        binding.BTNPrev.setOnClickListener {
            var currentPage = viewModel.seasonNow.value?.pagination?.current_page
            if (currentPage != null) {
                try {
                    viewModel.loadSeasonByYear(year,currentSeason,currentPage - 1)
                    binding.TVPagination.text =
                        viewModel.seasonNow.value?.pagination?.current_page.toString()
                } catch (e: Exception) {
                    Toast.makeText(requireContext(), "Wait", Toast.LENGTH_SHORT)
                }
            }
        }

    }
}