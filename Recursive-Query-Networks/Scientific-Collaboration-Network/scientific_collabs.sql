--PREAMBLE--

/* View for all the authors present in the author id list */
CREATE VIEW all_authors AS 
SELECT DISTINCT authorid FROM authordetails;

/* View for all the pairs of (p1,p2) where p1 has cited p2 directly or indirectly */
CREATE VIEW all_citations AS
WITH RECURSIVE paper_citation_pairs (paperid1, paperid2) AS 
	(SELECT DISTINCT paperid1, paperid2 FROM citationlist
	 UNION 
	 SELECT DISTINCT paper_citation_pairs.paperid1, citationlist.paperid2 FROM paper_citation_pairs, citationlist WHERE paper_citation_pairs.paperid2 = citationlist.paperid1
	)
SELECT * FROM paper_citation_pairs;

/* View for all the pairs of (author,count) where 'count' is the total citations of the papers written by 'author' */
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

/* View for all the pairs (a,p) where person a has cited the paper p directly or indirectly */
CREATE VIEW all_citations_authors AS
SELECT DISTINCT authordetails.authorid, all_citations.paperid2 as paperid
FROM authordetails, all_citations, authorpaperlist
WHERE authordetails.authorid = authorpaperlist.authorid AND all_citations.paperid1 = authorpaperlist.paperid;

/* View for all the author pairs (a1,a2) who have worked on atleast one paper together */
CREATE VIEW co_authors AS
SELECT DISTINCT origin.authorid as origin, dest.authorid as dest
FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid);

/****************** View for getting all the different paths in the Collabs graph *********************/
/* The path will be a Simple cycle if it has a cycle and the source and destination nodes are same */
/* Else the path will be a simple path if it does not have a cycle in it. Only cases to be considered */
CREATE VIEW info_paths_collabs AS 
WITH RECURSIVE get_paths AS (
	 -- Having the path as the list of nodes, created via string operations 
	 SELECT DISTINCT origin.authorid as origin, dest.authorid as dest, 1 as len, 
	 	concat(',', origin.authorid, ',', dest.authorid, ',') as nodes,
	 	(CASE WHEN origin.authorid = dest.authorid THEN 1 ELSE 0 END) AS has_cycle
	 FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 UNION ALL
	 SELECT DISTINCT get_paths.origin, dest.authorid as dest, len + 1,
	 	concat(get_paths.nodes, dest.authorid, ','),
	 	-- If the destination Node is present in the nodes list till now, then it is a cycle
	 	(CASE WHEN get_paths.nodes LIKE concat('%,',dest.authorid,',%') THEN 1 ELSE 0 END) AS has_cycle
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	)
SELECT * FROM get_paths;

/* The view (similar to info_paths_collabs) with the additional conditions on the age and gender of the authors */
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

/* The view (similar to info_paths_collabs) with the additional conditions on the citation of a paper with the paper id (126) */
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
	 	-- Adding an Integer value here that would check if any one in the path has cited the paper of Id 126 or not
	 	(CASE WHEN (EXISTS (SELECT 0 FROM all_citations_authors WHERE all_citations_authors.authorid = origin.authorid AND all_citations_authors.paperid = 126)) 
	 	 THEN 1 ELSE 0 END) as any_citation_126
	 FROM get_paths, authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper
	 WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid
	 	AND origin_paper.paperid = dest_paper.paperid AND (NOT origin.authorid = dest.authorid)
	 	AND get_paths.dest = origin.authorid AND get_paths.has_cycle = 0
	)
SELECT * FROM get_paths;

/* The view (similar to info_paths_collabs) with the additional conditions that the total citations are strictly increasing */
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

/* The view (similar to info_paths_collabs) with the additional conditions that the total citations are strictly decreasing */
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

/* The view to get both the ascending as well as the descending paths with respect to the total citations */
CREATE VIEW info_paths_citations_both AS
WITH inc_and_dec_paths AS
	(SELECT DISTINCT info_paths_citations_asc.origin, info_paths_citations_asc.nodes, info_paths_citations_asc.dest, info_paths_citations_asc.has_cycle
	 FROM info_paths_citations_asc 
	UNION 
	 SELECT DISTINCT info_paths_citations_desc.origin, info_paths_citations_desc.nodes, info_paths_citations_desc.dest, info_paths_citations_desc.has_cycle
	 FROM info_paths_citations_desc)
SELECT DISTINCT origin, nodes, dest, has_cycle FROM inc_and_dec_paths;

/*******************************************************************************************************************************************************************************/

--12--
/* Shortest path from Author A (authorid = 1235) to every other Author in G */
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
/* Number of paths between A(1558) and B(2826) where all authors on path have age more than 35 and have consecutive ones have different genders */
WITH age_gender_paths AS
	(SELECT DISTINCT (COUNT(dest) OVER (PARTITION BY origin,dest)) AS count, -1 as query_id
	 FROM info_paths_collabs_ang
	 WHERE origin = 1558 AND dest = 2826 AND has_cycle=0
	UNION ALL
	 -- Taking care of the conditions where the two vertices are not in the same component of the graph (i.e no path between them)
	 SELECT (CASE WHEN (NOT EXISTS (SELECT -1 FROM info_paths_collabs WHERE origin = 1558 AND dest = 2826 AND has_cycle=0)) 
	 		 THEN -1 ELSE 0 END),-1
	)
SELECT count FROM age_gender_paths
LIMIT 1;
	 
--14--
/* Number of paths between A(704) and B(102) where atleast one person on path has cited paper p(126) */
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
/* Number of paths between A(1745) and B(456) such that the total number of citations are in a strictly increasing/decreasing order */	 
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
/* Returns the top-10 authors with the most number of future collaborators */
SELECT foo_outer.origin as authorid
FROM
	(SELECT DISTINCT foo.origin, COUNT(origin) OVER (PARTITION BY origin) as future_collaborations
	FROM
		(SELECT DISTINCT origin.authorid as origin, dest.authorid as dest
		FROM authordetails as origin, authordetails as dest, authorpaperlist as origin_paper, authorpaperlist as dest_paper, all_citations
		WHERE origin.authorid = origin_paper.authorid AND dest.authorid = dest_paper.authorid 
			-- Condition for Indirect/Direct paper citation 
			AND (EXISTS (SELECT 0 FROM all_citations WHERE paperid1 = origin_paper.paperid AND paperid2 = dest_paper.paperid))
			-- Condition for the two authors not having any paper together
			AND (NOT EXISTS (SELECT 0 FROM co_authors WHERE co_authors.origin = origin.authorid AND co_authors.dest = dest.authorid))
			AND NOT(origin.authorid = dest.authorid)) AS foo
	ORDER BY future_collaborations DESC, origin ASC) AS foo_outer
LIMIT 10;
	 
--18--
/* Number of paths between A(3552) to B(321) that also pass through atleast one of C1(1436), C2(562), C3(921) */
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
 	 
--CLEANUP--
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
