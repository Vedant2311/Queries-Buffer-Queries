WITH rws AS
(SELECT left_stats.*, row_number() OVER (PARTITION BY season_year) AS rank
FROM
(SELECT DISTINCT season_year, team_name, num_batsmen
FROM
(SELECT foo.*, COUNT(player_id) OVER (PARTITION BY season_id, team_id) AS num_batsmen
FROM
(SELECT DISTINCT season.season_year, season.season_id, team.team_name, team.team_id, player.player_name, player.player_id
FROM season, player_match, player, match, team, country, batting_style
WHERE match.match_id = player_match.match_id AND player_match.player_id = player.player_id AND match.season_id = season.season_id
AND player.batting_hand = batting_style.batting_id AND batting_style.batting_hand = 'Left-hand bat' AND player_match.team_id = team.team_id
AND player.country_id = country.country_id AND (NOT upper(country.country_name) = 'INDIA')) AS foo) AS foo_outer
ORDER BY season_year ASC, num_batsmen DESC, team_name ASC) AS left_stats)
SELECT season_year, team_name, rank FROM rws
WHERE rank<=5;

