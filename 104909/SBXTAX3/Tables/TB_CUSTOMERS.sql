CREATE TABLE sbxtax3.tb_customers (
  customer_id NUMBER(10) NOT NULL,
  customer_comment VARCHAR2(2000 BYTE),
  contact_fax VARCHAR2(20 BYTE),
  customer_group_id NUMBER(10) NOT NULL,
  cust_number VARCHAR2(100 BYTE) NOT NULL,
  cust_name VARCHAR2(100 BYTE) NOT NULL,
  dba_name VARCHAR2(100 BYTE),
  address_1 VARCHAR2(60 BYTE),
  address_2 VARCHAR2(60 BYTE),
  address_3 VARCHAR2(60 BYTE),
  address_4 VARCHAR2(60 BYTE),
  city VARCHAR2(60 BYTE),
  st_code VARCHAR2(2 BYTE),
  zip_code VARCHAR2(50 BYTE),
  county_code VARCHAR2(3 BYTE),
  business_phone VARCHAR2(20 BYTE),
  contact_name VARCHAR2(60 BYTE),
  contact_email VARCHAR2(60 BYTE),
  contact_phone VARCHAR2(20 BYTE),
  contact_title VARCHAR2(100 BYTE),
  contact_department VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  file_id NUMBER(10),
  fully_exempt VARCHAR2(1 BYTE),
  country VARCHAR2(3 BYTE),
  province VARCHAR2(50 BYTE),
  district VARCHAR2(50 BYTE),
  "STATE" VARCHAR2(50 BYTE),
  county VARCHAR2(50 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;