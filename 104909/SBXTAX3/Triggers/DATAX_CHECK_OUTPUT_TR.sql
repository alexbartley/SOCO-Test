CREATE OR REPLACE TRIGGER sbxtax3."DATAX_CHECK_OUTPUT_TR" 
 BEFORE
  INSERT
 ON sbxtax3.datax_check_output
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_check_out_seq.NEXTVAL INTO :new.data_check_output_id FROM dual;
  END;
/