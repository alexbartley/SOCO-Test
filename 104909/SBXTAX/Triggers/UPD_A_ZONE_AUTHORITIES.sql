CREATE OR REPLACE TRIGGER sbxtax."UPD_A_ZONE_AUTHORITIES"
AFTER UPDATE OF
ZONE_ID,
AUTHORITY_ID
ON sbxtax.TB_ZONE_AUTHORITIES
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
     WHEN (
(
decode(NEW.ZONE_AUTHORITY_ID,OLD.ZONE_AUTHORITY_ID,0,1) +
decode(NEW.ZONE_ID,OLD.ZONE_ID,0,1) +
decode(NEW.AUTHORITY_ID,OLD.AUTHORITY_ID,0,1)
) > 0
) DECLARE
  l_zone_level_id number;
BEGIN
SELECT ZONE_LEVEL_ID
INTO l_zone_level_id
FROM TB_ZONES WHERE ZONE_ID = :NEW.ZONE_ID;

 IF l_zone_level_id >-8 THEN
  INSERT INTO A_ZONE_AUTHORITIES (
ZONE_AUTHORITY_ID,
ZONE_ID,
AUTHORITY_ID,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
--SYNCHRONIZATION_TIMESTAMP,
ZONE_AUTHORITY_ID_O,
ZONE_ID_O,
AUTHORITY_ID_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:NEW.ZONE_AUTHORITY_ID,
:NEW.ZONE_ID,
:NEW.AUTHORITY_ID,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
:OLD.ZONE_AUTHORITY_ID,
:OLD.ZONE_ID,
:OLD.AUTHORITY_ID,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
--:OLD.SYNCHRONIZATION_TIMESTAMP,
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_AUTHORITIES A WHERE A.AUTHORITY_ID = :NEW.AUTHORITY_ID AND M.MERCHANT_ID = A.MERCHANT_ID),
    SYSDATE);
    END IF;
END;
/