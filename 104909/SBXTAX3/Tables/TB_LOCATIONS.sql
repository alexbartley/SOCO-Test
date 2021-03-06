CREATE TABLE sbxtax3.tb_locations (
  location_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(30 BYTE) NOT NULL,
  poo_flag VARCHAR2(1 BYTE),
  poa_flag VARCHAR2(1 BYTE),
  ship_from_flag VARCHAR2(1 BYTE),
  poo_usage_flag VARCHAR2(1 BYTE),
  poa_usage_flag VARCHAR2(1 BYTE),
  ship_from_usage_flag VARCHAR2(1 BYTE),
  "ACTIVE" VARCHAR2(1 BYTE),
  notes VARCHAR2(240 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  ship_to_flag VARCHAR2(1 BYTE),
  ship_to_usage_flag VARCHAR2(1 BYTE),
  bill_to_flag VARCHAR2(1 BYTE),
  supply_flag VARCHAR2(1 BYTE),
  middleman_flag VARCHAR2(1 BYTE),
  bill_to_usage_flag VARCHAR2(1 BYTE),
  supply_usage_flag VARCHAR2(1 BYTE),
  middleman_usage_flag VARCHAR2(1 BYTE),
  country VARCHAR2(3 BYTE),
  district VARCHAR2(50 BYTE),
  province VARCHAR2(50 BYTE),
  "STATE" VARCHAR2(50 BYTE),
  county VARCHAR2(50 BYTE),
  city VARCHAR2(50 BYTE),
  postcode VARCHAR2(50 BYTE),
  geocode VARCHAR2(50 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;