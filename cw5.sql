create extension postgis;

--zadanie 1
SELECT SUM(st_area(geom))
FROM trees
WHERE vegdesc='Mixed Trees'

--zadanie 2
SELECT*FROM trees t
WHERE t.vegdesc='Mixed Trees';

SELECT*FROM trees t
WHERE t.vegdesc='Deciduous';

SELECT*FROM trees t
WHERE t.vegdesc='Evergreen';


--zadanie 3
SELECT
	SUM(ST_Length(ST_Intersection(rail.geom, re.geom)))
FROM
	railroads rail,
	regions re
WHERE
	re.name_2 = 'Matanuska-Susitna';


--zadanie 4 
SELECT AVG(elev) FROM airports WHERE use = 'Military';

SELECT COUNT(*) FROM airports WHERE use = 'Military';

DELETE FROM airports WHERE use= 'Military' AND elev>1400;

SELECT COUNT(*)FROM airports WHERE use= 'Military' AND elev>1400;


--zadanie 5

SELECT * INTO buildings_in_bristol_bay FROM popp p WHERE p.f_codedesc='Building'
and
st_within(p.geom, (SELECT geom FROM regions WHERE name_2='Bristol Bay'));

SELECT COUNT(*) FROM buildings_in_bristol_bay;

--zadanie 6
DELETE FROM buildings_in_bristol_bay b
WHERE ST_DWithin((SELECT ST_Union(geom) FROM rivers),b.geom,100000)=False;-- mozliwe ze trzeba uzyc stop bo to ameryka

SELECT COUNT(*) FROM buildings_in_bristol_bay

--zadanie 7
WITH przecina_sie as
(SELECT ST_Intersection(m.geom,r.geom) as geom
 FROM majrivers m,railroads r
 WHERE ST_AsText(ST_Intersection(m.geom,r.geom))!='LINESTRING EMPTY'
)
SELECT SUM(ST_NPoints(geom)) FROM przecina_sie

--zadanie 8

SELECT st_node(geom) as geom into railroads_node
FROM railroads

SELECT COUNT(geom) FROM railroads_node

--zadanie 9
WITH airports_buffer AS (
	SELECT st_buffer(geom, 100000) as geom --mozliwe ze maja byc stopy bo to ameryka
	FROM airports
),
railroads_buffer AS (
	SELECT st_buffer(geom, 50000) as geom 
	FROM railroads
),
trails_buffer AS (
	SELECT st_buffer(geom, 1000) as geom 
	FROM trails
)

SELECT st_intersection((st_intersection
						((st_intersection((SELECT st_union(geom) FROM airports_buffer), r.geom)),
						 (st_intersection((SELECT st_union(geom) FROM railroads_buffer), r.geom)))),
					  (SELECT st_union(geom) FROM trails_buffer))AS geom FROM regions r
					  
-- zadanie 10
SELECT SUM(st_npoints(st_simplify(geom, 100))) AS geom
FROM swamp

SELECT sum(st_area(st_simplify(geom, 100))) AS geom
FROM swamp

SELECT SUM(st_npoints(geom)) AS geom
FROM swamp

SELECT SUM(st_area(geom)) AS geom
FROM swamp

