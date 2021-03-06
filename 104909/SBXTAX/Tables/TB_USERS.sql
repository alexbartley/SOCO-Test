CREATE TABLE sbxtax.tb_users (
  user_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  username VARCHAR2(60 CHAR) NOT NULL,
  java_password VARCHAR2(16 CHAR) NOT NULL,
  last_update_date DATE,
  start_date DATE NOT NULL,
  end_date DATE,
  creation_date DATE,
  extension VARCHAR2(6 CHAR),
  deleted VARCHAR2(1 CHAR) NOT NULL,
  email VARCHAR2(60 CHAR),
  first_name VARCHAR2(30 CHAR) NOT NULL,
  last_name VARCHAR2(30 CHAR) NOT NULL,
  mi VARCHAR2(1 CHAR),
  phone VARCHAR2(20 CHAR),
  notes VARCHAR2(240 CHAR),
  created_by NUMBER NOT NULL,
  last_updated_by NUMBER(10),
  external_token VARCHAR2(36 CHAR) DEFAULT '.' NOT NULL,
  password_expiration_date DATE,
  password_never_expires VARCHAR2(1 CHAR),
  force_password_change VARCHAR2(1 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;