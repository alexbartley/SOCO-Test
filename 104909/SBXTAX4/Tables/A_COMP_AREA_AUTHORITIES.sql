CREATE TABLE sbxtax4.a_comp_area_authorities (
  compliance_area_auth_id NUMBER(10),
  compliance_area_auth_id_o NUMBER(10),
  compliance_area_id NUMBER(10),
  compliance_area_id_o NUMBER(10),
  authority_id NUMBER(10),
  authority_id_o NUMBER(10),
  created_by NUMBER(10),
  created_by_o NUMBER(10),
  creation_date DATE,
  creation_date_o DATE,
  last_updated_by NUMBER(10),
  last_updated_by_o NUMBER(10),
  last_update_date DATE,
  last_update_date_o DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  change_date DATE,
  change_type VARCHAR2(100 CHAR),
  change_version VARCHAR2(50 CHAR) NOT NULL
) 
TABLESPACE ositax;