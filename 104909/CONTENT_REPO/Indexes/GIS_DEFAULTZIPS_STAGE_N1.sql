CREATE INDEX content_repo.gis_defaultzips_stage_n1 ON content_repo.gis_defaultzips_stage(geo_polygon_id,state_code,county_name,city_name,zipcode,zip4,area_id)

TABLESPACE content_repo;