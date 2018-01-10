CREATE OR REPLACE TRIGGER sbxtax."DATAX_APP_SIG_TR" 
 BEFORE
  INSERT
 ON sbxtax.datax_approval_signatures
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_app_sig_seq.NEXTVAL INTO :new.approval_signature_id FROM dual;
  END;
/