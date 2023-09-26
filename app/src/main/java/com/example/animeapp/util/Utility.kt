package com.example.animeapp.util

import android.os.Build
import androidx.annotation.RequiresApi
import java.time.LocalDate


@RequiresApi(Build.VERSION_CODES.O)
private val currentDate = LocalDate.now()
var currentSeason = ""


@RequiresApi(Build.VERSION_CODES.O)
fun Season(): String {
    when (currentDate.month.value) {
        1 -> currentSeason = "winter"
        2 -> currentSeason = "winter"
        3 -> currentSeason = "winter"
        4 -> currentSeason = "spring"
        5 -> currentSeason = "spring"
        6 -> currentSeason = "spring"
        7 -> currentSeason = "summer"
        8 -> currentSeason = "summer"
        9 -> currentSeason = "summer"
        10 -> currentSeason = "fall"
        11 -> currentSeason = "fall"
        12 -> currentSeason = "fall"
    }
    return currentSeason
}

@RequiresApi(Build.VERSION_CODES.O)
fun Year():Int{
    return currentDate.year
}