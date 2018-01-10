CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_GEO_AREAS_NKIDS" 
 BEFORE
 INSERT
 ON content_repo.JURIS_GEO_AREAS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
select nkid
into :new.GEO_POLYGON_NKID
from geo_polygons
where id = :new.GEO_POLYGON_ID;
select nkid
into :new.JURISDICTION_NKID
from jurisdictions
where id = :new.JURISDICTION_ID;

END;
/