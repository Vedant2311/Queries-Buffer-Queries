WITH rws AS
(SELECT foo.*, row_number() OVER (PARTITION BY team_name) AS rand
FROM
(SELECT DISTINCT team.team_name, player.player_name, COUNT(match.match_id) OVER (PARTITION BY player.player_id, team.team_id) AS count
FROM player, player_match, match, team
WHERE player_match.match_id = match.match_id AND player_match.player_id = player.player_id
AND player_match.team_id = team.team_id AND match.man_of_the_match = player.player_id
ORDER BY team_name ASC, count DESC, player_name ASC) AS foo)
SELECT team_name, player_name, count FROM rws
WHERE rand<=1
ORDER BY team_name ASC, count DESC, player_name ASC;

