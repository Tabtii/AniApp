package com.example.animeapp.ui.detail

import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.cardview.widget.CardView
import androidx.constraintlayout.widget.ConstraintSet
import androidx.core.content.ContextCompat
import androidx.core.view.marginStart
import androidx.fragment.app.activityViewModels
import com.example.animeapp.R
import com.example.animeapp.adapter.LittleAniAdapter
import com.example.animeapp.data.datamodels.AnimeCharacter
import com.example.animeapp.data.datamodels.Theme
import com.example.animeapp.databinding.FragmentAnimeDetailBinding
import com.example.animeapp.databinding.FragmentCharDetailBinding
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.google.android.material.card.MaterialCardView
import com.squareup.picasso.Picasso

private const val TAG = "CharDetail"

class CharDetailFragment : Fragment() {
    private val viewModel: MainViewmodel by activityViewModels()
    private lateinit var binding: FragmentCharDetailBinding
    private var id = 0

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            id = it.getInt("CharID")
            Log.d(TAG, "$id")

            viewModel.loadCharByID(id)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        binding = FragmentCharDetailBinding.inflate(inflater, container, false)
        return binding.root

    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val actorImage = listOf<Int>(
            R.drawable.chibivoice1,
            R.drawable.chibivoice2,
            R.drawable.chibivoice3,
            R.drawable.chibivoice4,
            R.drawable.chibivoice5,
        )
        val linearLayout = view?.findViewById<LinearLayout>(R.id.LLCharDetail)

        viewModel.charDetail.observe(viewLifecycleOwner) {

            if (it != null) {
                for (i in 1..(it.data.voices?.lastIndex
                    ?: 0)) {


                    val cardView = MaterialCardView(context)
                    val params = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.MATCH_PARENT
                    )
                    params.setMargins(0, 16, 0, 16) // Anpassen der Abstände
                    cardView.layoutParams = params
                    cardView.radius = 40f
                    cardView.setBackgroundColor(
                        ContextCompat.getColor(requireContext(), R.color.background)
                    )
                    cardView.strokeWidth = 3
                    cardView.layoutParams.height = 300

                    val linearLayout1 = LinearLayout(context)
                    linearLayout1.orientation = LinearLayout.HORIZONTAL
                    linearLayout1.layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.MATCH_PARENT
                    )

                    cardView.addView(linearLayout1)

                    val textView1 = TextView(requireContext())
                    textView1.isSingleLine = false
                    textView1.textSize = 18f
                    textView1.setTextColor(Color.BLACK)
                    val layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    )
                    layoutParams.gravity = Gravity.END
                    layoutParams.setMargins(
                        360,
                        8,
                        0,
                        8
                    )
                    textView1.layoutParams = layoutParams

                    textView1.text = "Voice actor/ actress:\n" +
                            "${it.data.voices?.get(i)?.person?.name}\n" +
                            "Language:\n" +
                            "${it.data.voices?.get(i)?.language}"

                    val imageView = ImageView(requireContext())
                    val layoutParamsImage = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    )
                    layoutParamsImage.gravity = Gravity.START
                    layoutParamsImage.setMargins(
                        0,
                        0,
                        680,
                        0,
                    )
                    imageView.layoutParams = layoutParamsImage

                    if (it.data.voices?.get(i)?.person?.images?.jpg?.imageUrl.isNullOrEmpty()) {
                        imageView.setImageResource(actorImage.random())
                    } else {
                        Picasso.get().load(it.data.voices?.get(i)?.person?.images?.jpg?.imageUrl)
                            .into(imageView)
                    }


                    cardView.addView(imageView)
                    cardView.addView(textView1)


                    linearLayout?.addView(cardView)
                }
                binding.RVAnime2.adapter= LittleAniAdapter(it.data.anime)
                binding.TVCharDetailName.text = it.data.name
                binding.TVNameKanji.text = it.data.name_kanji
                Picasso.get().load(it.data.images?.jpg?.image_url).into(binding.IVCharDetailImage)
                var nickname = ""
                for (name in it.data.nicknames!!) {
                    nickname = nickname + name + ", "
                    binding.TVNickname.text = nickname
                }
                binding.TVAbout.text = it.data.about
            }

        }
    }

}
