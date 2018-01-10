CREATE TABLE content_repo.kpmg_load_appl_manual (
  commodity_id NUMBER(20),
  juris_tax_id NUMBER(20),
  start_date DATE,
  end_date DATE
)
ORGANIZATION EXTERNAL
(TYPE ORACLE_LOADER
DEFAULT DIRECTORY EXTRACT_FILES
ACCESS PARAMETERS (
RECORDS DELIMITED BY
        NEWLINE SKIP 1 fields terminated BY ',' MISSING FIELD VALUES ARE NULL
)
LOCATION ('KPMG_Applicability_Manual.txt'));