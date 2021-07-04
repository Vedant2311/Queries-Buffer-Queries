SELECT *
FROM
(SELECT *
FROM
(SELECT match_id, player_name, team_name, COUNT(match_id) OVER (PARTITION BY player_id, match_id) AS num_wickets
FROM
(SELECT ball_by_ball.match_id, player.player_id, player.player_name, team.team_name
FROM ball_by_ball, wicket_taken, out_type, player_match, team, player
WHERE ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
AND wicket_taken.kind_out = out_type.out_id AND
(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED'
OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED'
OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id AND team.team_id = player_match.team_id
AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)) AS foo) AS foo_outer
WHERE foo_outer.num_wickets>=5) as foo_outer_1
GROUP BY match_id, player_name, team_name, num_wickets
ORDER BY num_wickets DESC, player_name ASC, team_name ASC, match_id ASC;

