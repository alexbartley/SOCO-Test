CREATE INDEX content_repo.dev_tnn_tat_local ON content_repo.tax_applicability_taxes(juris_tax_applicability_nkid)

LOCAL (PARTITION
  TABLESPACE tax_app_set,
PARTITION
  TABLESPACE tax_app_set,
PARTITION
  TABLESPACE tax_app_set,
PARTITION
  TABLESPACE tax_app_set,
PARTITION
  TABLESPACE tax_app_set,
PARTITION
  TABLESPACE tax_app_set);