CREATE TABLE sbxtax3.update_canada_pt (
  product VARCHAR2(500 BYTE),
  commodity_code VARCHAR2(500 BYTE),
  ghq VARCHAR2(500 BYTE),
  bc VARCHAR2(500 BYTE),
  man VARCHAR2(500 BYTE),
  ont VARCHAR2(500 BYTE),
  pei VARCHAR2(500 BYTE),
  sas VARCHAR2(500 BYTE),
  pc_id NUMBER,
  ghq_rule NUMBER,
  bc_rule NUMBER,
  man_rule NUMBER,
  ont_rule NUMBER,
  pei_rule NUMBER,
  sas_rule NUMBER,
  product_for_rule NUMBER
) 
TABLESPACE ositax;