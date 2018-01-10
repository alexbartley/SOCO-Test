CREATE OR REPLACE FUNCTION content_repo."FNNOHTML" (p_string IN CLOB) RETURN CLOB
IS
-- *****************************************************************************
-- Description: remove html tags from a clob
--
-- Revision History
-- Date            Author           Reason for Change
-- ----------------------------------------------------------------
-- -                                -
-- *****************************************************************************
-- Notes
  v_nohtml_out CLOB;
begin
  SELECT REGEXP_REPLACE(p_string, '<[^>]+>', '') newval
  INTO v_nohtml_out
  FROM dual;
  RETURN v_nohtml_out;
END;
 
 
/