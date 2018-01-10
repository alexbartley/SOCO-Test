CREATE OR REPLACE TRIGGER content_repo.ins_geo_poly_ref_qr
 BEFORE
  INSERT
 ON content_repo.geo_poly_ref_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_geo_poly_ref_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/