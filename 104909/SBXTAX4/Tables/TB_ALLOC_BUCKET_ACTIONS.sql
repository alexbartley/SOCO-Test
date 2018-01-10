CREATE TABLE sbxtax4.tb_alloc_bucket_actions (
  alloc_bucket_action_id NUMBER NOT NULL,
  alloc_bucket_id NUMBER NOT NULL,
  prev_alloc_bucket_action_id NUMBER NOT NULL,
  xml_element VARCHAR2(250 CHAR),
  "VALUE" VARCHAR2(250 CHAR),
  value_xml_element VARCHAR2(250 CHAR),
  "OPERATOR" VARCHAR2(15 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;