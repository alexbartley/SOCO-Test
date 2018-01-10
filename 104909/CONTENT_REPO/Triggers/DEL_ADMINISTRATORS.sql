CREATE OR REPLACE TRIGGER content_repo."DEL_ADMINISTRATORS" 
 AFTER 
 DELETE
 ON content_repo.ADMINISTRATORS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
    DELETE FROM admin_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'ADMINISTRATORS';
    DELETE FROM administrator_contacts WHERE administrator_id = :old.id;
END;
/