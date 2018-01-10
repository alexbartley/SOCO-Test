CREATE TABLE sbxtax4.tb_location_sets (
  location_set_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(30 CHAR) NOT NULL,
  "ACTIVE" VARCHAR2(1 CHAR) NOT NULL,
  notes VARCHAR2(240 CHAR),
  ship_from_location_id NUMBER,
  ship_to_location_id NUMBER,
  bill_to_location_id NUMBER,
  supply_location_id NUMBER,
  middleman_location_id NUMBER,
  poo_location_id NUMBER,
  poa_location_id NUMBER,
  buyer_primary_location_id NUMBER,
  seller_primary_location_id NUMBER,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;