CREATE TABLE sbxtax2.datax_flag_levels (
  flag_level_id NUMBER NOT NULL,
  flag_level_description VARCHAR2(100 BYTE) NOT NULL,
  CONSTRAINT datax_flag_levels_pk PRIMARY KEY (flag_level_id) USING INDEX 
    TABLESPACE ositax
) 
TABLESPACE ositax;