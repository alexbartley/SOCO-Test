CREATE OR REPLACE FUNCTION content_repo."NNT_DASHINCONVERT"
(astidlist IN VARCHAR2, sSection IN NUMBER) RETURN VARCHAR2 IS
/**
 * Dev Copy/ Test/ Concept
 * Build exclusion list of id's
 * currently only using this function to get one of the lists back
 * future dev; change to procedure to set IN and exclude list
 */

 astInclude varchar2(128) DEFAULT null;
 astExclude varchar2(128) DEFAULT NULL;
 astReturn varchar2(256) :='';
 x CLOB;
 TYPE sectionRecord IS RECORD
 (id NUMBER,
  tabname varchar2(32),
  ixcolumn varchar2(32));
 TYPE sectionTable IS TABLE OF sectionRecord; -- INDEX BY BINARY_INTEGER;
 sections sectionTable;
BEGIN
 sections := sectionTable();
IF astidlist IS NOT NULL then

  /**
   * Internal temp table -- Table, key column
   * put these in an Oracle table instead of this type table
   * might want to use some sort of prefix for tables eg. cva/cvb
   */
  sections.extend();
  -- sections(sections.last)
  sections(1).id := 1;
  sections(1).tabname := 'admin_chg_vlds';
  sections(1).ixcolumn :='admin_chg_log_id';
  sections.extend();
  sections(2).id := 2;
  sections(2).tabname := 'juris_chg_vlds';
  sections(2).ixcolumn :='juris_chg_log_id';
  sections.extend();
  sections(3).id := 3;
  sections(3).tabname := 'juris_tax_chg_vlds';
  sections(3).ixcolumn :='juris_tax_chg_log_id';
  sections.extend();
  sections(4).id := 4;
  sections(4).tabname := 'juris_tax_app_chg_vlds';
  sections(4).ixcolumn :='juris_tax_app_chg_log_id';
  -- for section 5 and 6:
  -- call this one for each section before building the query to get both
  -- 5 and 6
  sections.extend();
  sections(5).id := 5;
  sections(5).tabname := 'comm_chg_vlds';
  sections(5).ixcolumn :='comm_chg_log_id';
  sections.extend();
  sections(6).id := 6;
  sections(6).tabname := 'comm_grp_chg_vlds';
  sections(6).ixcolumn :='comm_grp_chg_log_id';

  sections.extend();
  sections(7).id := 6;
  sections(7).tabname := 'comm_grp_chg_vlds';
  sections(7).ixcolumn :='comm_grp_chg_log_id';

  sections.extend();
  sections(8).id := 6;
  sections(8).tabname := 'comm_grp_chg_vlds';
  sections(8).ixcolumn :='comm_grp_chg_log_id';

  sections.extend();
  sections(9).id := 9;
  sections(9).tabname := 'ref_grp_chg_vlds';
  sections(9).ixcolumn :='ref_grp_chg_log_id';

  x:='WITH t AS (SELECT '''||astidlist||''' col1 FROM dual)
  SELECT MAX(decode(VXIn,1,astID)), max(decode(VXIn,2,astID))
  from
  (SELECT DISTINCT
  VXIn, ''IN(''|| LISTAGG(codes, '','') WITHIN GROUP (ORDER BY VXIn) over (PARTITION BY VXIn)||'')'' astID
  from
  (
  SELECT x,lengthof,
    decode(instr(column_codes,''-''),0,1,2) VXIn, ABS(column_codes) Codes from
    (SELECT LEVEL x,
    LENGTH(REGEXP_REPLACE(t.col1, ''[^,]+'')) + 1 lengthof,
     REPLACE(REGEXP_SUBSTR(t.col1, ''([-[:alnum:]]*)(,|$)'', 1, ROWNUM), '','') column_codes
     FROM t
     CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(t.col1, ''[^,]+'')) + 1) VX
  ))';
  dbms_output.put_line(astidlist);
  EXECUTE IMMEDIATE x INTO astInclude, astExclude;

  /*IF sSection IN(5,6) THEN
    IF astExclude IS NOT NULL then
      astReturn:=' WHERE NOT exists (SELECT 1 FROM '
      ||sections(sSection).tabname
      ||' cvb WHERE cvb.assignment_type_id '
      ||astExclude
      ||' AND cvb.'||sections(sSection).ixcolumn||' = change_logid)';
    ELSE
      astReturn:=' WHERE 1=1 ';
    END IF;
  ELSE*/
    IF astExclude IS NOT NULL then
      astReturn:=' WHERE NOT exists (SELECT 1 FROM '
      ||sections(sSection).tabname
      ||' cvb WHERE cvb.assignment_type_id '
      ||astExclude
      ||' AND cvb.'||sections(sSection).ixcolumn||' = cva.'||sections(sSection).ixcolumn||')';
      -- add astInclude?
    ELSE
      --astReturn:=' WHERE 1=1 ';
      astReturn:=' WHERE exists (SELECT 1 FROM '
      ||sections(sSection).tabname
      ||' cvb WHERE cvb.assignment_type_id '
      ||astInclude
      ||' AND cvb.'||sections(sSection).ixcolumn||' = cva.'||sections(sSection).ixcolumn||')';
    END IF;
  --END IF;

ELSE
 astReturn:='';
END IF;
RETURN astReturn;
END;
 
 
 
/