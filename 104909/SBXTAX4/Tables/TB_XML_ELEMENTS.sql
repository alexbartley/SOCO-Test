CREATE TABLE sbxtax4.tb_xml_elements (
  xml_element_id NUMBER NOT NULL,
  parent_xml_element_id NUMBER,
  "ELEMENT" VARCHAR2(100 CHAR) NOT NULL,
  tag_name VARCHAR2(100 CHAR),
  leaf_node VARCHAR2(1 CHAR) NOT NULL,
  error_tag VARCHAR2(1 CHAR) NOT NULL,
  in_out_flag VARCHAR2(1 CHAR),
  data_type VARCHAR2(100 CHAR),
  created_by NUMBER NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER NOT NULL,
  last_update_date DATE NOT NULL,
  obsolete_as_of VARCHAR2(1 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;