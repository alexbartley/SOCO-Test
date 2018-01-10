CREATE OR REPLACE TRIGGER content_repo."INS_TAXABILITY_ELEMENTS" 
 BEFORE
  INSERT
 ON content_repo.taxability_elements
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_taxability_elements.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/