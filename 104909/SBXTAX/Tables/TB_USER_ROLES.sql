CREATE TABLE sbxtax.tb_user_roles (
  user_role_id NUMBER NOT NULL,
  user_id NUMBER NOT NULL,
  role_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  grant_flag VARCHAR2(1 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  is_cascading VARCHAR2(1 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;