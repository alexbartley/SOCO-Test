CREATE INDEX content_repo.geo_unique_area_fi1 ON content_repo.geo_unique_area_attributes(NVL("NEXT_RID",0))

TABLESPACE content_repo;