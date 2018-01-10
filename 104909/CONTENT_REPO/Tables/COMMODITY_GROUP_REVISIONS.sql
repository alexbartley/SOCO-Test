CREATE TABLE content_repo.commodity_group_revisions (
  "ID" NUMBER,
  nkid NUMBER,
  entered_by NUMBER,
  entered_date TIMESTAMP,
  status NUMBER DEFAULT 0,
  status_modified_date TIMESTAMP,
  next_rid NUMBER,
  summ_ass_status NUMBER DEFAULT 0
) 
TABLESPACE content_repo;