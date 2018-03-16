CREATE OR REPLACE TYPE alex_50215.ORACLE_ERROR_OBJ AS OBJECT

(

app_entity_val VARCHAR2(100),

app_module VARCHAR2(30),

app_err_messg VARCHAR2(10000),

oracle_err_code NUMBER,

oracle_err_messg VARCHAR2(10000),

severity CHAR(1),

-- Common severity abbreviations:

-- E = error

-- W = warning

-- I = information

CONSTRUCTOR FUNCTION oracle_error_obj(app_entity_val VARCHAR2

,app_module VARCHAR2

,app_err_messg VARCHAR2

,oracle_err_code NUMBER

,oracle_err_messg VARCHAR2

,severity CHAR) RETURN SELF AS RESULT

)

NOT FINAL
/
CREATE OR REPLACE TYPE BODY alex_50215.ORACLE_ERROR_OBJ AS

CONSTRUCTOR FUNCTION oracle_error_obj(app_entity_val VARCHAR2

,app_module VARCHAR2

,app_err_messg VARCHAR2

,oracle_err_code NUMBER

,oracle_err_messg VARCHAR2

,severity CHAR) RETURN SELF AS RESULT IS

BEGIN

SELF.app_entity_val := app_entity_val;

SELF.app_module := app_module;

SELF.app_err_messg := app_err_messg;

SELF.oracle_err_code := oracle_err_code;

SELF.oracle_err_messg := oracle_err_messg;

SELF.severity := severity;

RETURN;

END;

END;
/