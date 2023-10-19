package com.example.animeapp.db

enum class AnimeSearchQueryOrderBy(val value: String) {
    MAL_ID("mal_id"),
    TITLE("title"),
    START_DATE("start_date"),
    END_DATE("end_date"),
    EPISODES("episodes"),
    SCORE("score"),
    SCORED_BY("scored_by"),
    RANK("rank"),
    POPULARITY("popularity"),
    MEMBERS("members"),
    FAVORITES("favorites")
}

enum class Genre(val value : String){
    ACTION("1"),
    ADVENTURE("2"),
    AVANT_GARDE("5"),
    AWARD_WINNING("46"),
    BOYS_LOVE("28"),
    COMEDY("4"),
    DRAMA("8"),
    ECCHI("9"),
    FANTASY("10"),
    GIRLS_LOVE("26"),
    GOURMET("47"),
    HORROR("14"),
    MYSTERY("7"),
    ROMANCE("22"),
    SCIFI("24"),
    SLICE_OF_LIFE("36"),
    SPORTS("30"),
    SUPERNATURAL("37"),
    SUSPENSE("41")
}
