CREATE OR REPLACE TRIGGER content_repo."INS_GEO_POLY_USPS_NKID"
 BEFORE
  INSERT
 ON content_repo.GEO_POLYGON_USPS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
    l_nkid number;
BEGIN
select nkid
into :new.GEO_POLYGON_NKID
from geo_polygons
where id = :new.GEO_POLYGON_ID;

END;
/