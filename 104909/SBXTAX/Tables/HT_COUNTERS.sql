CREATE TABLE sbxtax.ht_counters (
  "NAME" VARCHAR2(32 BYTE) NOT NULL,
  "VALUE" NUMBER(20) NOT NULL,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;