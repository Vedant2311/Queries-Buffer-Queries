SELECT team_name, opponent_team_name, number_of_sixes
FROM
(SELECT playing.team_name AS team_name, opponent.team_name AS opponent_team_name,
COUNT(batsman_scored.innings_no) OVER (PARTITION BY playing.team_id, opponent.team_id, match.match_id) AS number_of_sixes
FROM team AS playing, team AS opponent, batsman_scored, ball_by_ball, player, player_match, match, season
WHERE match.match_id = player_match.match_id AND player.player_id = player_match.player_id AND playing.team_id = player_match.team_id
AND ((playing.team_id = match.team_1 AND opponent.team_id = match.team_2) OR (playing.team_id = match.team_2 AND opponent.team_id = match.team_1))
AND match.season_id = season.season_id AND season.season_year = 2008
AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id
AND ball_by_ball.team_batting = playing.team_id AND ball_by_ball.team_bowling = opponent.team_id
AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)
AND batsman_scored.runs_scored = 6) AS foo
GROUP BY team_name, opponent_team_name, number_of_sixes
ORDER BY number_of_sixes DESC, team_name ASC, opponent_team_name ASC
LIMIT 3;

