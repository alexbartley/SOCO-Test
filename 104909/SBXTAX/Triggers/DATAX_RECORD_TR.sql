CREATE OR REPLACE TRIGGER sbxtax."DATAX_RECORD_TR" 
 BEFORE
  INSERT
 ON sbxtax.datax_records
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_record_seq.NEXTVAL, SYSDATE INTO :new.record_id, :new.record_date FROM dual;
      IF :new.run_id IS NULL THEN
        SELECT datax_run_seq.NEXTVAL INTO :new.run_id  FROM dual;
      END IF;
  END;
/