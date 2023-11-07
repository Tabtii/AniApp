package com.example.animeapp.adapter

import android.os.Build
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.recyclerview.widget.RecyclerView
import androidx.navigation.findNavController
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.AnimeInfo
import com.example.animeapp.databinding.ListItemAnimeBinding
import com.example.animeapp.ui.SearchFragmentDirections
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.example.animeapp.ui.ThisSeasonFragmentDirections
import com.squareup.picasso.Picasso

private const val TAG = "Adapter"

class Adapter(
    private val dataset: AnimeInfo,
    private val viewmodel: MainViewmodel
) : RecyclerView.Adapter<Adapter.ItemViewHolder>() {


    inner class ItemViewHolder(val binding: ListItemAnimeBinding) :
        RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val binding =
            ListItemAnimeBinding.inflate(LayoutInflater.from(parent.context), parent, false)

        return ItemViewHolder(binding)
    }

    override fun getItemCount(): Int {
        return dataset.data.size
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {

        val item = dataset.data[position]
        Log.d(TAG, "$item")
        val id = item.mal_id
        var genre1 = ""
        if (item != null) {
            for (genre in item.genres!!) {
                genre1 = "$genre1 ${genre.name}"
            }
        }
        val imageUrl = item.images?.jpg?.image_url
        Picasso.get().load(imageUrl).into(holder.binding.IVAnimeImage)
        if (item.title_english == null) {
            holder.binding.TVAnimeName.text = item.title
        } else {
            holder.binding.TVAnimeName.text = item.title_english.toString()
        }
        if (item.score != null) {
            holder.binding.TVScore.text = item.score.toString()
        } else {
            holder.binding.TVScore.text = "N/A"
        }
        holder.binding.TVGenre.text = genre1
        holder.binding.CVAnime.setOnClickListener {
            Log.d(TAG, "$id")
            if (id != null) {
                try {
                    it.findNavController().navigate(
                        ThisSeasonFragmentDirections.actionThisSeasonFragmentToAnimeDetailFragment(
                            id
                        )
                    )
                } catch (e: Exception) {
                    it.findNavController().navigate(
                        SearchFragmentDirections.actionSearchFragmentToAnimeDetailFragment(id)
                    )
                }

            }

        }
        when (item.like) {
            false -> {
                holder.binding.IBTNLike.setImageResource(R.drawable.star_border)

            }

            true -> {
                holder.binding.IBTNLike.setImageResource(R.drawable.star)

            }


        }

        holder.binding.IBTNLike.setOnClickListener {

            when (item.like) {
                false -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star)
                    item.like = true
                    viewmodel.markAnimeAsLiked(AniByIdResponse(data = item))

                }

                true -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star_border)
                    item.like = false
                    viewmodel.markAnimeAsDisLiked(AniByIdResponse(data = item))
                }
            }

        }

    }

}
