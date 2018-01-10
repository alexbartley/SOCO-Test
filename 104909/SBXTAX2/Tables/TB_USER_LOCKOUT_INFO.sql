CREATE TABLE sbxtax2.tb_user_lockout_info (
  user_lockout_id NUMBER(10) NOT NULL,
  user_id NUMBER(10) NOT NULL,
  failed_login_count NUMBER(10) NOT NULL,
  first_failed_at DATE NOT NULL,
  is_locked VARCHAR2(1 BYTE),
  locked_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;