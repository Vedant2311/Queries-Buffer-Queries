SELECT day FROM
(SELECT all_month_days.dayofmonth AS day, COALESCE(foo.flight_delay,0) AS flight_delay
FROM
all_month_days LEFT OUTER JOIN
(SELECT DISTINCT flights.dayofmonth, SUM(flights.departuredelay + flights.arrivaldelay) OVER (PARTITION BY flights.dayofmonth) AS flight_delay
FROM airports as origin, flights
WHERE origin.city = 'Albuquerque' AND flights.originairportid = origin.airportid) AS foo
ON all_month_days.dayofmonth = foo.dayofmonth
ORDER BY flight_delay ASC, day ASC) AS foo_outer;

