CREATE TABLE content_repo.impl_process_levels (
  process_id NUMBER,
  r_level NUMBER,
  impl NUMBER,
  commodity_id NUMBER,
  juris_tax_applicability_id NUMBER,
  reference_code VARCHAR2(100 BYTE),
  applyfromcomm NUMBER,
  source_h_code VARCHAR2(128 BYTE)
) 
TABLESPACE content_repo;