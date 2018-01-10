CREATE TABLE sbxtax4.datax_check_out_columns (
  data_check_id NUMBER NOT NULL,
  table_column VARCHAR2(250 BYTE) NOT NULL,
  restrictions VARCHAR2(4000 BYTE),
  data_check_out_column_id NUMBER NOT NULL,
  CONSTRAINT datax_check_out_col_fk FOREIGN KEY (data_check_id) REFERENCES sbxtax4.datax_checks (data_check_id)
) 
TABLESPACE ositax;