-- Database: zajecia_2

-- DROP DATABASE IF EXISTS zajecia_2;

	CREATE DATABASE zajecia_2

	-- zadanie 3
	CREATE EXTENSION postgis;
	 -- zadanie 4
	CREATE TABLE budynki(
	id INT,
	geometria GEOMETRY,
	nazwa VARCHAR(40)
	);
	
	CREATE TABLE drogi(
	id INT,
	geometria GEOMETRY,
	nazwa VARCHAR(40)
	);
	
	CREATE TABLE punkty_informacyjne(
	id INT,
	geometria GEOMETRY,
	nazwa VARCHAR(40)
	);
	-- zadanie 5
	INSERT into budynki
	values
	(1, ST_GeomFromText('Polygon ((8 1.5, 8 4, 10.5 4, 10.5 1.5, 8 1.5))'),'BuildingA'),
	(2, ST_GeomFromText('POLYGON((4 5, 4 7, 6 7, 6 5, 4 5))'), 'BuildingB'),
	(3, ST_GeomFromText('POLYGON((3 6, 3 8, 5 8, 5 6, 3 6))'), 'BuildingC'),
	(4, ST_GeomFromText('POLYGON((9 8, 9 9, 10 9, 10 8, 9 8))'), 'BuildingD'),
	(5, ST_GeomFromText('POLYGON((1 1, 1 2, 2 2, 2 1, 1 1))'), 'BuildingF');
	
	INSERT into drogi
	values
	(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX'),
	(2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)'), 'RoadY');
	
	INSERT into punkty_informacyjne
	values
	(1, ST_GeomFromText('Point(1 3.5)'), 'G'),
	(2, ST_GeomFromText('Point(5.5 1.5)'), 'H'),
	(3, ST_GeomFromText('Point(9.5 6)'), 'I'),
	(4, ST_GeomFromText('Point(6.5 6)'), 'J'),
	(5, ST_GeomFromText('Point(6 9.5)'), 'K');
	
	-- zadanie 6a
	Select sum(ST_Length(geometria)) as długosc_drogi from drogi;
	
	-- zadanie 6b
	Select ST_AsText(geometria) as WKT,
	ST_Area(geometria) as powierzchnia,
	ST_Perimeter(geometria) as obwod 
	from budynki where nazwa='BuildingA';
	
	-- zadanie 6c
	Select nazwa ,
	ST_Area(geometria) as powierzchnia
	from budynki
	order by nazwa;
	
	-- zadanie 6d
	Select nazwa ,
	ST_Perimeter(geometria) as obwod
	from budynki
	order by ST_Area(geometria) desc limit 2;
	
	-- zadanie 6e
	Select ST_Distance(budynki.geometria,punkt.geometria) as dystans from
	budynki as budynki ,punkty_informacyjne as punkt
	where budynki.nazwa = 'BuildingC' and punkt.nazwa='G'

	-- zadanie 6f
	SELECT ST_Area(ST_Difference(budynek_C.geometria, ST_Buffer(budynek_B.geometria, 0.5))) AS reszta_pola
	FROM budynki budynek_B, budynki budynek_C
	WHERE budynek_B.nazwa='BuildingB' AND budynek_C.nazwa='BuildingC';	
	
	-- zadanie 6g
	Select nazwa from budynki where ST_Y(ST_Centroid(geometria)) > (Select ST_Y(ST_Centroid(geometria))from drogi where nazwa='RoadX');
	
	-- zadanie 6h
	Select ST_Area(ST_SymDifference(budynek_c.geometria,ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) as pole_nie_wspolne
	from budynki budynek_c where nazwa='BuildingC';
	

