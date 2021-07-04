SELECT DISTINCT all_cities_pairs.origin as name1, all_cities_pairs.dest as name2
FROM all_cities_pairs
WHERE (all_cities_pairs.origin, all_cities_pairs.dest) NOT IN
(SELECT all_paths.origin as name1, all_paths.dest as name2 FROM all_paths)
ORDER BY name1 ASC, name2 ASC;

