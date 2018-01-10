CREATE TABLE content_repo.jurisdiction_relationships (
  "ID" NUMBER NOT NULL,
  jurisdiction_id NUMBER NOT NULL,
  related_jurisdiction_id NUMBER NOT NULL,
  relationship_type VARCHAR2(100 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  start_date DATE,
  end_date DATE,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  basis_amount_type VARCHAR2(50 CHAR),
  basis_value NUMBER,
  related_jurisdiction_nkid NUMBER NOT NULL,
  jurisdiction_nkid NUMBER NOT NULL
) 
TABLESPACE content_repo;