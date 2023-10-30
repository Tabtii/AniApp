package com.example.animeapp.ui

import android.R
import android.os.Build
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.SearchView
import android.widget.SeekBar
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import com.example.animeapp.adapter.Adapter
import com.example.animeapp.databinding.FragmentSearchBinding
import com.example.animeapp.db.AnimeSearchQueryOrderBy
import com.example.animeapp.db.Genre
import com.example.animeapp.ui.viewmodel.MainViewmodel

private const val TAG = "SEARCHFRAGMENT"

class SearchFragment : Fragment() {


    private lateinit var binding: FragmentSearchBinding
    private val viewmodel: MainViewmodel by activityViewModels()
    private var startPage = 1
    private var scoreSeekBar = 0
    private var sortBy = "desc"
    private var orderBy = AnimeSearchQueryOrderBy.SCORE.value
    private var genreNR : String = ""

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {

        binding = FragmentSearchBinding.inflate(layoutInflater, container, false)
        return binding.root
    }



    //Filteroptionen
    @RequiresApi(Build.VERSION_CODES.O)
    fun search(query: String, page: Int): Boolean {
        viewmodel.fetchAnimeData(
            page = page,
            q = query,
            type = null,
            score = null,
            minScore = scoreSeekBar.toDouble(),
            maxScore = null,
            status = null,
            rating = null,
            genres = genreNR,
            genresExcluded = null,
            orderBy = orderBy,
            sort = sortBy,
            letter = null,
            producers = null,
            startDate = null,
            endDate = null
        )
        return true
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        //Schieberegler um den MinScore einzustellen
        val seekBar = binding.seekBar
        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                binding.TVMinScore.text = progress.toString()
                scoreSeekBar = progress
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) {
            }

            override fun onStopTrackingTouch(seekBar: SeekBar?) {
            }
        })


        val orderBySpinner = binding.spinner2
        val orderByOptions = listOf("Score","Title" )
        val orderByAdapter =
            ArrayAdapter(requireContext(), R.layout.simple_spinner_item, orderByOptions)
        orderByAdapter.setDropDownViewResource(R.layout.simple_spinner_dropdown_item)
        orderBySpinner.adapter = orderByAdapter
        orderBySpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                val selectedItem = orderByOptions[position]
                when (selectedItem) {
                    "Title" -> orderBy = AnimeSearchQueryOrderBy.TITLE.value
                    "Score" -> orderBy = AnimeSearchQueryOrderBy.SCORE.value
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {
            }
        }


        val genreSpinner = binding.SPIGenre
        val genreOptions =
            listOf(
                "Action", "Adventure", "Avant Garde", "Award winning", "Boys love",
                "Comedy", "Drama", "Ecchi", "Fantasy", "Girls love", "Gourmet", "Horror", "Mystery",
                "Romance","Sci-Fi","Slice of life","Sports","Supernatural","Suspense")
        val genreAdapter =
            ArrayAdapter(requireContext(), R.layout.simple_spinner_item, genreOptions)
        genreAdapter.setDropDownViewResource(R.layout.simple_spinner_dropdown_item)
        genreSpinner.adapter = genreAdapter
        genreSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                val selectedItem = genreOptions[position]
                when (selectedItem) {
                    "Action" -> genreNR = Genre.ACTION.value
                    "Adventure" ->  genreNR = Genre.ADVENTURE.value
                    "Avant Garde" -> genreNR = Genre.AVANT_GARDE.value
                    "Award winning" -> genreNR = Genre.AWARD_WINNING.value
                    "Boys love" -> genreNR = Genre.BOYS_LOVE.value
                    "Comedy" -> genreNR = Genre.COMEDY.value
                    "Drama" -> genreNR = Genre.DRAMA.value
                    "Ecchi"-> genreNR = Genre.ECCHI.value
                    "Fantasy"-> genreNR = Genre.FANTASY.value
                    "Girls love" -> genreNR = Genre.GIRLS_LOVE.value
                    "Gourmet" -> genreNR = Genre.GOURMET.value
                    "Horror" -> genreNR = Genre.HORROR.value
                    "Mystery" -> genreNR = Genre.MYSTERY.value
                    "Romance" -> genreNR = Genre.ROMANCE.value
                    "Sci-Fi" -> genreNR = Genre.SCIFI.value
                    "Slice of life" -> genreNR = Genre.SLICE_OF_LIFE.value
                    "Sports" -> genreNR = Genre.SPORTS.value
                    "Supernatural" -> genreNR = Genre.SUPERNATURAL.value
                    "Suspense" -> genreNR = Genre.SUSPENSE.value
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {
            }
        }


        binding.FilterTV.setOnClickListener {
            when (binding.CVFilter.visibility) {
                View.VISIBLE -> binding.CVFilter.visibility = View.GONE
                View.GONE -> binding.CVFilter.visibility = View.VISIBLE
            }
        }


        binding.BTNSearch.setOnClickListener {
            search(binding.SearchView.query.toString(), 1)
            binding.CVFilter.visibility = View.GONE
        }


        val sortSpinner = binding.spinner
        val sortOptions = listOf("descended", "ascended")
        val sortAdapter = ArrayAdapter(requireContext(), R.layout.simple_spinner_item, sortOptions)
        sortAdapter.setDropDownViewResource(R.layout.simple_spinner_dropdown_item)
        sortSpinner.adapter = sortAdapter
        sortSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                val selectedItem = sortOptions[position]
                when (selectedItem) {
                    "descended" -> sortBy = "desc"
                    "ascended" -> sortBy = "asc"
                }

            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
            }
        }



        val searchView = binding.SearchView
        val searchViewListener = object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                query?.let {
                    startPage = 1
                    search(it, startPage)
                }
                return true
            }

            override fun onQueryTextChange(newText: String?): Boolean {

                return true
            }
        }
        binding.seekBar
        searchView.setOnQueryTextListener(searchViewListener)
        viewmodel.searchResults.observe(viewLifecycleOwner) { result ->
            binding.TVFirstPage.text = "1"
            binding.TVLastPage.text = result?.pagination?.last_visible_page.toString()
            binding.TVPagination2.text = result?.pagination?.current_page.toString()
            if (result != null) {
                binding.RVFavoFrag.adapter = Adapter(result, viewmodel)

                when (result.pagination?.has_next_page) {
                    true -> binding.BTNNext2.visibility = View.VISIBLE
                    false -> binding.BTNNext2.visibility = View.GONE
                    else -> binding.BTNNext2.visibility = View.GONE
                }
                when (result.pagination?.current_page) {
                    1 -> {
                        binding.BTNPrev2.visibility = View.GONE
                        binding.TVFirstPage.visibility = View.GONE
                        binding.TVPagination2.visibility = View.VISIBLE
                        if (result.pagination.current_page != result.pagination.last_visible_page) {
                            binding.TVLastPage.visibility = View.VISIBLE
                        } else {
                            binding.TVLastPage.visibility = View.GONE

                        }
                    }

                    result.pagination?.last_visible_page -> {
                        binding.TVLastPage.visibility = View.GONE
                        binding.TVFirstPage.visibility = View.VISIBLE
                        binding.BTNPrev2.visibility = View.VISIBLE
                    }

                    null -> {
                        binding.TVLastPage.visibility = View.GONE
                        binding.TVPagination2.visibility = View.GONE
                        binding.TVFirstPage.visibility = View.GONE
                    }

                    else -> {
                        binding.TVLastPage.visibility = View.VISIBLE
                        binding.TVFirstPage.visibility = View.VISIBLE
                        binding.BTNPrev2.visibility = View.VISIBLE
                        binding.TVPagination2.visibility = View.VISIBLE
                    }
                }
            }
        }
        binding.TVFirstPage.setOnClickListener {
            startPage = 1
            search(binding.SearchView.query.toString(), startPage)
        }

        binding.TVLastPage.setOnClickListener {
            startPage = viewmodel.searchResults.value?.pagination?.last_visible_page!!
            search(binding.SearchView.query.toString(), startPage)
        }


        binding.BTNNext2.setOnClickListener {
            Thread.sleep(500)

            startPage++
            search(binding.SearchView.query.toString(), startPage)
        }

        binding.BTNPrev2.setOnClickListener {
            Thread.sleep(500)

            startPage--
            search(binding.SearchView.query.toString(), startPage)

        }
    }
}