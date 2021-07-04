SELECT wickets_final.season_year AS season_year, wickets_final.player_name AS player_name, wickets_final.num_wickets AS num_wickets, runs_table.runs AS runs
FROM
(SELECT season_year, player_name, num_wickets
FROM
(SELECT season.season_year, player.player_name, COUNT(match.match_id) OVER (PARTITION BY season.season_id, player.player_id) AS num_wickets
FROM season, match, player_match, player, wicket_taken, ball_by_ball, out_type
WHERE season.season_id = match.season_id AND match.match_id = player_match.match_id AND player_match.player_id = player.player_id
AND ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.match_id = match.match_id AND ball_by_ball.over_id = wicket_taken.over_id
AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
AND player.player_id = ball_by_ball.bowler AND wicket_taken.kind_out = out_type.out_id AND
(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED'
OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED'
OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)) AS foo
GROUP BY season_year, player_name, num_wickets) AS wickets_final,
(SELECT season_year, player_name, runs
FROM
(SELECT season.season_year, player.player_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY season.season_id, player.player_id) as runs
FROM season, player_match, player, match, batsman_scored, ball_by_ball, batting_style
WHERE season.season_id = match.season_id AND player_match.match_id = match.match_id AND player.player_id = player_match.player_id
AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id
AND player.batting_hand = batting_style.batting_id AND batting_style.batting_hand = 'Left-hand bat') AS foo
GROUP BY season_year, player_name, runs) AS runs_table,
(SELECT season_year, player_name, total_matches
FROM
(SELECT season.season_year, player.player_name, COUNT(match.match_id) OVER (PARTITION BY season.season_id, player.player_id) as total_matches
FROM season, player_match, player, match
WHERE season.season_id = match.season_id AND match.match_id = player_match.match_id AND player_match.player_id = player.player_id) AS foo
GROUP BY season_year, player_name, total_matches) AS matches_table
WHERE runs_table.season_year = wickets_final.season_year AND runs_table.player_name = wickets_final.player_name
ANd matches_table.season_year = wickets_final.season_year AND matches_table.player_name = wickets_final.player_name
AND runs_table.runs>=150 AND wickets_final.num_wickets>=5 AND matches_table.total_matches>=10
ORDER BY num_wickets DESC, runs DESC, player_name ASC, season_year ASC;

