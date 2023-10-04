package com.example.animeapp.ui

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.fragment.app.activityViewModels
import com.example.animeapp.databinding.FragmentSearchBinding
import com.google.firebase.auth.FirebaseAuth
import com.example.animeapp.ui.loginup.SignInActivity
import com.example.animeapp.ui.viewmodel.MainViewmodel


class SearchFragment : Fragment() {


    private lateinit var binding: FragmentSearchBinding
    private val viewmodel: MainViewmodel by activityViewModels()


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {

        binding = FragmentSearchBinding.inflate(layoutInflater, container, false)
        return binding.root
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)



        binding.BTNLogOut.setOnClickListener {
            Toast.makeText(requireContext(), "Goodbye", Toast.LENGTH_SHORT).show()
            val intent = Intent(requireContext(), SignInActivity::class.java)
            FirebaseAuth.getInstance().signOut()
            // Starte die Login-Aktivität und schließe die aktuelle Aktivität
            startActivity(intent)
            requireActivity().finish()
        }
    }
}