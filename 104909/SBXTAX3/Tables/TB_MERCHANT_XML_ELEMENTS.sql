CREATE TABLE sbxtax3.tb_merchant_xml_elements (
  merchant_xml_element_id NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10) NOT NULL,
  last_update_date DATE NOT NULL,
  xml_group_id NUMBER(10) NOT NULL,
  xml_element_id NUMBER(10) NOT NULL,
  is_returned VARCHAR2(1 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;