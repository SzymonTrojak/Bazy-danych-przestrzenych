create extension postgis;

CREATE TABLE obiekty(ID INT PRIMARY KEY, nazwa VARCHAR(15) NOT NULL, geom GEOMETRY NOT NULL);
INSERT INTO obiekty(ID,nazwa, geom) VALUES
(1,'obiekt1', ST_GeomFromEWKT( 'COMPOUNDCURVE( (0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 2, 5 1), (5 1, 6 1))' )),
(2,'obiekt2', ST_GeomFromEWKT( 'CURVEPOLYGON( 
					COMPOUNDCURVE( (10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6)),
					COMPOUNDCURVE( CIRCULARSTRING(11 2, 12 3, 13 2), CIRCULARSTRING(13 2, 12 1, 11 2)))')),
(3,'obiekt3', ST_GeomFromEWKT( 'TRIANGLE((7 15, 10 17, 12 13, 7 15))')),
(4,'obiekt4', ST_GeomFromEWKT( 'LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')),
(5,'obiekt5', ST_GeomFromEWKT( 'MULTIPOINT(30 30 59, 38 32 234)')),
(6,'obiekt6', ST_GeomFromEWKT( 'GEOMETRYCOLLECTION( LINESTRING(1 1, 3 2), POINT(4 2) )'));

SELECT ST_CurveToLine(geom) FROM obiekty


--1
SELECT ST_Area(ST_Buffer(ST_ShortestLine
			((SELECT geom FROM obiekty WHERE nazwa='obiekt3'),
			(SELECT geom FROM obiekty WHERE nazwa='obiekt4')),5));

--2
SELECT ST_IsClosed((ST_Dump(geom)).geom) AS is_closed
FROM obiekty
WHERE nazwa = 'obiekt4';

UPDATE obiekty 
SET geom = ST_MakePolygon(ST_LineMerge(ST_Collect
				(geom,
				ST_MakeLine(ST_Point(20.5,19.5), ST_Point(20,20)))))
WHERE nazwa='obiekt4';

--3

INSERT INTO obiekty(id,nazwa, geom) VALUES(7,'obiekt7', 
		ST_Collect((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
					(SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')));

--4

SELECT SUM(ST_Area(ST_Buffer(obiekty.geom, 5))) AS powierzchnia
FROM obiekty
WHERE ST_HasArc(obiekty.geom)=FALSE;
