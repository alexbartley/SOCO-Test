CREATE TABLE sbxtax2.ct_calc_method_mappings (
  rule_id NUMBER NOT NULL,
  f_calc_method NUMBER NOT NULL,
  approved_by VARCHAR2(100 BYTE),
  approved_date DATE
) 
TABLESPACE ositax;