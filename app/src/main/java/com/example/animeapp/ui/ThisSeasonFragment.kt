package com.example.animeapp.ui

import android.os.Build
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import com.example.animeapp.R
import com.example.animeapp.adapter.Adapter
import com.example.animeapp.databinding.FragmentThisSeasonBinding
import com.example.animeapp.util.Season
import com.example.animeapp.util.Year

@RequiresApi(Build.VERSION_CODES.O)
class ThisSeasonFragment : Fragment() {

    private val currentSeason = Season()
    private val year = Year()
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentThisSeasonBinding

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {
        binding = FragmentThisSeasonBinding.inflate(inflater, container, false)
        viewModel.loadList()
        return binding.root
    }


    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        when(currentSeason){
            "winter"-> {
                binding.IVSeason.setImageResource(R.drawable.imgbin_anime_mangaka_4chan_png)
                binding.TVSeason.text = "Winter\n" +
                        "Season\n" +
                        "$year"
            }
                "spring"->{
                    binding.IVSeason.setImageResource(R.drawable.imgbin_manga_my_hero_academia_fan_art_anime_png)
                    binding.TVSeason.text = "Spring\n" +
                            "Season\n" +
                            "$year"

                }
            "summer"->{
                binding.IVSeason.setImageResource(R.drawable.imgbin_monkey_d_luffy_roronoa_zoro_logo_one_piece_character_png)
                binding.TVSeason.text = "Summer\nSeason\n$year"

            }
            "fall"->{
                binding.IVSeason.setImageResource(R.drawable.imgbin_re_zero_starting_life_in_another_world_r_e_m_anime_manga_png)
                binding.TVSeason.text = "Fall\n" +
                        "Season\n" +
                        "$year"

            }
        }

        viewModel.seasonNow.observe(viewLifecycleOwner) { anime ->
            binding.RVSeason.adapter = Adapter(anime)
        }


    }
}