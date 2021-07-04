SELECT team_name
FROM
(SELECT DISTINCT opponent.team_name, COUNT(match.match_id) OVER (PARTITION BY opponent.team_id) AS num_wins
FROM season, match, team AS rcb, team AS opponent, outcome
WHERE season.season_id = match.season_id AND season.season_year = 2008
AND ((match.team_1 = rcb.team_id AND rcb.team_name = 'Royal Challengers Bangalore') OR (match.team_2 = rcb.team_id AND rcb.team_name = 'Royal Challengers Bangalore'))
AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT'
AND match.match_winner = opponent.team_id AND NOT match.match_winner = rcb.team_id) AS foo
ORDER BY num_wins DESC, team_name ASC;

