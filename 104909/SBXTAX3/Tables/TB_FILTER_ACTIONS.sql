CREATE TABLE sbxtax3.tb_filter_actions (
  action_id NUMBER(10) NOT NULL,
  filter_id NUMBER(10) NOT NULL,
  ordering NUMBER(10) NOT NULL,
  xml_element VARCHAR2(250 BYTE),
  "VALUE" VARCHAR2(250 BYTE),
  value_xml_element VARCHAR2(1500 BYTE),
  "OPERATOR" VARCHAR2(15 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;