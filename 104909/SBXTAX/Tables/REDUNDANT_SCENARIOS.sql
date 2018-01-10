CREATE TABLE sbxtax.redundant_scenarios (
  rate_scenario_id NUMBER NOT NULL,
  rate_scenario VARCHAR2(100 CHAR) NOT NULL,
  pt_scenario_id NUMBER NOT NULL,
  pt_scenario VARCHAR2(100 CHAR) NOT NULL,
  rate_target_tax_type VARCHAR2(2 CHAR),
  pt_target_tax_type VARCHAR2(2 CHAR)
) 
TABLESPACE ositax;