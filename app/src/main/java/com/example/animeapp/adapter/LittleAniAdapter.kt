package com.example.animeapp.adapter


import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.navigation.findNavController
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.data.datamodels.Anime
import com.example.animeapp.databinding.ListItemAnime2Binding
import com.example.animeapp.ui.detail.CharDetailFragmentDirections
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.squareup.picasso.Picasso

class LittleAniAdapter(
    private val dataset: List<Anime>?,
) : RecyclerView.Adapter<LittleAniAdapter.ItemViewHolder>() {


    inner class ItemViewHolder(val binding: ListItemAnime2Binding) :
        RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val binding =
            ListItemAnime2Binding
                .inflate(LayoutInflater.from(parent.context), parent, false)

        return ItemViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        var item = dataset?.get(position)
        val id = item?.anime?.mal_id!!
        if (item != null) {
            Picasso.get().load(item.anime.images.jpg?.image_url).into(holder.binding.IVAnimeImage2)
        }
        holder.binding.CVAnime2.setOnClickListener {
            if (item != null) {
                it.findNavController().navigate(
                    CharDetailFragmentDirections.actionCharDetailFragmentToAnimeDetailFragment(id)
                )
            }
        }
    }


    override fun getItemCount(): Int {
        return dataset?.size ?: 0
    }

}