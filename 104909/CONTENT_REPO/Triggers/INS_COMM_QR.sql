CREATE OR REPLACE TRIGGER content_repo."INS_COMM_QR"
 BEFORE
  INSERT
 ON content_repo.comm_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_comm_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/