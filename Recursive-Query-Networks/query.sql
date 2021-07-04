--PREAMBLE--
CREATE VIEW all_paths AS
WITH RECURSIVE reachable_cities (origin, dest, origin_state, dest_state) AS
	((SELECT DISTINCT origin.city as origin, dest.city as dest, origin.state as origin_state, dest.state as dest_state
	  FROM airports as origin, airports as dest, flights
	  WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid)
	UNION 
	 (SELECT DISTINCT origin.city, reachable_cities.dest, origin.state, reachable_cities.dest_state
	  FROM reachable_cities, airports as origin, airports as dest, flights
	  WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND dest.city = reachable_cities.origin
	 ))
SELECT * FROM reachable_cities;

CREATE VIEW all_cities_pairs AS
SELECT source.city as origin, dest.city as dest
FROM airports as source, airports as dest
WHERE NOT source.airportid = dest.airportid;

CREATE VIEW all_month_days AS
SELECT generate_series AS dayofmonth, 0 AS flight_delay FROM GENERATE_SERIES(1,31);

CREATE VIEW info_paths AS 
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.city as origin, dest.city as dest, 1 as len, 
	 	concat(',', origin.city, ',', dest.city, ',') as nodes,
	 	(CASE WHEN origin.city = dest.city THEN 1 ELSE 0 END) AS has_cycle
	 FROM airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.city as dest, len + 1,
	 	concat(get_paths.nodes, dest.city, ','),
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.city,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND get_paths.dest = origin.city 
	 	AND get_paths.has_cycle = 0
	)
SELECT * FROM get_paths;

CREATE VIEW info_paths_interstate AS
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.city as origin, dest.city as dest, 1 as len, 
	 	concat(',', origin.city, ',', dest.city, ',') as nodes,
	 	(CASE WHEN origin.city = dest.city THEN 1 ELSE 0 END) AS has_cycle
	 FROM airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND NOT(origin.state = dest.state)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.city as dest, len + 1,
	 	concat(get_paths.nodes, dest.city, ','),
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.city,',%') THEN 1 ELSE 0 END) AS has_cycle	 	
	 FROM get_paths, airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND get_paths.dest = origin.city 
	 	AND get_paths.has_cycle = 0 AND NOT(origin.state = dest.state)
	)	
SELECT * FROM get_paths;

CREATE VIEW info_paths_delay AS 
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.city as origin, dest.city as dest, 1 as len, 
	 	concat(',', origin.city, ',', dest.city, ',') as nodes,
	 	(CASE WHEN origin.city = dest.city THEN 1 ELSE 0 END) AS has_cycle,
	 	(flights.departuredelay + flights.arrivaldelay) AS total_delay
	 FROM airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.city as dest, len + 1,
	 	concat(get_paths.nodes, dest.city, ','),
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.city,',%') THEN 1 ELSE 0 END) AS has_cycle,
	 	(flights.departuredelay + flights.arrivaldelay) AS total_delay
	 FROM get_paths, airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND get_paths.dest = origin.city 
	 	AND get_paths.has_cycle = 0 AND ((flights.arrivaldelay + flights.departuredelay) >= get_paths.total_delay)
	)
SELECT * FROM get_paths;

CREATE VIEW all_authors AS 
SELECT DISTINCT authorid FROM authordetails;

CREATE VIEW all_citations AS
WITH RECURSIVE paper_citation_pairs (paperid1, paperid2) AS 
	(SELECT DISTINCT paperid1, paperid2 FROM citationlist
	 UNION 
	 SELECT DISTINCT paper_citation_pairs.paperid1, citationlist.paperid2 FROM paper_citation_pairs, citationlist WHERE paper_citation_pairs.paperid2 = citationlist.paperid1
	)
SELECT * FROM paper_citation_pairs;

CREATE VIEW total_citations AS
WITH temp_joining AS
	(SELECT DISTINCT all_authors.authorid, non_zero_citations.count
	 FROM all_authors LEFT OUTER JOIN 	 
		 (SELECT DISTINCT authorid, COUNT(paperid2) OVER (PARTITION BY authorid) as count
		  FROM
			(SELECT DISTINCT authordetails.authorid as authorid, all_citations.paperid1 as paperid1, all_citations.paperid2 as paperid2
			 FROM authordetails, all_citations, authorpaperlist
			 WHERE authordetails.authorid = authorpaperlist.authorid AND all_citations.paperid2 = authorpaperlist.paperid) AS foo) AS non_zero_citations
	 ON all_authors.authorid = non_zero_citations.authorid)
SELECT DISTINCT temp_joining.authorid, COALESCE(temp_joining.count,0) as count FROM temp_joining;

CREATE VIEW all_citations_authors AS
SELECT DISTINCT authordetails.authorid, all_citations.paperid2 as paperid
FROM authordetails, all_citations, authorpaperlist
WHERE authordetails.authorid = authorpaperlist.authorid AND all_citations.paperid1 = authorpaperlist.paperid;

CREATE VIEW co_authors AS
SELECT DISTINCT origin.authorid as origin, dest.authorid as dest
FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid);

CREATE VIEW info_paths_collabs AS 
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','),
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	)
SELECT * FROM get_paths;

CREATE VIEW info_paths_collabs_ang AS 
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes, '' as last_gender,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','), origin.gender as last_gender,
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	 	AND origin.age > 35 AND ((get_paths.len=1) OR ((get_paths.len>1) AND (NOT (get_paths.last_gender = origin.gender))))
	)
SELECT * FROM get_paths;

CREATE VIEW info_paths_cited_126 AS
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle, 1 as any_citation_126
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','),
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle,
	 	(CASE WHEN (EXISTS (SELECT 0 FROM all_citations_authors WHERE all_citations_authors.authorid = origin.authorid AND all_citations_authors.paperid = 126)) 
	 	 THEN 1 ELSE 0 END) as any_citation_126
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	)
SELECT * FROM get_paths;

CREATE VIEW info_paths_citations_asc AS
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes, -1::bigint as last_total_citations,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, total_citations
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','), total_citations.count as last_total_citations,
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, total_citations
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	 	AND (total_citations.authorid = origin.authorid) AND ((get_paths.len=1) OR ((get_paths.len>1) AND ((total_citations.count > get_paths.last_total_citations))))
	)
SELECT * FROM get_paths;

CREATE VIEW info_paths_citations_desc AS
WITH RECURSIVE get_paths AS (
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes, 100::bigint as last_total_citations,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, total_citations
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','), total_citations.count as last_total_citations,
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, total_citations
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	 	AND (total_citations.authorid = origin.authorid) AND ((get_paths.len=1) OR ((get_paths.len>1) AND ((total_citations.count < get_paths.last_total_citations))))
	)
SELECT * FROM get_paths;

CREATE VIEW info_paths_citations_both AS
WITH inc_and_dec_paths AS
	(SELECT DISTINCT info_paths_citations_asc.origin, info_paths_citations_asc.nodes, info_paths_citations_asc.dest, info_paths_citations_asc.has_cycle
	 FROM info_paths_citations_asc 
	UNION 
	 SELECT DISTINCT info_paths_citations_desc.origin, info_paths_citations_desc.nodes, info_paths_citations_desc.dest, info_paths_citations_desc.has_cycle
	 FROM info_paths_citations_desc)
SELECT DISTINCT origin, nodes, dest, has_cycle FROM inc_and_dec_paths;

--1--
WITH RECURSIVE reachable_cities (origin, dest, carrier) AS
	((SELECT DISTINCT origin.city as origin, dest.city as dest, flights.carrier as carrier
	  FROM airports as origin, airports as dest, flights
	  WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid)
	UNION 
	 (SELECT DISTINCT origin.city, reachable_cities.dest, reachable_cities.carrier
	  FROM reachable_cities, airports as origin, airports as dest, flights
	  WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND dest.city = reachable_cities.origin
	  	AND reachable_cities.carrier = flights.carrier
	 ))
SELECT DISTINCT dest AS name
FROM reachable_cities
WHERE reachable_cities.origin = 'Albuquerque'
ORDER BY name ASC;

--2--
WITH RECURSIVE reachable_cities (origin, dest, dayofweek) AS
	((SELECT DISTINCT origin.city as origin, dest.city as dest, flights.dayofweek as dayofweek
	  FROM airports as origin, airports as dest, flights
	  WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid)
	UNION 
	 (SELECT DISTINCT origin.city, reachable_cities.dest, reachable_cities.dayofweek
	  FROM reachable_cities, airports as origin, airports as dest, flights
	  WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND dest.city = reachable_cities.origin 
	  	AND reachable_cities.dayofweek = flights.dayofweek
	 ))
SELECT DISTINCT dest AS name
FROM reachable_cities
WHERE reachable_cities.origin = 'Albuquerque'
ORDER BY name ASC;

--3--
SELECT dest as name
FROM
	(SELECT info_paths.*, COUNT(origin) OVER (PARTITION BY origin, dest) AS rand
	FROM info_paths
	WHERE origin = 'Albuquerque' AND ((dest = origin and has_cycle = 1) OR (NOT(dest=origin) AND has_cycle = 0))) AS foo
WHERE rand = 1
ORDER BY name ASC;

--4--
WITH largest_cycle_abq AS 
	(SELECT DISTINCT len AS length, 0 AS query_id 
	 FROM info_paths
	 WHERE has_cycle=1 AND origin = dest AND (nodes LIKE concat('%,','Albuquerque',',%'))
	UNION ALL
	 SELECT NULL,0
	 WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE has_cycle=1 AND origin = dest AND (nodes LIKE concat('%,','Albuquerque',',%')))
	ORDER BY length DESC
	LIMIT 1)
SELECT COALESCE(length,0) AS length FROM largest_cycle_abq;

--5--
WITH largest_cycle AS 
	(SELECT DISTINCT len as length, 0 as query_id
	 FROM info_paths
	 WHERE has_cycle=1 AND origin = dest
	UNION ALL
	 SELECT NULL,0
	 WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE has_cycle=1 AND origin = dest)
	ORDER BY length DESC
	LIMIT 1)
SELECT COALESCE(length,0) AS length FROM largest_cycle;

--6--
WITH abq_chicago_interstate AS
	(SELECT DISTINCT COUNT(origin) OVER (PARTITION BY (origin,dest)) AS count, 0 as query_id
	 FROM info_paths_interstate
	 WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND has_cycle = 0
	UNION ALL
	 SELECT NULL,0
	 WHERE NOT EXISTS (SELECT 0 FROM info_paths_interstate WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND has_cycle = 0))
SELECT COALESCE(count,0) AS count FROM abq_chicago_interstate;
	
--7--
WITH abq_chicago_paths AS
	(SELECT DISTINCT rand as count, 0 as query_id
	 FROM
		(SELECT info_paths.*, COUNT(origin) OVER (PARTITION BY origin, dest) AS rand
		FROM info_paths
		WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND ((has_cycle = 0))
			AND nodes LIKE concat('%,','Washington',',%')) AS foo
	UNION ALL
	 SELECT NULL,0
	 WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND ((has_cycle = 0)) AND nodes LIKE concat('%,','Washington',',%')))
SELECT COALESCE(count,0) AS count FROM abq_chicago_paths;
			
--8--
SELECT DISTINCT all_cities_pairs.origin as name1, all_cities_pairs.dest as name2
FROM all_cities_pairs
WHERE (all_cities_pairs.origin, all_cities_pairs.dest) NOT IN 
	(SELECT all_paths.origin as name1, all_paths.dest as name2 FROM all_paths)
ORDER BY name1 ASC, name2 ASC;

--9--
SELECT day FROM
	(SELECT all_month_days.dayofmonth AS day, COALESCE(foo.flight_delay,0) AS flight_delay
	 FROM
		all_month_days LEFT OUTER JOIN
		(SELECT DISTINCT flights.dayofmonth, SUM(flights.departuredelay + flights.arrivaldelay) OVER (PARTITION BY flights.dayofmonth) AS flight_delay
		 FROM airports as origin, flights
		 WHERE origin.city = 'Albuquerque' AND flights.originairportid = origin.airportid) AS foo
	 ON all_month_days.dayofmonth = foo.dayofmonth
	 ORDER BY flight_delay ASC, day ASC) AS foo_outer;

--10--

--11--
SELECT DISTINCT origin as name1, dest as name2 FROM info_paths_delay
ORDER BY name1 ASC, name2 ASC;

--12--
SELECT authorid, length
FROM
	(SELECT all_authors.authorid, COALESCE(shortest_paths.length,-1) as length
	 FROM all_authors LEFT OUTER JOIN 
		(SELECT dest as authorid, length
		 FROM
			(SELECT foo.*, row_number() OVER (PARTITION BY dest) as rand
			 FROM
				(SELECT DISTINCT origin, dest, nodes, len as length
				 FROM info_paths_collabs
				 WHERE origin = 1235 AND has_cycle=0 AND NOT(dest = origin)
				 ORDER BY dest ASC, len ASC) AS foo) AS foo_outer
		 WHERE rand = 1) AS shortest_paths
	 ON shortest_paths.authorid = all_authors.authorid) AS temp_table
WHERE NOT(authorid=1235)
ORDER BY length DESC, authorid ASC;

--13--
WITH age_gender_paths AS
	(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
	 FROM info_paths_collabs_ang
	 WHERE origin = 1558 AND dest = 2826 AND has_cycle=0
	UNION ALL
	 SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 1558 AND dest = 2826 AND has_cycle=0)) 
	 		 THEN -1 ELSE 0 END),-1
	)
SELECT count FROM age_gender_paths
LIMIT 1;
	 
--14--
WITH cited_p126_paths AS 
	(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
	 FROM info_paths_cited_126
	 WHERE origin = 704 AND dest = 102 AND any_citation_126 = 1 AND has_cycle = 0
	UNION ALL
	 SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 704 AND dest = 102 AND has_cycle=0))
 	 		 THEN -1 ELSE 0 END),-1
	)
SELECT count from cited_p126_paths
LIMIT 1;

--15--
WITH paths_for_both_directions AS
	(SELECT DISTINCT COUNT(dest) OVER (PARTITION BY origin) as count FROM info_paths_citations_both
	 WHERE origin = 1745 AND dest = 456 AND has_cycle = 0
	UNION ALL
	 SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 1745 AND dest = 456 AND has_cycle=0)) 
	 		 THEN -1 ELSE 0 END)
	)
SELECT count FROM paths_for_both_directions
LIMIT 1;

--16--
SELECT foo_outer.origin as authorid
FROM
	(SELECT DISTINCT foo.origin, COUNT(origin) OVER (PARTITION BY origin) as future_collaborations
	FROM
		(SELECT DISTINCT origin.authorid as origin, dest.authorid as dest
		FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, all_citations
		WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid 
			AND (EXISTS (SELECT 0 FROM all_citations WHERE paperid1 = origin_paper.paperid AND paperid2 = dest_paper.paperid))
			AND (NOT EXISTS (SELECT 0 FROM co_authors WHERE co_authors.origin = origin.authorid AND co_authors.dest = dest.authorid))
			AND NOT(origin.authorid = dest.authorid)) AS foo
	ORDER BY future_collaborations DESC, origin ASC) AS foo_outer
LIMIT 10;

--17--
	 
--18--
WITH c123_inclusion_paths AS
	(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
	 FROM info_paths_collabs
	 WHERE origin = 3552 AND dest = 321 AND has_cycle=0
 		AND ((nodes LIKE concat('%,',1436,',%')) OR (nodes LIKE concat('%,',562,',%')) OR (nodes LIKE concat('%,',921,',%')))
 	UNION ALL
 	 SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 3552 AND dest = 321 AND has_cycle=0))
 	 		 THEN -1 ELSE 0 END),-1
 	 )
SELECT count FROM c123_inclusion_paths
LIMIT 1;

--19--

--20--

--21--

--22--

--CLEANUP--
DROP VIEW all_paths;
DROP VIEW all_cities_pairs;
DROP VIEW all_month_days;
DROP VIEW info_paths;
DROP VIEW info_paths_interstate;
DROP VIEW info_paths_delay;
DROP VIEW info_paths_citations_both CASCADE;
DROP VIEW info_paths_citations_asc CASCADE;
DROP VIEW info_paths_citations_desc CASCADE;
DROP VIEW info_paths_cited_126 CASCADE;
DROP VIEW all_citations_authors CASCADE;
DROP VIEW co_authors CASCADE;
DROP VIEW total_citations CASCADE;
DROP VIEW all_authors CASCADE;
DROP VIEW all_citations CASCADE;
DROP VIEW info_paths_collabs CASCADE;
DROP VIEW info_paths_collabs_ang CASCADE;
