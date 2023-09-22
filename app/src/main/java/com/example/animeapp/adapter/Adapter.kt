package com.example.animeapp.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.data.datamodels.AnimeData

import com.example.animeapp.databinding.ListItemAnimeBinding
import com.squareup.picasso.Picasso

class Adapter(
    private val dataset: List<AnimeData>

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

    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        val item = dataset[position]
        val imageUrl =
            item.images?.jpg?.image_url // Hier sollte imageUrl die URL oder der Pfad zur Datei sein
        Picasso.get().load(imageUrl).into(holder.binding.IVAnimeImage)
        holder.binding.TVAnimeName.text = item.title
    }

}
