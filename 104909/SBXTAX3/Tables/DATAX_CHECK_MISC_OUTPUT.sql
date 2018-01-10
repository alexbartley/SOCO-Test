CREATE TABLE sbxtax3.datax_check_misc_output (
  data_check_id NUMBER NOT NULL,
  run_id NUMBER NOT NULL,
  creation_date DATE NOT NULL,
  primary_key NUMBER NOT NULL,
  table_name VARCHAR2(100 BYTE) NOT NULL,
  data_check_misc_output_id NUMBER NOT NULL,
  CONSTRAINT datax_check_misc_out_fk FOREIGN KEY (data_check_id) REFERENCES sbxtax3.datax_checks (data_check_id)
) 
TABLESPACE ositax;