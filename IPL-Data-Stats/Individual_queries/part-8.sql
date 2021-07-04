SELECT foo_outer.team_name, foo_outer.player_name, foo_outer.runs
FROM
(SELECT team_name, player_name, runs
FROM
(SELECT team.team_name, player.player_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY team.team_name, player.player_id) AS runs
FROM team, player, player_match, match, outcome, season, ball_by_ball, batsman_scored
WHERE team.team_id = player_match.team_id AND player_match.player_id = player.player_id
AND player_match.match_id = match.match_id AND match.outcome_id = outcome.outcome_id
AND match.season_id = season.season_id AND season.season_year = 2010
AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id) AS foo
GROUP BY team_name, player_name, runs
ORDER BY runs DESC, team_name ASC, player_name ASC) AS foo_outer
INNER JOIN (
SELECT team_name, MAX(runs) as maxruns
FROM
(SELECT team_name, player_name, runs
FROM
(SELECT team.team_name, player.player_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY team.team_name, player.player_id) AS runs
FROM team, player, player_match, match, outcome, season, ball_by_ball, batsman_scored
WHERE team.team_id = player_match.team_id AND player_match.player_id = player.player_id
AND player_match.match_id = match.match_id AND match.outcome_id = outcome.outcome_id
AND match.season_id = season.season_id AND season.season_year = 2010
AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id) AS foo
GROUP BY team_name, player_name, runs
ORDER BY runs DESC, team_name ASC, player_name ASC) AS foo_outer
GROUP BY team_name) AS topruns ON foo_outer.team_name = topruns.team_name AND foo_outer.runs = topruns.maxruns
ORDER BY team_name ASC, player_name ASC, runs ASC;

