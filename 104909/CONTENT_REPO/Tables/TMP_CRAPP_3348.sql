CREATE TABLE content_repo.tmp_crapp_3348 (
  authority_name VARCHAR2(100 BYTE),
  authority_type VARCHAR2(100 BYTE),
  admin_level VARCHAR2(50 BYTE),
  authority_ctageory VARCHAR2(200 BYTE),
  rate_code VARCHAR2(20 BYTE),
  rate_description VARCHAR2(200 BYTE),
  start_date DATE,
  end_date DATE,
  rate_type VARCHAR2(50 BYTE),
  amount_type VARCHAR2(30 BYTE),
  rate VARCHAR2(20 BYTE),
  min_threshold VARCHAR2(20 BYTE),
  max_limit VARCHAR2(200 BYTE),
  tier_rate_code VARCHAR2(20 BYTE),
  fee VARCHAR2(100 BYTE),
  comments VARCHAR2(300 BYTE)
) 
TABLESPACE content_repo;