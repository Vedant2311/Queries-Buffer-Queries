SELECT DISTINCT player_name
FROM
(SELECT player_name, COUNT(season_id) OVER (PARTITION BY player_name) AS num_seasons
FROM
(SELECT DISTINCT player.player_name, match.season_id
FROM player, player_match, match
WHERE player_match.match_id = match.match_id AND player_match.player_id = player.player_id
ORDER BY player.player_name, match.season_id) AS foo) AS season_stats
WHERE num_seasons = (SELECT COUNT(DISTINCT season_id) FROM season)
ORDER BY player_name ASC;

