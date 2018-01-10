CREATE TABLE sbxtax3.ht_locations (
  "ACTIVE" VARCHAR2(1 BYTE),
  bill_to_flag VARCHAR2(1 BYTE),
  bill_to_usage_flag VARCHAR2(1 BYTE),
  city VARCHAR2(50 BYTE),
  country VARCHAR2(3 BYTE),
  county VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  district VARCHAR2(50 BYTE),
  geocode VARCHAR2(50 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  location_id NUMBER(10),
  merchant_id NUMBER(10),
  middleman_flag VARCHAR2(1 BYTE),
  middleman_usage_flag VARCHAR2(1 BYTE),
  "NAME" VARCHAR2(30 BYTE),
  notes VARCHAR2(240 BYTE),
  poa_flag VARCHAR2(1 BYTE),
  poa_usage_flag VARCHAR2(1 BYTE),
  poo_flag VARCHAR2(1 BYTE),
  poo_usage_flag VARCHAR2(1 BYTE),
  postcode VARCHAR2(50 BYTE),
  province VARCHAR2(50 BYTE),
  ship_from_flag VARCHAR2(1 BYTE),
  ship_from_usage_flag VARCHAR2(1 BYTE),
  ship_to_flag VARCHAR2(1 BYTE),
  ship_to_usage_flag VARCHAR2(1 BYTE),
  "STATE" VARCHAR2(50 BYTE),
  supply_flag VARCHAR2(1 BYTE),
  supply_usage_flag VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_location_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;