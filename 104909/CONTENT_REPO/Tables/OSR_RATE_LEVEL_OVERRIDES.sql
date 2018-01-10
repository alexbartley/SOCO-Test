CREATE TABLE content_repo.osr_rate_level_overrides (
  state_code VARCHAR2(2 CHAR),
  official_name VARCHAR2(150 CHAR),
  nkid NUMBER,
  rate_level VARCHAR2(10 CHAR),
  unabated CHAR(1 CHAR)
) 
TABLESPACE content_repo;