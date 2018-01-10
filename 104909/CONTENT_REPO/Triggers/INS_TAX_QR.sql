CREATE OR REPLACE TRIGGER content_repo."INS_TAX_QR"
 BEFORE
  INSERT
 ON content_repo.tax_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_tax_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/