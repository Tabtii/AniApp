package com.example.animeapp

import android.content.pm.ActivityInfo
import android.os.Build
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Toast
import androidx.activity.viewModels
import androidx.annotation.RequiresApi
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.NavigationUI
import androidx.navigation.ui.setupWithNavController
import com.example.animeapp.databinding.ActivityMainBinding
import com.example.animeapp.ui.viewmodel.MainViewmodel
import androidx.activity.OnBackPressedCallback
import com.google.firebase.database.FirebaseDatabase

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private val viewmodel: MainViewmodel by viewModels()


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Verhindern der automatischen Bildschirmrotation
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT // Portrait-Modus

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        FirebaseDatabase.getInstance().setPersistenceEnabled(true)

        //NavController durch NavHostFragment laden
        val navHostFragment: NavHostFragment =
            supportFragmentManager.findFragmentById(R.id.navHostFragmentFCV) as NavHostFragment
        val navController = navHostFragment.navController

        //BottomNavBar mit NavController verbinden
        binding.bottomNavBNV.setupWithNavController(navController)


        //Wird aufgerufen wenn Item in der NavBar ausgewählt wird
        binding.bottomNavBNV.setOnItemSelectedListener { item ->

            //Standard NavBar Funktionalität: Navigiere zum ausgewählten Item
            //Hierbei wird auch im navController der entsprechende BackStack geladen
            //Das führt dazu dass vorherige Navigation noch "gespeichert" und z.B.
            //das zweite Fragment angezeigt wird obwohl das erste ausgewählt wurde
            NavigationUI.onNavDestinationSelected(item, navController)

            //Hier lösen wir das Problem indem wir den BackStack zurücksetzen auf das ausgewählte Item
            navController.popBackStack(item.itemId, false)

            //Item soll als ausgewählt angezeigt werden(farblich hinterlegt)
            return@setOnItemSelectedListener true
        }
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                navController.navigateUp()
                Toast.makeText(this@MainActivity, "Back Pressed", Toast.LENGTH_LONG).show()
            }

        })
    }
}