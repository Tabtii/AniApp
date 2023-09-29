package com.example.animeapp.adapter

import android.content.ContentValues.TAG
import android.os.Build
import android.util.Log
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.ExpandableListView.OnChildClickListener
import androidx.annotation.RequiresApi
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.data.datamodels.AnimeData
import androidx.navigation.findNavController
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.LikedAnimes
import com.example.animeapp.databinding.ListItemAnimeBinding
import com.example.animeapp.ui.MainViewmodel
import com.example.animeapp.ui.ThisSeasonFragmentDirections
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.ValueEventListener
import com.google.firebase.database.ktx.getValue
import com.squareup.picasso.Picasso

class Adapter(
    private val dataset: List<AnimeData>,
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
        return dataset.size
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {


        val item = dataset[position]
        var genre1 = ""
        for (genre in item.genres!!) {
            genre1 = genre1 + " " + genre.name
        }
        val imageUrl = item.images?.jpg?.image_url
        Picasso.get().load(imageUrl).into(holder.binding.IVAnimeImage)
        if (item.title_english == null) {
            holder.binding.TVAnimeName.text = item.title
        } else {
            holder.binding.TVAnimeName.text = item.title_english
        }
        if (item.score != null) {
            holder.binding.TVScore.text = item.score.toString()
        } else {
            holder.binding.TVScore.text = "N/A"
        }
        holder.binding.TVGenre.text = genre1
        holder.binding.CVAnime.setOnClickListener {

                it.findNavController().navigate(ThisSeasonFragmentDirections.actionThisSeasonFragmentToAnimeDetailFragment(item.mal_id))

        }
        when (item.liked) {
            false -> {
                holder.binding.IBTNLike.setImageResource(R.drawable.star_border)

            }

            true -> {
                holder.binding.IBTNLike.setImageResource(R.drawable.star)

            }
        }

        holder.binding.IBTNLike.setOnClickListener {

            when (item.liked) {
                false -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star)
                    item.liked = true
                    viewmodel.markAnimeAsLiked(item)
                    viewmodel.updateAnime(item)
                }

                true -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star_border)
                    item.liked = false
                    viewmodel.updateAnime(item)
                }
            }

        }

    }

}
