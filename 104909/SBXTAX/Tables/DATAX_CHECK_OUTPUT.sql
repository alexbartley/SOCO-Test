CREATE TABLE sbxtax.datax_check_output (
  data_check_output_id NUMBER NOT NULL,
  primary_key NUMBER NOT NULL,
  data_check_id NUMBER NOT NULL,
  run_id NUMBER NOT NULL,
  creation_date DATE NOT NULL,
  reviewed_approved NUMBER,
  approved_date DATE,
  last_update_date DATE,
  verified VARCHAR2(20 BYTE),
  verified_date DATE,
  removed VARCHAR2(1 BYTE),
  step_info VARCHAR2(500 CHAR) DEFAULT null,
  CONSTRAINT datax_check_output_fk FOREIGN KEY (data_check_id) REFERENCES sbxtax.datax_checks (data_check_id)
) 
TABLESPACE ositax;