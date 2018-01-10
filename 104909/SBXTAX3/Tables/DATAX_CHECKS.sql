CREATE TABLE sbxtax3.datax_checks (
  data_check_id NUMBER NOT NULL,
  flag_level_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  description VARCHAR2(1000 BYTE),
  active_f VARCHAR2(1 BYTE) NOT NULL,
  active_g VARCHAR2(1 BYTE) NOT NULL,
  "CATEGORY" VARCHAR2(100 BYTE) NOT NULL,
  purpose_reference VARCHAR2(1000 BYTE),
  data_owner_table VARCHAR2(100 BYTE) NOT NULL,
  procedure_name VARCHAR2(100 BYTE),
  view_name VARCHAR2(100 BYTE),
  tax_research_only VARCHAR2(1 BYTE),
  production_only VARCHAR2(1 BYTE),
  CONSTRAINT datax_checks_pk PRIMARY KEY (data_check_id) USING INDEX 
    TABLESPACE ositax,
  CONSTRAINT datax_check_flag_level_fk FOREIGN KEY (flag_level_id) REFERENCES sbxtax3.datax_flag_levels (flag_level_id)
) 
TABLESPACE ositax;