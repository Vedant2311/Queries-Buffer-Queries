--1--
/* Returns the bowlers that took 5 or more wickets in a single match */
SELECT *
FROM
	(SELECT *
	FROM	
		-- Number of Wickets in a match will be the number of times the match id would be repeated in the table for Wickets
		(SELECT match_id, player_name, team_name, COUNT(match_id) OVER (PARTITION BY player_id, match_id) AS num_wickets
		FROM
			(SELECT ball_by_ball.match_id, player.player_id, player.player_name, team.team_name
			FROM ball_by_ball, wicket_taken, out_type, player_match, team, player
			-- Join the Ball-By-Ball stats and the Wicket stats
			WHERE ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.over_id = wicket_taken.over_id 
				AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
				-- Check the type of wicket that would be considered for the Bowler stats
				AND wicket_taken.kind_out = out_type.out_id AND 
					(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED' 
						OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED' 
						OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
				AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id AND team.team_id = player_match.team_id
				-- Only take the stats for the First and the Second Innings and Ignore the Super-over stats
				AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)) AS foo) AS foo_outer
	WHERE foo_outer.num_wickets>=5) as foo_outer_1
-- Group by the columns to remove repetitions
GROUP BY match_id, player_name, team_name, num_wickets
ORDER BY num_wickets DESC, player_name ASC, team_name ASC, match_id ASC;

--2--
/* Top 3 Man-of-the-Match for the teams in a losing position */
SELECT *
FROM
	(SELECT player.player_name, COUNT(match.match_id) OVER (PARTITION BY player.player_id) AS num_matches
	FROM match, player_match, player, outcome
	WHERE match.match_id = player_match.match_id AND match.man_of_the_match = player_match.player_id AND player_match.player_id = player.player_id 
		-- Remove the situation where the match would end without any results
		AND (NOT player_match.team_id = match.match_winner)	AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT') as foo
GROUP BY player_name, num_matches
ORDER BY num_matches DESC, player_name ASC
LIMIT 3;

--3--
/* Most catches as a fielder in the season 2012 */
SELECT player_name
FROM
	(SELECT player.player_name, COUNT(match.match_id) OVER (PARTITION BY player.player_id) AS num_catches
	FROM match, player_match, player, wicket_taken, out_type, season
	WHERE match.match_id = player_match.match_id AND player_match.player_id = player.player_id
		-- Taking the situation where the wicket was taken by a catch
		AND wicket_taken.match_id = match.match_id AND wicket_taken.kind_out = out_type.out_id AND upper(out_type.out_name) = 'CAUGHT' 
		AND wicket_taken.fielders = player.player_id AND (wicket_taken.innings_no = 1 OR wicket_taken.innings_no = 2)
		AND match.season_id = season.season_id AND season.season_year = 2012) as foo
GROUP BY player_name, num_catches
ORDER BY num_catches DESC, player_name ASC
LIMIT 1;

--4--
/* Number of matches played by the Purple cap player */
SELECT season_year, player_name, num_matches
FROM
	(SELECT season.season_year, player.player_name, COUNT(player_match.match_id) OVER (PARTITION BY player.player_id, season.season_id) AS num_matches
	FROM season, player, player_match, match
	WHERE player.player_id = player_match.player_id AND player_match.match_id = match.match_id
		AND match.season_id = season.season_id AND season.purple_cap = player.player_id) as foo
GROUP BY season_year, player_name, num_matches
ORDER BY season_year ASC, player_name ASC, num_matches ASC;

--5--
/* Players who scored more than 50 runs in a losing situation */
SELECT DISTINCT (player_name)
FROM
	-- Number of runs for the player will be the sum of the runs scored in each ball faced by the player
	(SELECT player.player_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY player.player_id, match.match_id) AS total_runs
	FROM player, player_match, match, batsman_scored, ball_by_ball, outcome
	WHERE player_match.match_id = match.match_id AND player_match.player_id = player.player_id
		-- Take only the first and second innings to compute the stats for the player
		AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
		AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id 
		AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id
		AND (NOT match.match_winner = player_match.team_id) AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT') AS foo
WHERE total_runs > 50
ORDER BY player_name ASC;

--6--
/* Top 5 teams with most left handed batsmen */
WITH rws AS 
	-- Adding a sequential row number corresponding to each groups formed according to the season year
	(SELECT left_stats.*, row_number() OVER (PARTITION BY season_year) AS rank
	FROM
		(SELECT DISTINCT season_year, team_name, num_batsmen
		FROM
			-- Getting the stats of the number of left handed batsmen per team per season
			(SELECT foo.*, COUNT(player_id) OVER (PARTITION BY season_id, team_id) AS num_batsmen  
			FROM
				(SELECT DISTINCT season.season_year, season.season_id, team.team_name, team.team_id, player.player_name, player.player_id
				FROM season, player_match, player, match, team, country, batting_style
				WHERE match.match_id = player_match.match_id AND player_match.player_id = player.player_id AND match.season_id = season.season_id
					AND player.batting_hand = batting_style.batting_id AND batting_style.batting_hand = 'Left-hand bat' AND player_match.team_id = team.team_id
					AND player.country_id = country.country_id AND (NOT upper(country.country_name) = 'INDIA')) AS foo) AS foo_outer
		ORDER BY season_year ASC, num_batsmen DESC, team_name ASC) AS left_stats)
SELECT season_year, team_name, rank FROM rws
-- Getting the Top 5 for each season by taking only the indices lesser than Five. The rows were already sorted in a decreasing order w.r.t num_batsmen
WHERE rank<=5;

--7--
/* Maximum match wins for the season 2009. Will also consider the wins by SUPEROVER here */
SELECT team_name
FROM 
	(SELECT team.team_name, COUNT(match.match_id) OVER (PARTITION BY team.team_id) AS num_wins
	FROM season, match, team, outcome
	WHERE outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT'
		AND season.season_id = match.season_id AND match.match_winner = team.team_id AND season.season_year = 2009) AS foo
GROUP BY team_name, num_wins
ORDER BY num_wins DESC, team_name ASC;

--8--
/* Top scorer of each team in the season 2010 */
SELECT foo_outer.team_name, foo_outer.player_name, foo_outer.runs
FROM
	-- This table will contain the summary of the runs scored by all the players of all the teams
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
	-- Join the above table with a modification of itself that consists of the stats of the maximum runs scored by any player per each team
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

--9--
/* Top 3 teams with the maximum number of Sixes */
SELECT team_name, opponent_team_name, number_of_sixes
FROM
	(SELECT playing.team_name AS team_name, opponent.team_name AS opponent_team_name, 
		COUNT(batsman_scored.innings_no) OVER (PARTITION BY playing.team_id, opponent.team_id, match.match_id) AS number_of_sixes
	FROM team AS playing, team AS opponent, batsman_scored, ball_by_ball, player, player_match, match, season
	WHERE match.match_id = player_match.match_id AND player.player_id = player_match.player_id AND playing.team_id = player_match.team_id
		-- The Playing team is the Team-1 and the opponent team is Team-2 OR vice-versa
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

--11--
/* Left Handed batsmen who scored >=150 runs and took >=5 wickets and played >=10 matches in a season*/
SELECT wickets_final.season_year AS season_year, wickets_final.player_name AS player_name, wickets_final.num_wickets AS num_wickets, runs_table.runs AS runs
FROM
	-- Constructing the Table for the wickets for each player 
	(SELECT season_year, player_name, num_wickets
	FROM
		(SELECT season.season_year, player.player_name, COUNT(match.match_id) OVER (PARTITION BY season.season_id, player.player_id) AS num_wickets
		FROM season, match, player_match, player, wicket_taken, ball_by_ball, out_type
		WHERE season.season_id = match.season_id AND match.match_id = player_match.match_id AND player_match.player_id = player.player_id
			AND ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.match_id = match.match_id AND ball_by_ball.over_id = wicket_taken.over_id 
			AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
			AND player.player_id = ball_by_ball.bowler AND wicket_taken.kind_out = out_type.out_id AND 
				(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED' 
					OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED' 
					OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
			AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)) AS foo
	GROUP BY season_year, player_name, num_wickets) AS wickets_final,
	-- Constructing a table corresponding to left handed batsmen having scored more than 150 runs per season
	(SELECT season_year, player_name, runs
		FROM
			(SELECT season.season_year, player.player_name, SUM(batsman_scored.runs_scored) OVER (PARTITION BY season.season_id, player.player_id) as runs
			FROM season, player_match, player, match, batsman_scored, ball_by_ball, batting_style
			WHERE season.season_id = match.season_id AND player_match.match_id = match.match_id AND player.player_id = player_match.player_id
				AND batsman_scored.match_id = match.match_id AND (batsman_scored.innings_no = 1 OR batsman_scored.innings_no = 2)
				AND ball_by_ball.match_id = batsman_scored.match_id AND ball_by_ball.over_id = batsman_scored.over_id 
				AND ball_by_ball.ball_id = batsman_scored.ball_id AND ball_by_ball.innings_no = batsman_scored.innings_no AND ball_by_ball.striker = player.player_id
				AND player.batting_hand = batting_style.batting_id AND batting_style.batting_hand = 'Left-hand bat') AS foo
		GROUP BY season_year, player_name, runs) AS runs_table,
	-- Constructing a table corrresponding to the number of matches played by the player
	(SELECT season_year, player_name, total_matches
	FROM
		(SELECT season.season_year, player.player_name, COUNT(match.match_id) OVER (PARTITION BY season.season_id, player.player_id) as total_matches
			FROM season, player_match, player, match
			WHERE season.season_id = match.season_id AND match.match_id = player_match.match_id AND player_match.player_id = player.player_id) AS foo
	GROUP BY season_year, player_name, total_matches) AS matches_table
-- Joining the above defined tables according to the conditions specified in the problem statement
WHERE runs_table.season_year = wickets_final.season_year AND runs_table.player_name = wickets_final.player_name 
	ANd matches_table.season_year = wickets_final.season_year AND matches_table.player_name = wickets_final.player_name
	AND runs_table.runs>=150 AND wickets_final.num_wickets>=5 AND matches_table.total_matches>=10
ORDER BY num_wickets DESC, runs DESC, player_name ASC, season_year ASC;
	
--12--
/* Highest Number of Wickets taken by a player in a match */
SELECT *
FROM
	(SELECT match_id, player_name, team_name, num_wickets, season_year
	FROM
		(SELECT ball_by_ball.match_id, player.player_name, team.team_name, 
			COUNT(match.match_id) OVER (PARTITION BY player.player_id, match.match_id) AS num_wickets, season.season_year
		FROM ball_by_ball, wicket_taken, out_type, player_match, team, player, season, match
		WHERE ball_by_ball.match_id = wicket_taken.match_id AND ball_by_ball.over_id = wicket_taken.over_id 
			AND ball_by_ball.ball_id = wicket_taken.ball_id AND ball_by_ball.innings_no = wicket_taken.innings_no
			AND wicket_taken.kind_out = out_type.out_id AND 
				(upper(out_type.out_name)='CAUGHT' OR upper(out_type.out_name)='BOWLED' 
					OR upper(out_type.out_name)='LBW' OR upper(out_type.out_name)='STUMPED' 
					OR upper(out_type.out_name)='CAUGHT AND BOWLED' OR upper(out_type.out_name)='HIT WICKET')
			AND player_match.player_id = ball_by_ball.bowler AND player_match.match_id = ball_by_ball.match_id AND team.team_id = player_match.team_id
			AND player.player_id = player_match.player_id AND (ball_by_ball.innings_no = 1 OR ball_by_ball.innings_no = 2)
			AND season.season_id = match.season_id AND match.match_id = player_match.match_id) AS foo
	GROUP BY match_id, player_name, team_name, num_wickets, season_year) AS player_wickets
ORDER BY num_wickets DESC, player_name ASC, match_id ASC, team_name ASC, season_year ASC
LIMIT 1;
	
--13--
/* All players who have played in all seasons */
SELECT DISTINCT player_name
FROM
	(SELECT player_name, COUNT(season_id) OVER (PARTITION BY player_name) AS num_seasons
	FROM
		(SELECT DISTINCT player.player_name, match.season_id
		FROM player, player_match, match
		WHERE player_match.match_id = match.match_id AND player_match.player_id = player.player_id
		ORDER BY player.player_name, match.season_id) AS foo) AS season_stats
-- Check if the number of seasons played by the player equals the total number of seasons in the DB
WHERE num_seasons = (SELECT COUNT(DISTINCT season_id) FROM season)
ORDER BY player_name ASC;

--14--
/* Top 3 teams for each season based on number of batsmen with >=50 score in a winning match */
WITH rws AS (
	-- Adding a series of row numbers for each group corresponding to a season year
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
-- Getting the Top 3 for each season by taking only the indices lesser than three. The rows were already sorted in a decreasing order w.r.t num_batsmen
WHERE rand <=3 
ORDER BY season_year ASC, num_batsmen DESC, team_name ASC, match_id ASC;

--16--
/* All the teams against which RCB lost a match in 2008 */
SELECT team_name
FROM
	(SELECT DISTINCT opponent.team_name, COUNT(match.match_id) OVER (PARTITION BY opponent.team_id) AS num_wins
	FROM season, match, team AS rcb, team AS opponent, outcome
	WHERE season.season_id = match.season_id AND season.season_year = 2008
		-- RCB is either of team-1 or team-2. And it is not the winner
		AND ((match.team_1 = rcb.team_id AND rcb.team_name = 'Royal Challengers Bangalore') OR (match.team_2 = rcb.team_id AND rcb.team_name = 'Royal Challengers Bangalore')) 
		AND outcome.outcome_id = match.outcome_id AND NOT upper(outcome.outcome_type) = 'NO RESULT' 
		AND match.match_winner = opponent.team_id AND NOT match.match_winner = rcb.team_id) AS foo
ORDER BY num_wins DESC, team_name ASC;

--17--
/* The player for each team with the maximum number of MOM */
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

--18--
/* Top 5 players in >=3 teams and have given >20 runs per over max no of times. Super Over considered */
SELECT max_runs.player_name
	FROM
		-- Get the stats for the bowlers who conceded more than 20 runs per over in the proper order as this will be used later
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
		-- Get the players having played in 3 or more teams 
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
