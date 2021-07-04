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

