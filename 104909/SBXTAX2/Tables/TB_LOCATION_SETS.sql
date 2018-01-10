CREATE TABLE sbxtax2.tb_location_sets (
  location_set_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(30 BYTE) NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) NOT NULL,
  poo_location_id NUMBER,
  poa_location_id NUMBER,
  notes VARCHAR2(240 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  ship_from_location_id NUMBER,
  last_update_date DATE,
  ship_to_location_id NUMBER,
  bill_to_location_id NUMBER,
  supply_location_id NUMBER,
  middleman_location_id NUMBER,
  buyer_primary_location_id NUMBER,
  seller_primary_location_id NUMBER,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;