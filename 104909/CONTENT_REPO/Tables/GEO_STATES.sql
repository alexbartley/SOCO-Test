CREATE TABLE content_repo.geo_states (
  "ID" NUMBER NOT NULL,
  state_code VARCHAR2(2 CHAR) NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  start_date DATE,
  end_date DATE,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  fips VARCHAR2(2 CHAR),
  CONSTRAINT geo_states_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT geo_states_un UNIQUE (state_code) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;