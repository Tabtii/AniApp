package com.example.animeapp.ui.detail

import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import androidx.navigation.findNavController
import androidx.navigation.fragment.findNavController
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.databinding.FragmentAnimeDetailBinding
import com.example.animeapp.ui.ThisSeasonFragmentDirections
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.squareup.picasso.Picasso


private const val TAG = "AniDetail"
class AnimeDetailFragment : Fragment() {
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentAnimeDetailBinding
    private var id: Int = 0

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            id = it.getInt("IDAnime")
            Log.d(TAG, "$id")
            viewModel.loadAnimeByID(id)
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
            Log.d(TAG, "$it")
            if (it != null) {
                if (it.data?.images?.jpg?.image_url != null) {
                    Picasso.get().load(it.data?.images?.jpg?.image_url).into(binding.IVAnimeDetail)
                }
                if (it.data?.title_english == null){
                    binding.TVAnimeDetailTitle.text = it.data?.title
                }else{
                    binding.TVAnimeDetailTitle.text = it.data?.title_english.toString()
                }
            }
            var season = ""
            if (it != null) {
                binding.TVTitleEng.text= it.data?.title_english.toString()
                binding.TVTitleJap.text = it.data?.title_japanese
                when(it.data?.season){
                    "winter" -> season = "Winter"
                    "spring" -> season = "Spring"
                    "summer" -> season = "Summer"
                    "fall" -> season = "Fall"
                }
                binding.TVType.text = it.data?.type
                binding.TVStatus.text = it.data?.status
                binding.TVEpisodes.text = it.data?.episodes.toString()
                binding.TVPremiered.text = "$season ${it.data?.year}"
                binding.TVScoredetail.text = it.data?.score.toString()
                binding.TVScoredBy.text = "${it.data?.scored_by} users"
                binding.TVSource.text = it.data?.source
                viewModel.firebaseAnimeData.observe(viewLifecycleOwner){list->
                    if (list.isNullOrEmpty()){

                    }else { for (item in list){
                        if (item.mal_id  == it.data?.mal_id){

                        }
                    }}

                }
                when (it.data?.like) {
                    false -> {
                        binding.IBTNLikeADetail.setImageResource(R.drawable.star_border)
                    }
                    true -> {
                        binding.IBTNLikeADetail.setImageResource(R.drawable.star)
                    }

                    else -> {}
                }
                binding.IBTNLikeADetail.setOnClickListener {view->
                    when (it.data?.like) {
                        true -> {
                            binding.IBTNLikeADetail.setImageResource(R.drawable.star_border)
                            it.data?.like = false
                            viewModel.markAnimeAsDisLiked(it)



                        }
                        false -> {
                            binding.IBTNLikeADetail.setImageResource(R.drawable.star)
                            it.data?.like = true
                            viewModel.markAnimeAsLiked(it)


                        }

                        else -> {}
                    }
                }

                /*binding.CVCharacterDetail.setOnClickListener {view->
                    view.findNavController().navigate(AnimeDetailFragmentDirections.actionAnimeDetailFragmentToCharacterListFragment(it.mal_id))
                }*/
            }

            if (it != null){
                binding.TVSynopsis.text = it.data?.synopsis ?: "N/A"
                if (it.data?.background != null) {
                    binding.TVBackground.text = it.data?.background.toString()
                }
            }

            val webView: WebView = binding.WVTrailer
            webView.settings.javaScriptEnabled = true
            webView.settings.domStorageEnabled = true
            webView.webViewClient = WebViewClient()
            val videoUrl = it?.data?.trailer?.embed_url
            if (videoUrl != null) {
                val htmlCode = "<html><body style='margin:0;padding:0;'><iframe width='100%' height='100%' src='$videoUrl' frameborder='0' allowfullscreen></iframe></body></html>"
                webView.loadData(htmlCode, "text/html", "utf-8")
            }




            var licensors = ""
            if (it != null) {
                for (licensor in it.data?.licensors!!){
                    licensors = "$licensors $licensor"
                }

                var producer = ""
                for (produ in it.data?.producers!!){
                    producer =  producer + " " + produ.name
                }
                binding.TVProducer.text = producer

                var studios = ""
                for (studio in it.data?.studios!!){
                    studios =  studios + " " + studio.name
                }
                binding.TVStudio.text = studios

                var themes = ""
                for (theme in it.data?.themes!!){
                    themes =  themes + " " + theme.name
                }

                binding.TVThemes.text = themes
                var genre1 = ""
                for (genre in it.data?.genres!!){
                    genre1 =  genre1 + " " + genre.name
                }
                binding.TVGenreDetail.text = genre1

            }
            binding.TVProducer.text = licensors


        }

    }

}