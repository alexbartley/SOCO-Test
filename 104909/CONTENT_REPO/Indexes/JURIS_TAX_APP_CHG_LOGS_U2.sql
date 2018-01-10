CREATE UNIQUE INDEX content_repo.juris_tax_app_chg_logs_u2 ON content_repo.juris_tax_app_chg_logs(table_name,rid,primary_key)

LOCAL (PARTITION tab_jta
  TABLESPACE juris_tax_app_chg,
PARTITION tab_trantax
  TABLESPACE juris_tax_app_chg,
PARTITION tab_appset
  TABLESPACE juris_tax_app_chg,
PARTITION tab_apptax
  TABLESPACE juris_tax_app_chg,
PARTITION tab_taxrel
  TABLESPACE juris_tax_app_chg,
PARTITION tab_appattr
  TABLESPACE content_repo);