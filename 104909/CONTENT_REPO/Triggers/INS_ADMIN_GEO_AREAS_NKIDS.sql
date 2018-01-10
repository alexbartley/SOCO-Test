CREATE OR REPLACE TRIGGER content_repo."INS_ADMIN_GEO_AREAS_NKIDS" 
 BEFORE
  INSERT
 ON content_repo.ADMIN_GEO_AREAS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
select nkid
into :new.ADMINISTRATOR_NKID
from administrators
where id = :new.ADMINISTRATOR_ID;
select nkid
into :new.GEO_POLYGON_NKID
from geo_polygons
where id = :new.GEO_POLYGON_ID;
END;
/