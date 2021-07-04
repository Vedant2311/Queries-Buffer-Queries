SELECT max_runs.player_name
FROM
(SELECT DISTINCT player_id, player_name, num_overs
FROM
(SELECT player_id, player_name, match_id, over_id, over_runs, COUNT(match_id) OVER (PARTITION BY player_id) AS num_overs
FROM
(SELECT DISTINCT player_id, player_name, match_id, over_id, over_runs
FROM
(SELECT player.player_id, player.player_name, match.match_id, ball_by_ball.over_id,
SUM(batsman_scored.runs_scored) OVER (PARTITION BY player.player_id, match.match_id, ball_by_ball.over_id) AS over_runs
FROM player, player_match, match, ball_by_ball, batsman_scored
WHERE player_match.player_id = player.player_id AND player_match.match_id = match.match_id AND ball_by_ball.match_id = match.match_id
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.bowler = player.player_id) AS foo_1
WHERE over_runs	> 20
ORDER BY player_id ASC, match_id ASC, over_id ASC, over_runs ASC) AS player_runs) AS foo_outer_1
ORDER BY num_overs DESC, player_name ASC) AS max_runs
WHERE max_runs.player_name IN
(SELECT player_teams.player_name
FROM
(WITH rws AS
(SELECT foo.*, COUNT(team_id) OVER (PARTITION BY player_id) AS rand
FROM
(SELECT DISTINCT player.player_id, player.player_name, team.team_id, team.team_name
FROM player, team, player_match
WHERE player.player_id = player_match.player_id AND player_match.team_id = team.team_id
ORDER BY player.player_id ASC) AS foo)
SELECT DISTINCT player_id, player_name FROM rws
WHERE rand>=3
ORDER BY player_id ASC) AS player_teams)
LIMIT 5;

