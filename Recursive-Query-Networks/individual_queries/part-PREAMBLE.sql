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

