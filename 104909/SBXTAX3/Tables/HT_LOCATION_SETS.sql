CREATE TABLE sbxtax3.ht_location_sets (
  "ACTIVE" VARCHAR2(1 BYTE),
  bill_to_location_id NUMBER(10),
  buyer_primary_location_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  location_set_id NUMBER(10),
  merchant_id NUMBER(10),
  middleman_location_id NUMBER(10),
  "NAME" VARCHAR2(30 BYTE),
  notes VARCHAR2(240 BYTE),
  poa_location_id NUMBER(10),
  poo_location_id NUMBER(10),
  seller_primary_location_id NUMBER(10),
  ship_from_location_id NUMBER(10),
  ship_to_location_id NUMBER(10),
  supply_location_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_location_set_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;