CREATE INDEX content_repo.gis_mapped_areas_temp_n1 ON content_repo.gis_mapped_areas_temp(jurisdiction_id,geo_polygon_id,unique_area_id,rid)

TABLESPACE content_repo;