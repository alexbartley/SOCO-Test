CREATE TABLE sbxtax4.ct_report_library (
  report_id NUMBER NOT NULL,
  report_name VARCHAR2(200 BYTE) NOT NULL,
  report_code VARCHAR2(50 BYTE) NOT NULL,
  output_filename VARCHAR2(150 BYTE) NOT NULL,
  procedure_call VARCHAR2(4000 BYTE)
) 
TABLESPACE ositax;