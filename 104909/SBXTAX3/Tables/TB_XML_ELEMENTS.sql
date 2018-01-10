CREATE TABLE sbxtax3.tb_xml_elements (
  xml_element_id NUMBER(10) NOT NULL,
  parent_xml_element_id NUMBER(10),
  "ELEMENT" VARCHAR2(100 BYTE) NOT NULL,
  tag_name VARCHAR2(100 BYTE),
  leaf_node VARCHAR2(1 BYTE) NOT NULL,
  error_tag VARCHAR2(1 BYTE) NOT NULL,
  in_out_flag VARCHAR2(1 BYTE) NOT NULL,
  data_type VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10) NOT NULL,
  last_update_date DATE NOT NULL,
  obsolete_as_of VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;