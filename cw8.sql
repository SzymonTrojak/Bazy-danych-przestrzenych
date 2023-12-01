create extension postgis;
create extension postgis_raster;
Drop table uk_250k;
Drop table parki_granice

--zadanie 6
SELECT ST_SRID(geom) FROM public.parki_granice;
CREATE TABLE public.uk_lake_district AS
SELECT ST_Clip(a.rast, b.geom, true)
FROM  public.uk_250k AS a, public.parki_granice AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.gid  = 1;

--zadanie 7
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(st_clip), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM public.uk_lake_district;

SELECT lo_export(loid, 'D:\my.tiff') --> Save the file in a placewhere the user postgres have access. In windows a flash drive usualy worksfine.
FROM tmp_out;


--zadanie 9
create table green as SELECT ST_Union(ST_SetBandNodataValue(rast, NULL), 'MAX') rast
                      FROM (SELECT rast FROM sentinel2_band3_1  
                        UNION ALL
                         SELECT rast FROM sentinel2_band3_2) foo;
						 
create table nir as SELECT ST_Union(ST_SetBandNodataValue(rast, NULL), 'MAX') rast
                      FROM (SELECT rast FROM sentinel2_band8_1 
                        UNION ALL
                         SELECT rast FROM sentinel2_band8_2) foo;

-- zadanie 10
create table ndwi as
WITH r1 AS ((SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) as rast
			FROM public.green AS a, public.parki_granice AS b
			WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.gid=1)),
			
			r2 AS ((SELECT ST_Union(ST_Clip(a.rast, ST_Transform(b.geom, 32630), true)) as rast
			FROM public.nir AS a, public.parki_granice AS b
			WHERE ST_Intersects(a.rast, ST_Transform(b.geom, 32630)) AND b.gid=1))
			
SELECT ST_MapAlgebra(r1.rast, r2.rast,'([rast1.val] - [rast2.val]) / ([rast2.val] +
[rast1.val])::float','32BF') AS rast 
FROM r1,r2

--zadanie 11
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM public.ndwi;

SELECT lo_export(loid, 'D:\zad3.tiff') --> Save the file in a placewhere the user postgres have access. In windows a flash drive usualy worksfine.
FROM tmp_out;
Drop table tmp_out