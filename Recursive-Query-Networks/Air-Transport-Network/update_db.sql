DELETE FROM airports;
DELETE FROM flights;

\copy airports from 'Data/airports.csv' csv header;
\copy flights from 'Data/flights.csv' csv header;
