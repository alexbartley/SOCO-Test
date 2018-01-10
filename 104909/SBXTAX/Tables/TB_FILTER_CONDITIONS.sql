CREATE TABLE sbxtax.tb_filter_conditions (
  condition_id NUMBER NOT NULL,
  filter_id NUMBER NOT NULL,
  parent_condition_id NUMBER,
  ordering NUMBER NOT NULL,
  xml_element VARCHAR2(1500 BYTE),
  "OPERATOR" VARCHAR2(15 CHAR),
  "VALUE" VARCHAR2(250 CHAR),
  value_xml_element VARCHAR2(1500 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  reference_list_id NUMBER,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;