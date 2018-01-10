CREATE OR REPLACE PACKAGE content_repo."TAXAB_LOOKUP_DS"
  IS
-- Purpose: DEVLOPMENT PACKAGE for Lookup datasets for page sections
--          (piped out with ID and DECRIPTION for now)
--
-- Available lists
--  'HEADER_TAX_DESCRIPTION' - returns NAME
--  'HEADER_CODE' - returns REFERENCE_CODE
--
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- ---------   ------  ------------------------------------------


  -- TBL/DS
  TYPE outDSRec IS RECORD
   (description varchar2(64),
    id number
   );
  TYPE outDSTbl IS TABLE OF outDSRec;

  -- FN
  FUNCTION taxab_section_lookup(sectionName IN VARCHAR2)
  RETURN outDSTbl PIPELINED;

  -- PROC
  PROCEDURE lookup_cmbx(cmbx_name IN VARCHAR2
                       ,p_ref OUT SYS_REFCURSOR);

END;
 
 
/