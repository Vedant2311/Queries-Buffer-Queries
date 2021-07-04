SELECT wickets_temp.country_name, wickets_temp.player_name, wickets_temp.num_wickets, runs_temp.runs_conceded
FROM	
	(SELECT DISTINCT player_name, player_id, country_name, num_wickets
	FROM
		(SELECT player.player_name, player.player_id, country.country_name, COUNT(match.match_id) OVER (PARTITION BY player.player_id) AS num_wickets
		FROM player, player_match, match, country, ball_by_ball, wicket_taken, out_type
		WHERE ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.over_id = wicket_taken.over_id 
			AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
			AND wicket_taken.kind_out = out_type.out_id AND 
				(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED' 
					OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED' 
					OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
			AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id
			AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)
			AND match.match_id = player_match.match_id AND country.country_id = player.country_id) AS foo
	ORDER BY num_wickets DESC, player_name ASC) AS wickets_temp,
	(SELECT DISTINCT player_name, player_id, country_name, runs_conceded
	FROM
		(SELECT player.player_name, player.player_id, country.country_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY player.player_id) AS runs_conceded
		FROM player, player_match, match, country, ball_by_ball, batsman_scored
		WHERE ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id 
			AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no
			AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id
			AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)
			AND match.match_id = player_match.match_id AND country.country_id = player.country_id) AS foo_1
	ORDER BY runs_conceded ASC, player_name ASC) AS runs_temp
WHERE runs_temp.player_id = wickets_temp.player_id
ORDER BY num_wickets DESC, runs_conceded ASC, player_name ASC, country_name ASC
LIMIT 1;
