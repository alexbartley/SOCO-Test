CREATE TABLE sbxtax3.datax_output_save (
  data_output_save_id NUMBER NOT NULL,
  data_check_id NUMBER NOT NULL,
  primary_key NUMBER NOT NULL,
  original_run_id NUMBER NOT NULL,
  repeated_run_id NUMBER NOT NULL,
  CONSTRAINT datax_output_save_fk1 FOREIGN KEY (data_check_id) REFERENCES sbxtax3.datax_checks (data_check_id)
) 
TABLESPACE ositax;