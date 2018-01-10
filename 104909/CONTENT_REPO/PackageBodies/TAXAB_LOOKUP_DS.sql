CREATE OR REPLACE PACKAGE BODY content_repo."TAXAB_LOOKUP_DS"
IS
--
-- Taxability Lookup
--
--
-- Purpose: Development purpose only Lookup datasets for page sections
--
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- ---------   ------  ------------------------------------------
--
--

  -- FN
  FUNCTION taxab_section_lookup(sectionName IN VARCHAR2)
  RETURN outDSTbl PIPELINED
  IS
    dataRecord outDSRec;
    cursor_cmbx SYS_REFCURSOR;
  BEGIN
    lookup_cmbx(sectionName, cursor_cmbx);
    IF cursor_cmbx%ISOPEN THEN
    LOOP
      FETCH cursor_cmbx INTO dataRecord;
      EXIT WHEN cursor_cmbx%NOTFOUND;
      PIPE row(dataRecord);
    END LOOP;
    CLOSE cursor_cmbx;
    END IF;
  END taxab_section_lookup;

  /** Cmt
   *
   * Note: Descr data is empty - using the name just to get some text
   SELECT distinct description, id
   FROM tax_descriptions
   ORDER BY description;
   */
  PROCEDURE lookup_cmbx(cmbx_name IN VARCHAR2
                       ,p_ref OUT SYS_REFCURSOR)
  IS
  BEGIN
    CASE cmbx_name
    WHEN 'HEADER_TAX_DESCRIPTION'
        THEN
           OPEN p_ref FOR
                SELECT distinct name, id
                  FROM tax_descriptions
              ORDER BY name;
        WHEN 'HEADER_CODE'
        THEN
           OPEN p_ref FOR
                SELECT DISTINCT reference_code, id
                  FROM juris_tax_impositions
              ORDER BY reference_code;
     END CASE;
  END lookup_cmbx;

END;
/