CREATE OR REPLACE TRIGGER content_repo."INS_CITATIONS" 
 BEFORE
  INSERT
 ON content_repo.citations
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_CITATIONS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/