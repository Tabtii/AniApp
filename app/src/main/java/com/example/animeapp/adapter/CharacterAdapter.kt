package com.example.animeapp.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.animeapp.data.datamodels.AnimeData
import com.example.animeapp.data.datamodels.CharacterList
import com.example.animeapp.databinding.ListItemAnimeBinding
import com.example.animeapp.databinding.ListItemCharakterBinding
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.squareup.picasso.Picasso

class CharacterAdapter(
    private val dataset: CharacterList?,
    private val viewmodel: MainViewmodel
) : RecyclerView.Adapter<CharacterAdapter.ItemViewHolder>() {


    inner class ItemViewHolder(val binding: ListItemCharakterBinding) :
        RecyclerView.ViewHolder(binding.root)


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val binding =
            ListItemCharakterBinding.inflate(LayoutInflater.from(parent.context), parent, false)

        return ItemViewHolder(binding)
    }

    override fun getItemCount(): Int {
        return dataset?.data?.size ?:1
    }

    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        val item = dataset?.data?.get(position)

        if (item != null) {
            holder.binding.TVCharacterName.text = item.character.name
        }

        val imageUrl = item?.character?.images?.jpg?.image_url
        Picasso.get().load(imageUrl).into(holder.binding.IVCharacterImage)

        if (item != null) {
            holder.binding.TVCharRole.text ="Role: ${item.role}"
        }
    }

}