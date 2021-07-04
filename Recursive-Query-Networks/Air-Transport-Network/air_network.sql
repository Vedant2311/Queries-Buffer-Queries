--PREAMBLE--
/* View for the tuples (c1,c2,c1_state,c2_state) where City c2 is reachable from City c1 via atleast one path */
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

/* View for the tuples (c1,c2) where they are all the possible pairs of cities in the dataset */
CREATE VIEW all_cities_pairs AS
SELECT source.city as origin, dest.city as dest
FROM airports as source, airports as dest
WHERE NOT source.airportid = dest.airportid;

/* View for getting all the days of the month in the given range of 1 to 31 */
CREATE VIEW all_month_days AS
SELECT generate_series AS dayofmonth, 0 AS flight_delay FROM GENERATE_SERIES(1,31);

/****************** View for getting all the different paths in the Airports graph *********************/
/* The path will be a Simple cycle if it has a cycle and the source and destination nodes are same */
/* Else the path will be a simple path if it does not have a cycle in it. Only cases to be considered */
CREATE VIEW info_paths AS 
WITH RECURSIVE get_paths AS (
	 -- Having the path as the list of nodes, created via string operations 
	 SELECT DISTINCT origin.city as origin, dest.city as dest, 1 as len, 
	 	concat(',', origin.city, ',', dest.city, ',') as nodes,
	 	(CASE WHEN origin.city = dest.city THEN 1 ELSE 0 END) AS has_cycle
	 FROM airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.city as dest, len + 1,
	 	concat(get_paths.nodes, dest.city, ','),
	 	-- If the destination City is present in the nodes list till now, then it is a cycle
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.city,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND get_paths.dest = origin.city 
	 	AND get_paths.has_cycle = 0
	)
SELECT * FROM get_paths;

/* The view (similar to info_paths) that would give out the information of the paths connected by Interstate flights */
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
	 	-- If the destination City is present in the nodes list till now, then it is a cycle
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.city,',%') THEN 1 ELSE 0 END) AS has_cycle	 	
	 FROM get_paths, airports as origin, airports as dest, flights
	 WHERE origin.airportid = flights.originairportid AND dest.airportid = flights.destairportid AND get_paths.dest = origin.city 
	 	AND get_paths.has_cycle = 0 AND NOT(origin.state = dest.state)
	)	
SELECT * FROM get_paths;

/* The view (similar to info_paths) that would give out the pairs (c1,c2) if the consecutive cities have their total delay in non-decreasing order */
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

/*******************************************************************************************************************************************************************************/

--1--
/* All cities reachable from Albuquerque with the same carrier */
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
/* All cities reachable from Albuquerque with all connecting flights on the same day of the week */
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
/* All cities reachable from Albuquerque by only one simple path of cities */
SELECT dest as name
FROM
	(SELECT info_paths.*, COUNT(origin) OVER (PARTITION BY origin, dest) AS rand
	FROM info_paths
	WHERE origin = 'Albuquerque' AND ((dest = origin and has_cycle = 1) OR (NOT(dest=origin) AND has_cycle = 0))) AS foo
WHERE rand = 1
ORDER BY name ASC;

--4--
/* Length of largest possible simple cycle containing Albuquerque in it */
/* A->a1->a2...->an->A is a simple cycle of length n+1 if A, a1, a2, ..., an are all distinct */
WITH largest_cycle_abq AS 
	(SELECT DISTINCT len AS length, 0 AS query_id 
	 FROM info_paths
	 WHERE has_cycle=1 AND origin = dest AND (nodes LIKE concat('%,','Albuquerque',',%'))
	-- Ensuring that the Query returns atleast one row even if there are no cycles here (thus the length would be 0)
	UNION ALL
	 SELECT NULL,0
	 WHERE NOT EXISTS (SELECT 0 FROM info_paths WHERE has_cycle=1 AND origin = dest AND (nodes LIKE concat('%,','Albuquerque',',%')))
	ORDER BY length DESC
	LIMIT 1)
SELECT COALESCE(length,0) AS length FROM largest_cycle_abq;

--5--
/* Length of the largest possible simple cycle in the graph */
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
/* No. of Simple Paths between Albuquerque and Chicago via interstate flights */
WITH abq_chicago_interstate AS
	(SELECT DISTINCT COUNT(origin) OVER (PARTITION BY (origin,dest)) AS count, 0 as query_id
	 FROM info_paths_interstate
	 WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND has_cycle = 0
	UNION ALL
	 SELECT NULL,0
	 WHERE NOT EXISTS (SELECT 0 FROM info_paths_interstate WHERE origin = 'Albuquerque' AND dest = 'Chicago' AND has_cycle = 0))
SELECT COALESCE(count,0) AS count FROM abq_chicago_interstate;
	
--7--
/* Get the number of paths between Albuquerque and Chicago passing through Washington */
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
/* All the pairs of cities (c1,c2) s.t no path from c1 to c2 */
SELECT DISTINCT all_cities_pairs.origin as name1, all_cities_pairs.dest as name2
FROM all_cities_pairs
WHERE (all_cities_pairs.origin, all_cities_pairs.dest) NOT IN 
	(SELECT all_paths.origin as name1, all_paths.dest as name2 FROM all_paths)
ORDER BY name1 ASC, name2 ASC;

--9--
/* Taking direct flights from Albuquerque, outputs days of the month with least amount of total delay (sum of arrival and departure delay) */
SELECT day FROM
	(SELECT all_month_days.dayofmonth AS day, COALESCE(foo.flight_delay,0) AS flight_delay
	 FROM
		-- Performing a Left Outer Join to ascertain that all the possible month-days will be there in the output
		all_month_days LEFT OUTER JOIN
		(SELECT DISTINCT flights.dayofmonth, SUM(flights.departuredelay + flights.arrivaldelay) OVER (PARTITION BY flights.dayofmonth) AS flight_delay
		 FROM airports as origin, flights
		 WHERE origin.city = 'Albuquerque' AND flights.originairportid = origin.airportid) AS foo
	 ON all_month_days.dayofmonth = foo.dayofmonth
	 ORDER BY flight_delay ASC, day ASC) AS foo_outer;

--11--
/* Pairs of cities such that there is a path between them and the consecutive delays are in an increasing order */
SELECT DISTINCT origin as name1, dest as name2 FROM info_paths_delay
ORDER BY name1 ASC, name2 ASC;

--CLEANUP--
DROP VIEW all_paths;
DROP VIEW all_cities_pairs;
DROP VIEW all_month_days;
DROP VIEW info_paths;
DROP VIEW info_paths_interstate;
DROP VIEW info_paths_delay;
