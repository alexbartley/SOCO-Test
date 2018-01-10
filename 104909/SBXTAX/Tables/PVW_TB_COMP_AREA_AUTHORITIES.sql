CREATE TABLE sbxtax.pvw_tb_comp_area_authorities (
  compliance_area_auth_id NUMBER(10),
  compliance_area_id NUMBER(10),
  authority_id NUMBER(10),
  authority_name VARCHAR2(100 CHAR),
  change_type VARCHAR2(20 CHAR),
  compliance_area_uuid VARCHAR2(32 CHAR)
) 
TABLESPACE ositax;