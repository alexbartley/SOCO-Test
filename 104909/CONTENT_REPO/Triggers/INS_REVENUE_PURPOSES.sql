CREATE OR REPLACE TRIGGER content_repo."INS_REVENUE_PURPOSES" 
 BEFORE
  INSERT
 ON content_repo.revenue_purposes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_revenue_purposes.nextval;
:new.entered_Date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/