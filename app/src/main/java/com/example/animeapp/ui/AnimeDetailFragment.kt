package com.example.animeapp.ui

import android.os.Build
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import androidx.navigation.fragment.findNavController
import com.example.animeapp.databinding.FragmentAnimeDetailBinding
import com.squareup.picasso.Picasso



class AnimeDetailFragment : Fragment() {
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentAnimeDetailBinding


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
            binding.TVTitleEng.text= it.title_english
            binding.TVTitleJap.text = it.title_japanese
            var season = ""
            when(it.season){
                "winter" -> season = "Winter"
                "spring" -> season = "Spring"
                "summer" -> season = "Summer"
                "fall" -> season = "Fall"
            }

            binding.TVType.text = it.type
            binding.TVStatus.text = it.status
            binding.TVEpisodes.text = it.episodes.toString()
            binding.TVPremiered.text = "$season ${it.year}"
            binding.TVScoredetail.text = it.score.toString()
            binding.TVScoredBy.text = "${it.scored_by} users"
            binding.TVSource.text = it.source


            val webView: WebView = binding.WVTrailer
            // Aktiviere JavaScript im WebView
            webView.settings.javaScriptEnabled = true
            // Setze die YouTube-Video-URL
            val videoUrl = it.trailer?.embed_url
            if (videoUrl != null) {
                webView.loadUrl(videoUrl)
            }
            // Stelle sicher, dass Links im WebView geöffnet werden
            webView.webViewClient = WebViewClient()

            var licensors = ""
            for (licensor in it.licensors!!){
                licensors =  licensors + " " + licensor.name
            }
            binding.TVProducer.text = licensors

            var producer = ""
            for (produ in it.producers!!){
                producer =  producer + " " + produ.name
            }
            binding.TVProducer.text = producer

            var studios = ""
            for (studio in it.studios!!){
                studios =  studios + " " + studio.name
            }
            binding.TVStudio.text = studios

            var themes = ""
            for (theme in it.themes!!){
                themes =  themes + " " + theme.name
            }

            binding.TVThemes.text = themes
            var genre1 = ""
            for (genre in it.genres!!){
                genre1 =  genre1 + " " + genre.name
            }
            binding.TVGenreDetail.text = genre1
        }
        binding.IBTNBack.setOnClickListener {
            findNavController().navigateUp()
        }

    }

}