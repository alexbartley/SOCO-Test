CREATE TABLE sbxtax2.tb_user_roles (
  user_id NUMBER NOT NULL,
  role_id NUMBER(10) NOT NULL,
  merchant_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  grant_flag VARCHAR2(1 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  user_role_id NUMBER NOT NULL,
  is_cascading VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;