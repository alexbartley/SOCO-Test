CREATE OR REPLACE TRIGGER content_repo."DEL_GEO_UNIQUE_AREA_REV" 
 AFTER
  DELETE
 ON content_repo.geo_unique_area_revisions
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
    UPDATE geo_unique_area_revisions r
    SET    next_rid = NULL
    WHERE  next_rid IS NOT NULL
           AND NOT EXISTS (
                            SELECT 1
                            FROM   geo_unique_area_revisions r2
                            WHERE  r2.id = r.next_rid
                          );
END;
/