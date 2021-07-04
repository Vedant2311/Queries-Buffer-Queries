SELECT team_name
FROM
(SELECT team.team_name, COUNT(match.match_id) OVER (PARTITION BY team.team_id) AS num_wins
FROM season, match, team, outcome
WHERE outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT'
AND season.season_id = match.season_id AND match.match_winner = team.team_id AND season.season_year = 2009) AS foo
GROUP BY team_name, num_wins
ORDER BY num_wins DESC, team_name ASC;

