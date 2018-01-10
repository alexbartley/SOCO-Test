CREATE TABLE sbxtax2.tb_merchant_xml_elements (
  merchant_xml_element_id NUMBER NOT NULL,
  xml_group_id NUMBER NOT NULL,
  xml_element_id NUMBER NOT NULL,
  created_by NUMBER NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER NOT NULL,
  last_update_date DATE NOT NULL,
  is_returned VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;