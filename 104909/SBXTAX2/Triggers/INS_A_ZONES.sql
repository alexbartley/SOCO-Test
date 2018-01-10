CREATE OR REPLACE TRIGGER sbxtax2.INS_A_ZONES
  AFTER INSERT ON sbxtax2.TB_ZONES
  REFERENCING FOR EACH ROW
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
    'CREATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M WHERE M.MERCHANT_ID = :NEW.MERCHANT_ID),
    SYSDATE);
    END IF;--ONLY UPDATE/INSERT/DELETE IF ABOVE A CITY LEVEL
END;
/