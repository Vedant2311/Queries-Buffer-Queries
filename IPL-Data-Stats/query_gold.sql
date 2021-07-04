--1--
with w as(select ball_by_ball.match_id, ball_by_ball.bowler, team_bowling, count(ball_by_ball.bowler) as num_wickets 
		from ball_by_ball, wicket_taken, out_type where ball_by_ball.match_id=wicket_taken.match_id 
		and ball_by_ball.over_id=wicket_taken.over_id and ball_by_ball.ball_id=wicket_taken.ball_id 
		and ball_by_ball.innings_no=wicket_taken.innings_no and kind_out=out_type.out_id 
		and out_type.out_id in (1, 2, 4, 6, 7, 8) and ball_by_ball.innings_no in (1,2)
		group by ball_by_ball.match_id, ball_by_ball.bowler, team_bowling 
		having count(ball_by_ball.bowler)>=5) 
select w.match_id, player_name, team_name, w.num_wickets 
from player, team, w 
where player.player_id=w.bowler and team.team_id=w.team_bowling 
order by num_wickets DESC, player_name ASC, team_name ASC, match_id ASC;
--2--
select player.player_name,count(player_name) as num_matches
from player_match,match,player
where player_match.player_id = match.man_of_the_match and player_match.match_id = match.match_id 
	  and player.player_id = player_match.player_id and match.match_winner!=player_match.team_id 
	  and match.match_winner is not null
group by player.player_name
order by num_matches desc,player_name
limit 3;
--3--
WITH a AS (SELECT fielders, COUNT(fielders) AS catches 
		   FROM wicket_taken, match, season 
		   WHERE match.match_id = wicket_taken.match_id AND wicket_taken.kind_out = 1 
		   AND match.season_id = season.season_id AND season.season_year = 2012 
		   GROUP BY fielders) 
select player_name 
from player, a 
where a.fielders=player.player_id 
order by catches desc, player_name asc 
limit 1;
--4--
select g.season_year,player.player_name,g.num_matches
from(select f.player_id,f.season_year,count(f.season_year) as num_matches
	from (select player_match.match_id,season.season_id,player_match.player_id,season.season_year
			from season,player_match
			where season.purple_cap=player_match.player_id) as f,match
	where match.season_id = f.season_id and match.match_id = f.match_id
	group by f.player_id,f.season_id,f.season_year) as g,player
where g.player_id = player.player_id
order by g.season_year;
--5--
select player.player_name 
from(select ball_by_ball.match_id,team_batting,striker,sum(runs_scored) as runs
	from ball_by_ball,batsman_scored
	where ball_by_ball.match_id=batsman_scored.match_id and  ball_by_ball.over_id = batsman_scored.over_id and 
	ball_by_ball.ball_id = batsman_scored.ball_id and ball_by_ball.innings_no = batsman_scored.innings_no and 
	ball_by_ball.innings_no!=3 and ball_by_ball.innings_no!=4
	group by ball_by_ball.match_id,team_batting,striker)as f,match,player
where match.match_id = f.match_id and match.match_winner!=team_batting and player.player_id=f.striker and runs>50
group by player_name
order by player_name;
--6--
select rank_filter.season_year, rank_filter.team_name, rank as position 
from(
	select season_year, team_name, count(team_name) as cnt,
	rank() over(
	    partition by season_year
	    order by count(team_name) DESC, team_name ASC
	)
	from(
		select season_year, team_name, player.player_id
		from season, match, player, player_match, batting_style, team, country
		where (season.season_id=match.season_id) and
		(match.match_id=player_match.match_id) and
		(player.player_id=player_match.player_id) and
		(player.batting_hand=batting_style.batting_id) and
		(batting_style.batting_hand='Left-hand bat') and
		(player_match.team_id=team.team_id) and
		(player.country_id=country.country_id) and
		(country.country_name!='India')
		group by season_year, team_name, player.player_id
	) as temp
	group by season_year, team_name
)rank_filter where rank<=5
order by season_year ASC, position ASC;
--7--
select team_name
from(select match_winner,count(match_winner) as num from match
	where season_id=2 and match_winner is not null
	group by match_winner) as f,team
where team.team_id=match_winner
order by num desc,team_name;
--8--
select team_name,player_name,runs_scored as runs
from(select rank_filter.team_batting, rank_filter.striker, rank_filter.score as runs_scored from(
 select team_batting,striker,score, player_name, rank() over(
 partition by team_batting
 order by score DESC, player_name asc)
 from(select team_batting,striker,sum(runs) as score
 from(select ball_by_ball.match_id,team_batting,striker,sum(runs_scored) as runs
 from ball_by_ball,batsman_scored
 where ball_by_ball.match_id=batsman_scored.match_id and ball_by_ball.over_id = batsman_scored.over_id and 
 ball_by_ball.ball_id = batsman_scored.ball_id and ball_by_ball.innings_no = batsman_scored.innings_no and 
 ball_by_ball.innings_no!=3 and ball_by_ball.innings_no!=4
 group by ball_by_ball.match_id,team_batting,striker) as f,
 (select match_id from match where season_id=3) as g
 where g.match_id = f.match_id
 group by team_batting,striker) as f, player
 where striker=player.player_id
 )rank_filter where rank=1) as d,player,team
where d.team_batting=team_id and d.striker=player_id
order by team_name asc;
--9--
select t_1.team_name, t_2.team_name as opponent_team_name, count(runs_scored) as number_of_sixes 
from season, match, ball_by_ball, batsman_scored, team as t_1, team as t_2 
where season.season_year=2008 and match.season_id=season.season_id and 
match.match_id=ball_by_ball.match_id and ball_by_ball.match_id=batsman_scored.match_id and 
ball_by_ball.over_id=batsman_scored.over_id and ball_by_ball.ball_id=batsman_scored.ball_id and 
ball_by_ball.innings_no=batsman_scored.innings_no and runs_scored=6 and t_1.team_id=team_batting 
and t_2.team_id=team_bowling and ball_by_ball.innings_no IN (1, 2) 
group by match.match_id, t_1.team_name, opponent_team_name 
order by number_of_sixes DESC, t_1.team_name ASC, opponent_team_name ASC 
limit 3;
--10--
select rank_filter.bowling_skill as bowling_category, rank_filter.player_name,  round(cast(rank_filter.batting_avg as numeric), 2) as batting_average from(
    select player_name, bowling_skill, batting_avg, rank() over(
        partition by bowling_skill
        order by batting_avg DESC, wickets desc
    )
    from
    (
        with players_avg as (
            with custom_seasons as (
                select match_id
                from match
            ), batsman_runs as (
                with ball_info as (
                    select match_id, over_id, ball_id, innings_no, striker
                    from ball_by_ball
                )
                select ball_info.match_id, striker as batsman, sum(runs_scored) as runs
                from ball_info, batsman_scored
                where ball_info.match_id = batsman_scored.match_id
                and ball_info.over_id = batsman_scored.over_id
                and ball_info.ball_id = batsman_scored.ball_id
                and ball_info.innings_no = batsman_scored.innings_no
                and ball_info.innings_no in (1, 2)
                group by ball_info.match_id, batsman
                order by runs desc
            )
            select player_id, avg(runs) as avg_runs
            from custom_seasons, batsman_runs, player
            where batsman_runs.match_id = custom_seasons.match_id
            and player.player_id = batsman_runs.batsman
            group by player_id
        ), bowler_wickets as (
            select bowler, count(bowler) as wickets
            from ball_by_ball, wicket_taken, player
            where ball_by_ball.match_id = wicket_taken.match_id
            and ball_by_ball.over_id = wicket_taken.over_id
            and ball_by_ball.ball_id = wicket_taken.ball_id
            and ball_by_ball.innings_no = wicket_taken.innings_no
            and ball_by_ball.innings_no in (1, 2)
            and kind_out in (1, 2, 4, 6, 7, 8)
            and player.player_id = bowler
            group by bowler
        )
        select player_name, bowling_style.bowling_skill, avg_runs as batting_avg, bowler_wickets.wickets
        from player, bowling_style, bowler_wickets, players_avg
        where player.player_id = players_avg.player_id
        and player.bowling_skill = bowling_style.bowling_id
        and player.player_id = bowler_wickets.bowler
        and bowler_wickets.wickets >= all (select avg(wickets) from bowler_wickets where wickets > 0)
        order by batting_avg desc, player_name asc
    ) as temp
) rank_filter where rank=1
order by bowling_skill asc;
--11--
select season.season_year,player.player_name,f.wikki as num_wickets,f.t_runs as runs
from(select hand.player_id,total_wickets.season_id,total_runs.t_runs,total_wickets.wikki
	from(select m.player_id
		from(select player_id
			from(select player_id,season_id,count(player_id) as matches
				from match,player_match
				where match.match_id=player_match.match_id
				group by player_id,season_id
				order by player_id,season_id) as f
			where matches>9
			group by player_id) as m,player
		where m.player_id=player.player_id and player.batting_hand=1)as hand,
	(select season_id,striker,t_runs
	from(select season_id,striker,sum(runs) as t_runs
		from(select ball_by_ball.match_id,striker,sum(runs_scored) as runs
			from ball_by_ball,batsman_scored
			where ball_by_ball.match_id=batsman_scored.match_id and  ball_by_ball.over_id = batsman_scored.over_id and 
			ball_by_ball.ball_id = batsman_scored.ball_id and ball_by_ball.innings_no = batsman_scored.innings_no and 
			ball_by_ball.innings_no!=3 and ball_by_ball.innings_no!=4
			group by ball_by_ball.match_id,striker) as f,match
		where match.match_id=f.match_id
		group by striker,season_id) as final
	where t_runs>149) as total_runs,
	(select bowler,season_id,wikki
	from(select bowler,season_id,sum(num_wickets) as wikki
		from(select ball_by_ball.match_id,bowler,count(bowler) as num_wickets
			from ball_by_ball,wicket_taken
			where ball_by_ball.match_id=wicket_taken.match_id and  ball_by_ball.over_id = wicket_taken.over_id and 
			ball_by_ball.ball_id = wicket_taken.ball_id and ball_by_ball.innings_no = wicket_taken.innings_no and 
			kind_out!=3 and kind_out!=5 and kind_out!=9 and ball_by_ball.innings_no!=3 and ball_by_ball.innings_no!=4
			group by ball_by_ball.match_id,bowler) as f,match
		where match.match_id=f.match_id
		group by bowler,season_id) as t
	where wikki>4) as total_wickets
where hand.player_id=total_runs.striker and total_runs.striker=total_wickets.bowler and
total_runs.season_id=total_wickets.season_id) as f,season,player
where player.player_id=f.player_id and season.season_id=f.season_id 
order by num_wickets desc,runs desc,player.player_name,season.season_year;
--12--
select temp.match_id, player_name, team_name, num_wickets, season_year
from player, team, season,
(select match.season_id, match.match_id, ball_by_ball.bowler, ball_by_ball.team_bowling, count(bowler) as num_wickets
from match, ball_by_ball, wicket_taken, out_type
where (match.match_id=ball_by_ball.match_id) and
(ball_by_ball.match_id=wicket_taken.match_id) and
(ball_by_ball.over_id=wicket_taken.over_id) and
(ball_by_ball.ball_id=wicket_taken.ball_id) and
(ball_by_ball.innings_no=wicket_taken.innings_no) and
(ball_by_ball.innings_no<3) and
(wicket_taken.kind_out=out_type.out_id) and
(out_name='caught' or out_name='bowled' or out_name='lbw' or out_name='stumped' or out_name='caught and bowled' or out_name='hit wicket')
group by match.season_id, match.match_id, bowler, team_bowling) as temp
where (temp.bowler=player.player_id) and
(temp.team_bowling=team.team_id) and
(temp.season_id=season.season_id)
order by num_wickets desc, player_name asc, match_id asc, team_name asc,
season_year asc
limit 1;
--13--
select player_name from
(select player_id, count(season_id) as num_seasons from
(select distinct player_id, season_id from
match, player_match
where (match.match_id=player_match.match_id)
order by player_id asc, season_id asc
)as tmp
group by player_id) as tmp1,
(select count(season_id) as num_seasons from season) as tmp2,
player
where (tmp1.player_id=player.player_id) and
(tmp1.num_seasons=tmp2.num_seasons)
order by player_name asc;
--14--
select rank_filter.season_year, rank_filter.match_id, rank_filter.team_name from
(
select season_year, team_name, match_id, count(team_batting),
rank() over(
    partition by season_year
    order by count(team_batting) desc, team_name asc, match_id asc
) from
(
select season_id, ball_by_ball.match_id, team_batting, striker, sum(runs_scored) as tot_runs from
ball_by_ball, batsman_scored, match
where (ball_by_ball.match_id=batsman_scored.match_id) and
(ball_by_ball.over_id=batsman_scored.over_id) and
(ball_by_ball.ball_id=batsman_scored.ball_id) and
(ball_by_ball.innings_no=batsman_scored.innings_no) and
(ball_by_ball.innings_no<3) and
(match.match_id=ball_by_ball.match_id) and
(match.match_winner=team_batting)
group by season_id, ball_by_ball.match_id, team_batting, striker
having sum(runs_scored)>=50
) as tmp, season, team
where (tmp.season_id=season.season_id) and
(team.team_id=tmp.team_batting)
group by season_year, team_name, match_id
)rank_filter where rank<=3
order by season_year asc, rank asc;
--15--
select tmp1.season_year, top_batsman, max_runs, top_bowler, max_wickets from
(
select rank_filter1.season_year, rank_filter1.player_name as top_batsman, rank_filter1.tot_runs as max_runs from
(
select season_year, player_name, tot_runs,
rank() over(
    partition by season_year
    order by tot_runs desc, player_name asc
) from
season, player,
(select season_id, striker, sum(runs_scored) as tot_runs from
match, ball_by_ball, batsman_scored
where (match.match_id = ball_by_ball.match_id) and
(ball_by_ball.match_id=batsman_scored.match_id) and
(ball_by_ball.over_id=batsman_scored.over_id) and
(ball_by_ball.innings_no=batsman_scored.innings_no) and
(ball_by_ball.innings_no<3) and
(ball_by_ball.ball_id=batsman_scored.ball_id)
group by season_id, striker) as tmp
where (season.season_id=tmp.season_id) and
(striker=player_id)
)rank_filter1 where rank=2
) as tmp1,
(
select rank_filter2.season_year, rank_filter2.player_name as top_bowler, rank_filter2.num_wickets as max_wickets from
(
select season_year, player_name, num_wickets,
rank() over(
    partition by season_year
    order by num_wickets desc, player_name asc
) from
season, player,
(select season_id, bowler, count(bowler) as num_wickets from
match, ball_by_ball, wicket_taken, out_type
where (match.match_id = ball_by_ball.match_id) and
(ball_by_ball.match_id=wicket_taken.match_id) and
(ball_by_ball.over_id=wicket_taken.over_id) and
(ball_by_ball.innings_no=wicket_taken.innings_no) and
(ball_by_ball.ball_id=wicket_taken.ball_id) and
(ball_by_ball.innings_no<3) and
(wicket_taken.kind_out=out_type.out_id) and
(out_name='caught' or out_name='bowled' or out_name='lbw' or out_name='stumped' or out_name='caught and bowled' or out_name='hit wicket')
group by season_id, bowler) as tmp
where (season.season_id=tmp.season_id) and
(bowler=player_id)
)rank_filter2 where rank=2
) as tmp2
where (tmp1.season_year=tmp2.season_year)
order by season_year asc;
--16--
select team_name from
(
select t1.team_id+t2.team_id-t3.team_id as team_ids, count(t1.team_id+t2.team_id-t3.team_id) as num_matches1 from
team as t1, team as t2, team as t3, match, season
where (match_winner=t1.team_id+t2.team_id-t3.team_id) and
(t1.team_id=team_1) and
(t2.team_id=team_2) and
(t1.team_id=t3.team_id or t2.team_id=t3.team_id) and
(t3.team_name='Royal Challengers Bangalore') and
(match.season_id=season.season_id) and
(season_year=2008)
group by team_ids
) as tmp, team
where (tmp.team_ids=team.team_id)
order by num_matches1 desc, team_name asc;
--17--
select rank_filter.team_name, rank_filter.player_name, rank_filter.num_moms as count
from(
select team_name, player_name, num_moms,
rank() over(
    partition by team_name
    order by num_moms desc, player_name asc
)
from player, team, 
(
select player_match.team_id, man_of_the_match, count(man_of_the_match) as num_moms from
match, player_match
where (match.match_id=player_match.match_id)
and (player_match.player_id=match.man_of_the_match)
group by player_match.team_id, man_of_the_match
) as tmp
where (tmp.team_id=team.team_id) and
(tmp.man_of_the_match=player_id)
)rank_filter where rank=1
order by team_name asc;
--18--
select player_name from (
    with player_team as (
        select player_id, count(player_id) as teams_count
        from (
            select player_id, team_id 
            from player_match
            group by player_id, team_id
        ) as temp
        group by player_id
    ), match_over_bowler as (
        select ball_by_ball.match_id, ball_by_ball.over_id, ball_by_ball.bowler, sum(batsman_scored.runs_scored) as runs_in_over
        from ball_by_ball, batsman_scored
        where ball_by_ball.match_id = batsman_scored.match_id
        and ball_by_ball.over_id = batsman_scored.over_id
        and ball_by_ball.ball_id = batsman_scored.ball_id
        and ball_by_ball.innings_no = batsman_scored.innings_no
        group by ball_by_ball.match_id, ball_by_ball.over_id, ball_by_ball.bowler
    )
    select player_name, count(player_name)
    from player_team, match_over_bowler, player
    where teams_count >= 3
    and runs_in_over > 20
    and player.player_id = bowler
    and player_team.player_id = player.player_id
    group by player_name
    order by count desc, player_name asc
    limit 5
) as temp;
--19--
with bat_runs as (
    select ball_by_ball.match_id, team_id, sum(runs_scored) as runs
    from ball_by_ball, batsman_scored, player_match
    where ball_by_ball.match_id = batsman_scored.match_id
    and ball_by_ball.over_id = batsman_scored.over_id
    and ball_by_ball.ball_id = batsman_scored.ball_id
    and ball_by_ball.innings_no = batsman_scored.innings_no
    and ball_by_ball.innings_no in (1, 2)
    and player_match.match_id = ball_by_ball.match_id
    and player_match.player_id = striker
    group by ball_by_ball.match_id, team_id
), matches as (
    select match_id 
    from match, season
    where match.season_id = season.season_id
    and season.season_year = 2010
)
select team_name, round(cast(avg(runs) as numeric), 2) as avg_runs
from bat_runs, matches, team
where team.team_id = bat_runs.team_id
and matches.match_id = bat_runs.match_id
group by team_name
order by team_name asc;
--20--
select player_name as player_names from (
    select player_name, count(player_name)
    from wicket_taken, player
    where over_id = 1
    and player.player_id = wicket_taken.player_out
    group by player_name
    order by count desc, player_name asc
    limit 10
) as temp;
--21--
with custom_matches as (
    select match_id, team_1, team_2, match_winner
    from match
), custom_ball as (
    select match_id, over_id, ball_id, team_batting
    from ball_by_ball
    where innings_no = 2
)
select custom_ball.match_id, team_a.team_name as team_1, team_b.team_name as team_2, winner.team_name as winner, count(custom_ball.match_id) as number_of_boundaries
from custom_matches, custom_ball, batsman_scored, team as team_a, team as team_b, team as winner
where custom_matches.match_id = custom_ball.match_id
and match_winner = team_batting
and match_winner = winner.team_id
and custom_matches.team_1 = team_a.team_id
and custom_matches.team_2 = team_b.team_id
and custom_ball.match_id = batsman_scored.match_id
and custom_ball.over_id = batsman_scored.over_id
and custom_ball.ball_id = batsman_scored.ball_id
and custom_ball.team_batting = custom_matches.match_winner
and batsman_scored.innings_no = 2
and batsman_scored.runs_scored in (4, 6)
group by custom_ball.match_id, team_a.team_name, team_b.team_name, winner.team_name
order by number_of_boundaries asc, custom_ball.match_id asc
limit 3;
--22--
with runs_conceded as (
    select bowler, sum(runs_scored)
    from ball_by_ball, batsman_scored
    where ball_by_ball.match_id = batsman_scored.match_id
    and ball_by_ball.over_id = batsman_scored.over_id
    and ball_by_ball.ball_id = batsman_scored.ball_id
    and ball_by_ball.innings_no = batsman_scored.innings_no
    group by bowler
), wickets as (
    select bowler, count(bowler)
    from ball_by_ball, wicket_taken
    where ball_by_ball.match_id = wicket_taken.match_id
    and ball_by_ball.over_id = wicket_taken.over_id
    and ball_by_ball.ball_id = wicket_taken.ball_id
    and ball_by_ball.innings_no = wicket_taken.innings_no
    and kind_out in (1, 2, 4, 6, 7, 8)
    group by bowler
)
select country_name
from runs_conceded, wickets, player, country
where wickets.count != 0
and runs_conceded.bowler = wickets.bowler
and player.player_id = wickets.bowler
and country.country_id = player.country_id
order by runs_conceded.sum/wickets.count asc
limit 3;