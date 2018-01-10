CREATE TABLE content_repo.copy_taxability_commodities (
  process_id NUMBER,
  commodity_id NUMBER,
  copy_selected NUMBER DEFAULT 0,
  entry_date DATE DEFAULT sysdate,
  commodity_nkid NUMBER
) 
TABLESPACE content_repo;
COMMENT ON TABLE content_repo.copy_taxability_commodities IS 'Processing commodity copy list';