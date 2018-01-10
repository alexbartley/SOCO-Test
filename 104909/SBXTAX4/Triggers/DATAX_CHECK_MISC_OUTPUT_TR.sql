CREATE OR REPLACE TRIGGER sbxtax4."DATAX_CHECK_MISC_OUTPUT_TR" 
 BEFORE
  INSERT
 ON sbxtax4.datax_check_misc_output
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
      SELECT datax_check_misc_out_seq.NEXTVAL INTO :new.data_check_misc_output_id FROM dual;
  END;
/