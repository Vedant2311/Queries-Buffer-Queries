SELECT season_year, player_name, num_matches
FROM
(SELECT season.season_year, player.player_name, COUNT(player_match.match_id) OVER (PARTITION BY player.player_id, season.season_id) AS num_matches
FROM season, player, player_match, match
WHERE player.player_id = player_match.player_id AND player_match.match_id = match.match_id
AND match.season_id = season.season_id AND season.purple_cap = player.player_id) as foo
GROUP BY season_year, player_name, num_matches
ORDER BY season_year ASC, player_name ASC, num_matches ASC;

