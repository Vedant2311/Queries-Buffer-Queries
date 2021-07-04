WITH rws AS (
SELECT fifty_stats.*, row_number() OVER (PARTITION BY season_year) AS rand
FROM
(SELECT DISTINCT season_year, match_id, team_name, COUNT(player_name) OVER (PARTITION BY match_id, team_name) AS num_batsmen
FROM
(SELECT player_name, season_year, match_id, team_name, runs
FROM
(SELECT DISTINCT player.player_name, season.season_year, match.match_id, team.team_name,
SUM(batsman_scored.runs_scored) OVER (PARTITION BY match.match_id, player.player_id) as runs
FROM season, player_match, player, match, batsman_scored, ball_by_ball, team, outcome
WHERE season.season_id = match.season_id AND player_match.match_id = match.match_id AND player.player_id = player_match.player_id
AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id
AND player_match.team_id = team.team_id AND match.match_winner = team.team_id
AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT'
ORDER BY runs DESC) AS foo
WHERE runs>=50) as foo_outer
ORDER BY season_year ASC, num_batsmen DESC, team_name ASC) AS fifty_stats
)
SELECT season_year, match_id, team_name FROM rws
WHERE rand <=3
ORDER BY season_year ASC, num_batsmen DESC, team_name ASC, match_id ASC;

