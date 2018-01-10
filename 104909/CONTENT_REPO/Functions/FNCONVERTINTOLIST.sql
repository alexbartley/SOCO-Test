CREATE OR REPLACE FUNCTION content_repo."FNCONVERTINTOLIST"
(astidlist IN VARCHAR2, sVerifiedBy IN VARCHAR2, sSection IN NUMBER) RETURN VARCHAR2 IS
/**
  Build join and where statement for a list of verification levels and
  verified by.

  Passed parameters can be '1,2,3,-4...' based on older function where we allowed
  user to exclude verification levels. See 'fnDashInConvert'
*/
 astInclude varchar2(500) DEFAULT NULL;
 astExclude varchar2(500) DEFAULT NULL;
 astReturn varchar2(1000) :='';
 x CLOB;
 TYPE sectionRecord IS RECORD
 (id NUMBER,
  tabname varchar2(32),
  ixcolumn varchar2(32));
 TYPE sectionTable IS TABLE OF sectionRecord; -- INDEX BY BINARY_INTEGER;
 sections sectionTable;
BEGIN
  sections := sectionTable();
  /**
   * Internal temp table -- Table, key column
   * ToDo: put these values in an Oracle lookup table instead of this type table
   */
  sections.extend();
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

  sections.extend();
  sections(10).id := 10;
  sections(10).tabname := 'geo_poly_ref_chg_vlds';
  sections(10).ixcolumn :='geo_poly_ref_chg_log_id';

  sections.extend();
  sections(11).id := 11;
  sections(11).tabname := 'GEO_UNIQUE_AREA_CHG_VLDS';
  sections(11).ixcolumn :='GEO_UNIQUE_AREA_CHG_log_id';
  IF astidlist IS NOT NULL then
    x:='WITH t AS (SELECT '''||astidlist||''' col1 FROM dual)
    SELECT MAX(decode(VXIn,1,astID)), MAX(decode(VXIn,2,astID))
    from
    (SELECT DISTINCT
    VXIn, LISTAGG(codes, '','') WITHIN GROUP (ORDER BY VXIn, codes) over (PARTITION BY VXIn)||'''' astID
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
   EXECUTE IMMEDIATE x INTO astInclude, astExclude;
  END IF;

  IF astInclude IS NOT NULL then
    /*  astReturn:=' WHERE clo.id IN (
     select '||sections(sSection).ixcolumn||' from
     (
     select '||sections(sSection).ixcolumn||',
     LISTAGG(assignment_type_id, '','') WITHIN GROUP (ORDER BY assignment_type_id) rx
     from (
     select distinct assignment_type_id, '||sections(sSection).ixcolumn||' from '
     ||sections(sSection).tabname||
     ' cvb order by cvb.assignment_type_id)
     group by '||sections(sSection).ixcolumn||'
     )
     where rx='''||astInclude||''' and '||sections(sSection).ixcolumn||' = cva.'||sections(sSection).ixcolumn||' )';
    */
  astReturn:=' JOIN (
  select '||sections(sSection).ixcolumn||' from
  (
    select '||sections(sSection).ixcolumn||',
    LISTAGG(assignment_type_id, '','') WITHIN GROUP (ORDER BY assignment_type_id) rx
    from (
      select
      distinct assignment_type_id,
      '||sections(sSection).ixcolumn||'
      from '||sections(sSection).tabname||' cvb';

   -- should be a concat if verified by exists
   -- for now just add it if is set
   -- REGEXP hint: \d = A digit character. POSIX class [[:digit:]].
   if sVerifiedBy is not null and REGEXP_count(sVerifiedBy,'\d')>0 then
    astReturn:=astReturn||' WHERE '||sVerifiedBy||' )';
    DBMS_OUTPUT.Put_Line( astReturn );
   end if;

   -- return WITH verification level set
   astReturn:=astReturn||' order by cvb.assignment_type_id)
              group by '||sections(sSection).ixcolumn||'
              )
              where rx='''||astInclude||''') rx1
              ON (rx1.'||sections(sSection).ixcolumn||' = clo.id) ';

ELSE
 if sVerifiedBy is not null and REGEXP_count(sVerifiedBy,'\d')>0 then
 DBMS_OUTPUT.Put_Line( 'Verified By (fn):'||sVerifiedBy );

  astReturn:=' JOIN (
  select '||sections(sSection).ixcolumn||' from
  (
  select '||sections(sSection).ixcolumn||',
   LISTAGG(assignment_type_id, '','') WITHIN GROUP (ORDER BY assignment_type_id) rx
  from (
  select
  distinct assignment_type_id,
  '||sections(sSection).ixcolumn||'
  from '||sections(sSection).tabname||' cvb';

  astReturn:=astReturn||' WHERE '||sVerifiedBy||' )';

  -- return WITHOUT verification level set
  astReturn:=astReturn||' order by cvb.assignment_type_id)
  group by '||sections(sSection).ixcolumn||'
  )
  ) rx1
  ON (rx1.'||sections(sSection).ixcolumn||' = clo.id) ';

  DBMS_OUTPUT.Put_Line( astReturn );

  else
  astReturn:='';
  end if;
 END IF;

  RETURN astReturn;
END fnConvertINtoList;
 
/