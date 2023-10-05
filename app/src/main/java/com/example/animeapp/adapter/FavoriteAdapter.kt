package com.example.animeapp.adapter

import android.os.Build
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.navigation.findNavController
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.AniByIdResponse
import com.example.animeapp.data.datamodels.Data
import com.example.animeapp.databinding.ListItemAnimeBinding
import com.example.animeapp.ui.HomeFragmentDirections
import com.example.animeapp.ui.ThisSeasonFragmentDirections
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.squareup.picasso.Picasso

class FavoriteAdapter   (
    private val dataset: List<AniByIdResponse>?,
    private val viewmodel: MainViewmodel
) : RecyclerView.Adapter<FavoriteAdapter.ItemViewHolder>() {
    inner class ItemViewHolder(val binding: ListItemAnimeBinding) :
        RecyclerView.ViewHolder(binding.root)


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val binding =
            ListItemAnimeBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ItemViewHolder(binding)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        val item = dataset?.get(position)
        var genre1 = ""
        var genreList = item?.data?.genres
        if (item != null) {
            if (genreList != null) {
                for (genre in genreList) {
                    genre1 = genre1 + " " + genre.name
                }
            }
        }
        val imageUrl = item?.data?.images?.jpg?.image_url
        Picasso.get().load(imageUrl).into(holder.binding.IVAnimeImage)
        if (item != null) {
            if (item.data?.title_english == null) {
                if (item != null) {
                    holder.binding.TVAnimeName.text = item.data?.title
                }
            } else {
                if (item != null) {
                    holder.binding.TVAnimeName.text = item.data?.title_english.toString()
                }
            }
        }
        if (item != null) {
            if (item.data?.score != null) {
                if (item != null) {
                    holder.binding.TVScore.text = item.data?.score.toString()
                }
            } else {
                holder.binding.TVScore.text = "N/A"
            }
        }
        holder.binding.TVGenre.text = genre1
        holder.binding.CVAnime.setOnClickListener {

            if (item != null) {
                if (item.data != null) {
                    it.findNavController().navigate(
                        HomeFragmentDirections.actionFavoFragmentToAnimeDetailFragment(
                            item.data.mal_id
                        )
                    )
                }}


        }
        if (item != null) {
            when (item.data?.like) {
                false -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star_border)

                }

                true -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star)

                }

                else -> {}
            }
        }



        holder.binding.IBTNLike.setOnClickListener {

            if (item != null) {
                when (item.data?.like) {
                    false -> {
                        holder.binding.IBTNLike.setImageResource(R.drawable.star)
                        viewmodel.markAnimeAsLiked(AniByIdResponse(item.data))
                    }

                    true -> {
                        holder.binding.IBTNLike.setImageResource(R.drawable.star_border)
                        viewmodel.markAnimeAsDisLiked(AniByIdResponse(item.data))
                    }

                    else -> {}
                }
            }

        }

    }


    override fun getItemCount(): Int {
        return dataset?.size ?: 0
    }


}