--------------------------------------
--Tworzenie rastrów z istniejących rastrów i interakcja z wektorami
--------------------------------------

--ST_Intersects
CREATE TABLE trojak.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table trojak.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON trojak.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('trojak'::name,
'intersects'::name,'rast'::name);

--ST_Clip
CREATE TABLE trojak.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--ST_Union
CREATE TABLE trojak.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


--------------------------------------
--Tworzenie rastrów z wektorów (rastrowanie)
--------------------------------------

--ST_AsRaster
CREATE TABLE trojak.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';	

--ST_Union
DROP TABLE trojak.porto_parishes; --> drop table porto_parishes first
CREATE TABLE trojak.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--ST_Tile
DROP TABLE trojak.porto_parishes; --> drop table porto_parishes first
CREATE TABLE trojak.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';


--------------------------------------
--Konwertowanie rastrów na wektory (wektoryzowanie)
--------------------------------------

--ST_Intersection
create table trojak.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--ST_DumpAsPolygons
CREATE TABLE trojak.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);


--------------------------------------
--ANALIZA RASTRÓW
--------------------------------------

--st_band
CREATE TABLE trojak.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--st_clip
CREATE TABLE trojak.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--st_slpoe
CREATE TABLE trojak.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM trojak.paranhos_dem AS a;

--st_reclass
CREATE TABLE trojak.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM trojak.paranhos_slope AS a;

--st_summarystats
SELECT st_summarystats(a.rast) AS stats
FROM trojak.paranhos_dem AS a;

--st_summarystats & st_union
SELECT st_summarystats(ST_Union(a.rast))
FROM trojak.paranhos_dem AS a;

--ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM trojak.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--st_value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


--------------------------------------
--Topographic Position Index (TPI)
--------------------------------------

create table trojak.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON trojak.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('trojak'::name,
'tpi30'::name,'rast'::name);

--problem do rozwiązania :s


--------------------------------------
--Algebra map
--------------------------------------

--NDVI=(NIR-Red)/(NIR+Red)

--Wyrażenie Algebry Map
CREATE TABLE trojak.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON trojak.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('trojak'::name,
'porto_ndvi'::name,'rast'::name);

--Funkcja zwrotna
create or replace function trojak.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE trojak.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'trojak.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON trojak.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('trojak'::name,
'porto_ndvi2'::name,'rast'::name);

--Funkcje TPI


--------------------------------------
--Eksport Danych
--------------------------------------
--0) qgis

--1) st_astiff
SELECT ST_AsTiff(ST_Union(rast))
FROM trojak.porto_ndvi;

--2) st_asgdalraster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM trojak.porto_ndvi;

--3) Zapisywanie danych na dysku za pomocą dużego obiektu (large object,lo)
GRANT SELECT ON tmp_out TO PUBLIC
DROP TABLE tmp_out
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM trojak.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\myraster.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

--4) Użycie Gdal
-- gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9
-- PG:"host=localhost port=5432 dbname=Zajecia_7 user=postgres
-- password= schema=trojak table=porto_ndvi mode=2"
-- D:\porto_ndvi.tiff


--------------------------------------
--Publikowanie danych za pomocą MapServer*
--------------------------------------

--Mapfile
MAP
NAME 'map'
SIZE 800 650
STATUS ON
EXTENT -58968 145487 30916 206234
UNITS METERS
WEB
METADATA
'wms_title' 'Terrain wms'
'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
'wms_enable_request' '*'
'wms_onlineresource'
'http://54.37.13.53/mapservices/srtm'
END
END
PROJECTION
'init=epsg:3763'
END
LAYER
NAME srtm
TYPE raster
STATUS OFF
DATA "PG:host=localhost port=5432 dbname='Zajecia_7' user='postgis'
password='' schema='rasters' table='dem' mode='2'" PROCESSING
"SCALE=AUTO"
PROCESSING "NODATA=-32767"
OFFSITE 0 0 0
METADATA
'wms_title' 'srtm'
END
END
END


--------------------------------------
--Publikowanie danych przy użyciu GeoServera*
--------------------------------------

--rozwiązanie problemu B)
create table trojak.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

CREATE INDEX idx_tpi30_porto_rast_gist ON trojak.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('trojak'::name,
'tpi30_porto'::name,'rast'::name);

--------------------------------------