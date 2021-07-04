SELECT player_name
FROM
(SELECT player.player_name, COUNT(match.match_id) OVER (PARTITION BY player.player_id) AS num_catches
FROM match, player_match, player, wicket_taken, out_type, season
WHERE match.match_id = player_match.match_id AND player_match.player_id = player.player_id
AND wicket_taken.match_id = match.match_id AND wicket_taken.kind_out = out_type.out_id AND upper(out_type.out_name) = 'CAUGHT'
AND wicket_taken.fielders = player.player_id AND (wicket_taken.innings_no = 1 OR wicket_taken.innings_no = 2)
AND match.season_id = season.season_id AND season.season_year = 2012) as foo
GROUP BY player_name, num_catches
ORDER BY num_catches DESC, player_name ASC
LIMIT 1;

