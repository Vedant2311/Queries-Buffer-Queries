SELECT all_season.player_name, wickets_stats.highest_wickets, wickets_stats.season_year
FROM
	(SELECT DISTINCT player_name, player_id
	FROM
		(SELECT player_name, player_id, COUNT(season_id) OVER (PARTITION BY player_name) AS num_seasons
		FROM
			(SELECT DISTINCT player.player_name, player.player_id, match.season_id
			FROM player, player_match, match
			WHERE player_match.match_id = match.match_id AND player_match.player_id = player.player_id
			ORDER BY player.player_name, match.season_id) AS foo) AS season_stats
	WHERE num_seasons = (SELECT COUNT(DISTINCT season_id) FROM season)) AS all_season LEFT OUTER JOIN
	(SELECT player_name, player_id, season_year, num_wickets AS highest_wickets
	FROM
		(SELECT foo.*, row_number() OVER (PARTITION BY player_id) AS rand FROM
			(SELECT DISTINCT player.player_name, player.player_id, season.season_year, COUNT(match.match_id) OVER (PARTITION BY player.player_id, season.season_id) AS num_wickets
			FROM player, player_match, match, country, ball_by_ball, wicket_taken, out_type, season
			WHERE ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.over_id = wicket_taken.over_id 
				AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
				AND wicket_taken.kind_out = out_type.out_id AND 
					(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED' 
						OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED' 
						OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
				AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id AND match.season_id = season.season_id
				AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)
				AND match.match_id = player_match.match_id AND country.country_id = player.country_id
			ORDER BY player.player_id ASC, num_wickets DESC, season_year ASC) AS foo) AS foo_seasons
	WHERE rand=1) AS wickets_stats
ON wickets_stats.player_id = all_season.player_id;
