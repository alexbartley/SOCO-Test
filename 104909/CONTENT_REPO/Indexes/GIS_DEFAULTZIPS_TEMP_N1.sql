CREATE INDEX content_repo.gis_defaultzips_temp_n1 ON content_repo.gis_defaultzips_temp(geo_polygon_id,state_code,county_name,zipcode,zip4)

TABLESPACE content_repo;