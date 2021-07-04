SELECT DISTINCT (player_name)
FROM
(SELECT player.player_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY player.player_id, match.match_id) AS total_runs
FROM player, player_match, match, batsman_scored, ball_by_ball, outcome
WHERE player_match.match_id = match.match_id AND player_match.player_id = player.player_id
AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id
AND (NOT match.match_winner = player_match.team_id) AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT') AS foo
WHERE total_runs > 50
ORDER BY player_name ASC;

