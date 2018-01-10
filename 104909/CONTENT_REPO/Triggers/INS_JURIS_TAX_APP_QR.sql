CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_APP_QR"
 BEFORE
  INSERT
 ON content_repo.juris_tax_app_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_tax_app_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/