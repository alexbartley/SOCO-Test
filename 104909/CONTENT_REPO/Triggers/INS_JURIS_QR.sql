CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_QR"
 BEFORE
  INSERT
 ON content_repo.juris_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/