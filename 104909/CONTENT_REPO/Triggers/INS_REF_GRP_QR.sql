CREATE OR REPLACE TRIGGER content_repo."INS_REF_GRP_QR"
 BEFORE
  INSERT
 ON content_repo.ref_grp_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_ref_grp_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/