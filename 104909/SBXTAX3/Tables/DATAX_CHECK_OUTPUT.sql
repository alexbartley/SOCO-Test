CREATE TABLE sbxtax3.datax_check_output (
  data_check_output_id NUMBER NOT NULL,
  primary_key NUMBER NOT NULL,
  data_check_id NUMBER NOT NULL,
  run_id NUMBER NOT NULL,
  creation_date DATE NOT NULL,
  reviewed_approved VARCHAR2(20 BYTE),
  removed VARCHAR2(1 BYTE),
  verified VARCHAR2(20 BYTE),
  last_update_date DATE,
  approved_date DATE,
  verified_date DATE,
  CONSTRAINT datax_check_output_fk FOREIGN KEY (data_check_id) REFERENCES sbxtax3.datax_checks (data_check_id)
) 
TABLESPACE ositax;