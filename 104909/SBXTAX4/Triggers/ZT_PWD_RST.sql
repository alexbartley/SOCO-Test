CREATE OR REPLACE TRIGGER sbxtax4."ZT_PWD_RST" 
 BEFORE 
 INSERT OR UPDATE
 ON sbxtax4.TB_USERS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
      WHEN (NEW.username = 'Admin'
) BEGIN
    :NEW.JAVA_PASSWORD := '1uT6c441FvZcjwre';
END DT_PWD_RST;
/