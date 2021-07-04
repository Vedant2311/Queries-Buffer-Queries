SELECT *
FROM
(SELECT player.player_name, COUNT(match.match_id) OVER (PARTITION BY player.player_id) AS num_matches
FROM match, player_match, player, outcome
WHERE match.match_id = player_match.match_id AND match.man_of_the_match = player_match.player_id AND player_match.player_id = player.player_id
AND (NOT player_match.team_id = match.match_winner)	AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT') as foo
GROUP BY player_name, num_matches
ORDER BY num_matches DESC, player_name ASC
LIMIT 3;

