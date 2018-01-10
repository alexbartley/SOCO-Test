CREATE OR REPLACE TRIGGER content_repo."INS_GEO_POLY_REF_REVISIONS" 
 BEFORE
  INSERT
 ON content_repo.geo_poly_ref_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.nkid IS NULL) THEN
        :new.nkid := nkid_geo_poly_ref_revisions.nextval;
    END IF;

    :new.id := pk_geo_poly_ref_revisions.nextval;
    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;
END;
/