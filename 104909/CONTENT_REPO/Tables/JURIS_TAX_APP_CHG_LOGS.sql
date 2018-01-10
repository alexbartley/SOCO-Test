CREATE TABLE content_repo.juris_tax_app_chg_logs (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  table_name VARCHAR2(50 CHAR) NOT NULL,
  primary_key NUMBER NOT NULL,
  entity_id NUMBER NOT NULL,
  reason_id NUMBER,
  "SUMMARY" VARCHAR2(1000 CHAR),
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT juris_tax_app_chg_logs_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT juris_tax_app_chg_logs_f1 FOREIGN KEY (reason_id) REFERENCES content_repo.change_reasons ("ID")
) TABLESPACE content_repo
PARTITION BY LIST (table_name)
(PARTITION tab_jta VALUES ('JURIS_TAX_APPLICABILITIES', 'TAXABILITY_OUTPUTS')
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION tab_trantax VALUES ('TRAN_TAX_QUALIFIERS', 'TRANSACTION_TAXABILITIES')
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION tab_appset VALUES ('TAX_APPLICABILITY_SETS')
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION tab_apptax VALUES ('TAX_APPLICABILITY_TAXES')
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION tab_taxrel VALUES ('TAX_RELATIONSHIPS')
  INDEXING ON
  TABLESPACE juris_tax_app_chg,
PARTITION tab_appattr VALUES ('JURIS_TAX_APP_ATTRIBUTES')
  INDEXING ON
  TABLESPACE content_repo);