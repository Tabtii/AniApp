package com.example.animeapp.ui

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import com.example.animeapp.adapter.FavoriteAdapter
import com.example.animeapp.databinding.FragmentFavoListBinding
import com.example.animeapp.ui.loginup.SignInActivity
import com.example.animeapp.ui.viewmodel.MainViewmodel
import com.google.firebase.auth.FirebaseAuth


class HomeFragment : Fragment() {


    private lateinit var binding: FragmentFavoListBinding
    private val viewmodel: MainViewmodel by activityViewModels()


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {
        viewmodel.loadLikedData()
        binding = FragmentFavoListBinding.inflate(layoutInflater, container, false)
        return binding.root
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)


        binding.RvAnime.setHasFixedSize(true)

        binding.TVUser.text  = FirebaseAuth.getInstance().currentUser?.email


        viewmodel.firebaseAnimeData.observe(viewLifecycleOwner){
            Log.d("FAVLIST", "LiveData aktualisiert: $it")
            binding.RvAnime.adapter = FavoriteAdapter(it,viewmodel)
        }
        binding.BTNLogOut1.setOnClickListener {
            Toast.makeText(requireContext(), "Goodbye", Toast.LENGTH_SHORT).show()
            val intent = Intent(requireContext(), SignInActivity::class.java)
            FirebaseAuth.getInstance().signOut()
            // Starte die Login-Aktivität und schließe die aktuelle Aktivität
            startActivity(intent)
            requireActivity().finish()
        }
    }
}