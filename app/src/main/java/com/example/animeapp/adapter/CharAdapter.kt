package com.example.animeapp.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.Character
import com.example.animeapp.databinding.ListItemAnimeBinding
import com.example.animeapp.databinding.ListItemCharakterBinding
import com.squareup.picasso.Picasso

class CharAdapter(
    private val dataset : List<Character>
) : RecyclerView.Adapter<CharAdapter.ItemViewHolder>(){
    inner class ItemViewHolder(val binding: ListItemCharakterBinding): RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val binding = ListItemCharakterBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ItemViewHolder(binding)
    }

    override fun onBindViewHolder(holder: CharAdapter.ItemViewHolder, position: Int) {
        val item = dataset.get(position)
        val imageUrl = item.images.jpg.image_url
        Picasso.get().load(imageUrl).into(holder.binding.IVCharacterImage)
        holder.binding.TVCharacterName.text = item.name
    }

    override fun getItemCount(): Int {
        return dataset.size
    }


}