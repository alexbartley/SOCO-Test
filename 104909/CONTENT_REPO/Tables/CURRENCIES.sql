CREATE TABLE content_repo.currencies (
  "ID" NUMBER NOT NULL,
  currency_code VARCHAR2(100 CHAR) NOT NULL,
  description VARCHAR2(1000 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  CONSTRAINT currencies_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT currencies_un UNIQUE (currency_code) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;