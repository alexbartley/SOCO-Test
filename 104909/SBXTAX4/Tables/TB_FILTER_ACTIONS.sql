CREATE TABLE sbxtax4.tb_filter_actions (
  action_id NUMBER NOT NULL,
  filter_id NUMBER NOT NULL,
  ordering NUMBER NOT NULL,
  xml_element VARCHAR2(250 CHAR),
  "VALUE" VARCHAR2(250 CHAR),
  value_xml_element VARCHAR2(1500 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "OPERATOR" VARCHAR2(15 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;