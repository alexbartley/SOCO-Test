CREATE OR REPLACE TRIGGER content_repo.ins_juris_type_qr
 BEFORE
  INSERT
 ON content_repo.juris_type_qr
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_type_qr.nextval;
:new.entered_date := SYSTIMESTAMP;

END;
/