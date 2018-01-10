CREATE OR REPLACE TRIGGER sbxtax."UPD_A_RATE_TIERS"
AFTER UPDATE OF
    RATE_ID,
    RATE,
    FLAT_FEE,
    AMOUNT_LOW,
    AMOUNT_HIGH,
    RATE_CODE
ON sbxtax.TB_RATE_TIERS
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
     WHEN (
(
decode(NEW.RATE_ID,OLD.RATE_ID,0,1) +
decode(NEW.RATE,OLD.RATE,0,1) +
decode(NEW.FLAT_FEE,OLD.FLAT_FEE,0,1) +
decode(NEW.AMOUNT_LOW,OLD.AMOUNT_LOW,0,1) +
decode(NEW.AMOUNT_HIGH,OLD.AMOUNT_HIGH,0,1) +
decode(NEW.RATE_CODE,OLD.RATE_CODE,0,1)
) > 0
) BEGIN
  INSERT INTO A_RATE_TIERS (
    RATE_TIER_ID,
    RATE_ID,
    RATE,
    FLAT_FEE,
    AMOUNT_LOW,
    AMOUNT_HIGH,
    RATE_CODE,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    --SYNCHRONIZATION_TIMESTAMP,
    RATE_TIER_ID_O,
    RATE_ID_O,
    RATE_O,
    FLAT_FEE_O,
    AMOUNT_LOW_O,
    AMOUNT_HIGH_O,
    RATE_CODE_O,
    CREATED_BY_O,
    CREATION_DATE_O,
    LAST_UPDATED_BY_O,
    LAST_UPDATE_DATE_O,
    --SYNCHRONIZATION_TIMESTAMP_O,
    CHANGE_TYPE,
    --CHANGE_VERSION,
    CHANGE_DATE
  ) VALUES (
    :NEW.RATE_TIER_ID,
    :NEW.RATE_ID,
    :NEW.RATE,
    :NEW.FLAT_FEE,
    :NEW.AMOUNT_LOW,
    :NEW.AMOUNT_HIGH,
    :NEW.RATE_CODE,
    :NEW.CREATED_BY,
    :NEW.CREATION_DATE,
    :NEW.LAST_UPDATED_BY,
    :NEW.LAST_UPDATE_DATE,
    --:NEW.SYNCHRONIZATION_TIMESTAMP,
    :OLD.RATE_TIER_ID,
    :OLD.RATE_ID,
    :OLD.RATE,
    :OLD.FLAT_FEE,
    :OLD.AMOUNT_LOW,
    :OLD.AMOUNT_HIGH,
    :OLD.RATE_CODE,
    :OLD.CREATED_BY,
    :OLD.CREATION_DATE,
    :OLD.LAST_UPDATED_BY,
    :OLD.LAST_UPDATE_DATE,
    --:OLD.SYNCHRONIZATION_TIMESTAMP,
    'UPDATED',
    --(SELECT CONTENT_VERSION FROM TB_MERCHANTS M, TB_RATES R WHERE M.MERCHANT_ID = R.MERCHANT_ID AND R.RATE_ID = :NEW.RATE_ID),
    SYSDATE);
END;
/