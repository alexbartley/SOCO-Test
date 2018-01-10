CREATE TABLE sbxtax3.tb_xml_groups (
  xml_group_id NUMBER(10) NOT NULL,
  xml_group_name VARCHAR2(100 BYTE) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10) NOT NULL,
  last_update_date DATE NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;