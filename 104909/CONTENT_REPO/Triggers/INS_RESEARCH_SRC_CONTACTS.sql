CREATE OR REPLACE TRIGGER content_repo."INS_RESEARCH_SRC_CONTACTS" 
 BEFORE
  INSERT
 ON content_repo.research_source_contacts
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_research_src_contacts.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/