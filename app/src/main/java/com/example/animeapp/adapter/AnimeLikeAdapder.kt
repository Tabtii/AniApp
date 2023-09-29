package com.example.animeapp.adapter

import android.os.Build
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.navigation.findNavController
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.R
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.databinding.ListItemAnimeBinding
import com.example.animeapp.ui.HomeFragmentDirections
import com.example.animeapp.ui.MainViewmodel
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener
import com.squareup.picasso.Picasso

class AnimeLikeAdapder   (
    private val dataset: List<AnimeData>,
    private val viewmodel: MainViewmodel
) : RecyclerView.Adapter<AnimeLikeAdapder.ItemViewHolder>() {
    inner class ItemViewHolder(val binding: ListItemAnimeBinding) :
        RecyclerView.ViewHolder(binding.root)
    val database = FirebaseDatabase.getInstance()
    val reference = database.getReference("Ihr_Datenbankpfad")


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val binding =
            ListItemAnimeBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ItemViewHolder(binding)
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

                it.findNavController().navigate(HomeFragmentDirections.actionHomeFragmentToAnimeDetailFragment(item.mal_id))


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
                    viewmodel.updateAnime(item)
                    notifyItemChanged(position)
                }

                true -> {
                    holder.binding.IBTNLike.setImageResource(R.drawable.star_border)
                    item.liked = false
                    viewmodel.updateAnime(item)
                    notifyItemChanged(position)
                }
            }

        }

    }


    override fun getItemCount(): Int {
        return dataset.size
    }


}