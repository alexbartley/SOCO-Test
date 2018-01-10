CREATE OR REPLACE TRIGGER content_repo."INS_ADMIN_QR"
 BEFORE
  INSERT
 ON content_repo.admin_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_admin_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/