CREATE TABLE content_repo.geo_unique_area_revisions (
  "ID" NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  entered_by NUMBER NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  summ_ass_status NUMBER DEFAULT 0,
  next_rid NUMBER,
  CONSTRAINT geo_unique_area_rev_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;