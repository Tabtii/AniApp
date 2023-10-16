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
