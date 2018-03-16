CREATE TABLE sbxtax2.tb_users (
  user_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  username VARCHAR2(60 BYTE) NOT NULL,
  email VARCHAR2(60 BYTE),
  first_name VARCHAR2(30 BYTE) NOT NULL,
  last_name VARCHAR2(30 BYTE) NOT NULL,
  mi VARCHAR2(1 BYTE),
  phone VARCHAR2(20 BYTE),
  notes VARCHAR2(240 BYTE),
  created_by NUMBER NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  start_date DATE NOT NULL,
  end_date DATE,
  creation_date DATE,
  extension VARCHAR2(6 BYTE),
  deleted VARCHAR2(1 BYTE) NOT NULL,
  java_password VARCHAR2(16 BYTE) NOT NULL,
  external_token VARCHAR2(36 BYTE) DEFAULT '.' NOT NULL,
  password_expiration_date DATE,
  password_never_expires VARCHAR2(1 BYTE),
  force_password_change VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;