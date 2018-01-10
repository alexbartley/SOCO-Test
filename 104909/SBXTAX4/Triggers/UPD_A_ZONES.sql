CREATE OR REPLACE TRIGGER sbxtax4.UPD_A_ZONES
  AFTER UPDATE OF NAME, PARENT_ZONE_ID, TAX_PARENT_ZONE_ID, MERCHANT_ID, ZONE_LEVEL_ID, EU_ZONE_AS_OF_DATE, CODE_2CHAR, CODE_3CHAR, CODE_ISO, CODE_FIPS, REVERSE_FLAG, TERMINATOR_FLAG, DEFAULT_FLAG, RANGE_MIN, RANGE_MAX,EU_EXIT_DATE,GCC_AS_OF_DATE,GCC_EXIT_DATE 
  ON sbxtax4.TB_ZONES
  REFERENCING FOR EACH ROW
 WHEN (
(
decode(NEW.NAME,OLD.NAME,0,1) +
decode(NEW.PARENT_ZONE_ID,OLD.PARENT_ZONE_ID,0,1) +
decode(NEW.TAX_PARENT_ZONE_ID,OLD.TAX_PARENT_ZONE_ID,0,1) +
decode(NEW.MERCHANT_ID,OLD.MERCHANT_ID,0,1) +
decode(NEW.ZONE_LEVEL_ID,OLD.ZONE_LEVEL_ID,0,1) +
decode(NEW.EU_ZONE_AS_OF_DATE,OLD.EU_ZONE_AS_OF_DATE,0,1) +
decode(NEW.CODE_2CHAR,OLD.CODE_2CHAR,0,1) +
decode(NEW.CODE_3CHAR,OLD.CODE_3CHAR,0,1) +
decode(NEW.CODE_ISO,OLD.CODE_ISO,0,1) +
decode(NEW.CODE_FIPS,OLD.CODE_FIPS,0,1) +
decode(NEW.REVERSE_FLAG,OLD.REVERSE_FLAG,0,1) +
decode(NEW.TERMINATOR_FLAG,OLD.TERMINATOR_FLAG,0,1) +
decode(NEW.DEFAULT_FLAG,OLD.DEFAULT_FLAG,0,1) +
decode(NEW.RANGE_MIN,OLD.RANGE_MIN,0,1) +
decode(NEW.RANGE_MAX,OLD.RANGE_MAX,0,1) +
decode(NEW.EU_EXIT_DATE,OLD.EU_EXIT_DATE,0,1)+
decode(NEW.GCC_AS_OF_DATE,OLD.GCC_AS_OF_DATE,0,1)+
decode(NEW.GCC_EXIT_DATE,OLD.GCC_EXIT_DATE,0,1)
) > 0
)
  BEGIN
  IF :NEW.ZONE_LEVEL_ID>-8 THEN 
  INSERT INTO A_ZONES (
ZONE_ID,
NAME,
PARENT_ZONE_ID,
TAX_PARENT_ZONE_ID,
MERCHANT_ID,
ZONE_LEVEL_ID,
EU_ZONE_AS_OF_DATE,
CODE_2CHAR,
CODE_3CHAR,
CODE_ISO,
CODE_FIPS,
CREATED_BY,
CREATION_DATE,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
--SYNCHRONIZATION_TIMESTAMP,
REVERSE_FLAG,
TERMINATOR_FLAG,
DEFAULT_FLAG,
RANGE_MIN,
RANGE_MAX,
EU_EXIT_DATE,
GCC_AS_OF_DATE,
GCC_EXIT_DATE,
ZONE_ID_O,
NAME_O,
PARENT_ZONE_ID_O,
TAX_PARENT_ZONE_ID_O,
MERCHANT_ID_O,
ZONE_LEVEL_ID_O,
EU_ZONE_AS_OF_DATE_O,
CODE_2CHAR_O,
CODE_3CHAR_O,
CODE_ISO_O,
CODE_FIPS_O,
CREATED_BY_O,
CREATION_DATE_O,
LAST_UPDATED_BY_O,
LAST_UPDATE_DATE_O,
--SYNCHRONIZATION_TIMESTAMP_O,
REVERSE_FLAG_O,
TERMINATOR_FLAG_O,
DEFAULT_FLAG_O,
RANGE_MIN_O,
RANGE_MAX_O,
EU_EXIT_DATE_O,
GCC_AS_OF_DATE_O,
GCC_EXIT_DATE_O,
CHANGE_TYPE,
--CHANGE_VERSION,
CHANGE_DATE
  ) VALUES (
:NEW.ZONE_ID,
:NEW.NAME,
:NEW.PARENT_ZONE_ID,
:NEW.TAX_PARENT_ZONE_ID,
:NEW.MERCHANT_ID,
:NEW.ZONE_LEVEL_ID,
:NEW.EU_ZONE_AS_OF_DATE,
:NEW.CODE_2CHAR,
:NEW.CODE_3CHAR,
:NEW.CODE_ISO,
:NEW.CODE_FIPS,
:NEW.CREATED_BY,
:NEW.CREATION_DATE,
:NEW.LAST_UPDATED_BY,
:NEW.LAST_UPDATE_DATE,
--:NEW.SYNCHRONIZATION_TIMESTAMP,
:NEW.REVERSE_FLAG,
:NEW.TERMINATOR_FLAG,
:NEW.DEFAULT_FLAG,
:NEW.RANGE_MIN,
:NEW.RANGE_MAX,
:NEW.EU_EXIT_DATE,
:NEW.GCC_AS_OF_DATE,
:NEW.GCC_EXIT_DATE,
:OLD.ZONE_ID,
:OLD.NAME,
:OLD.PARENT_ZONE_ID,
:OLD.TAX_PARENT_ZONE_ID,
:OLD.MERCHANT_ID,
:OLD.ZONE_LEVEL_ID,
:OLD.EU_ZONE_AS_OF_DATE,
:OLD.CODE_2CHAR,
:OLD.CODE_3CHAR,
:OLD.CODE_ISO,
:OLD.CODE_FIPS,
:OLD.CREATED_BY,
:OLD.CREATION_DATE,
:OLD.LAST_UPDATED_BY,
:OLD.LAST_UPDATE_DATE,
--:OLD.SYNCHRONIZATION_TIMESTAMP,
:OLD.REVERSE_FLAG,
:OLD.TERMINATOR_FLAG,
:OLD.DEFAULT_FLAG,
:OLD.RANGE_MIN,
:OLD.RANGE_MAX,
:OLD.EU_EXIT_DATE,
:OLD.GCC_AS_OF_DATE,
:OLD.GCC_EXIT_DATE,
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M WHERE M.MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
    END IF;--ONLY UPDATE/INSERT/DELETE IF ABOVE A CITY LEVEL
END;
/