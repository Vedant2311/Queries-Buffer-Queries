SELECT *
FROM
(SELECT match_id, player_name, team_name, num_wickets, season_year
FROM
(SELECT ball_by_ball.match_id, player.player_name, team.team_name,
COUNT(match.match_id) OVER (PARTITION BY player.player_id, match.match_id) AS num_wickets, season.season_year
FROM ball_by_ball, wicket_taken, out_type, player_match, team, player, season, match
WHERE ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
AND wicket_taken.kind_out = out_type.out_id AND
(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED'
OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED'
OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id AND team.team_id = player_match.team_id
AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)
AND season.season_id = match.season_id AND match.match_id = player_match.match_id) AS foo
GROUP BY match_id, player_name, team_name, num_wickets, season_year) AS player_wickets
ORDER BY num_wickets DESC, player_name ASC, match_id ASC, team_name ASC, season_year ASC
LIMIT 1;

