CREATE EXTENSION postgis;

--4) Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty)
-- położonych w odległości mniejszej niż 1000 jednostek od głównych rzek. Budynki spełniające to
-- kryterium zapisz do osobnej tabeli tableB.

select p.* into tableB
from popp p, majrivers r
where p.f_codedesc='Building' and ST_DWithin(p.geom,r.geom,1000)

select count(f_codedesc) from tableB

--5) Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
-- geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.
select geom,elev,name into airportsNew
from airports

--a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód
select name, ST_X(geom) as W
from airportsNew
order by W Limit 1 

select name, ST_X(geom) as E
from airportsNew
order by E desc Limit 1 

--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
-- Wysokość n.p.m. przyjmij dowolną.

insert into airportsNew
values
((select ST_Centroid(ST_MakeLine(
		 (select geom from airportsNew order by ST_X(geom) desc limit 1), 
		 (select geom from airportsNew order by ST_X(geom) limit 1)))),8,'airportB')

--select * from airportsNew
--where name='airportB'

--6) Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

select ST_Area(ST_Buffer((ST_ShortestLine((select geom from lakes where names='Iliamna Lake'),
										 (select geom from airports where name='AMBLER'))), 1000))

--7)Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
-- poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).
select vegdesc as tree, sum(ST_Area(t.geom)) as area
from trees t, tundra tu, swamp s
where ST_Within(t.geom, tu.geom) or St_Within(t.geom, s.geom)
group by t.vegdesc



