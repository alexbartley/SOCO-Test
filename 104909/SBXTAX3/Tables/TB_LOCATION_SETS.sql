CREATE TABLE sbxtax3.tb_location_sets (
  location_set_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(30 BYTE) NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) NOT NULL,
  notes VARCHAR2(240 BYTE),
  ship_from_location_id NUMBER(10),
  ship_to_location_id NUMBER(10),
  bill_to_location_id NUMBER(10),
  supply_location_id NUMBER(10),
  middleman_location_id NUMBER(10),
  poo_location_id NUMBER(10),
  poa_location_id NUMBER(10),
  buyer_primary_location_id NUMBER(10),
  seller_primary_location_id NUMBER(10),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;