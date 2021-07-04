CREATE TABLE airports (
	airportid bigint NOT NULL,
	city text,
	state text,
	name text,
	constraint airports_key primary key (airportid)
);

CREATE TABLE flights (
	flightid bigint NOT NULL,
	originairportid bigint,
	destairportid bigint,
	carrier text,
	dayofmonth bigint,
	dayofweek bigint,
	departuredelay bigint,
	arrivaldelay bigint,
	constraint flights_key primary key (flightid)
);

\copy airports from 'Data/airports.csv' csv header;
\copy flights from 'Data/flights.csv' csv header;

