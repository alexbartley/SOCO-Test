CREATE OR REPLACE PACKAGE BODY content_repo."TAXABILITY_COPY" AS
/*
|| Get initial list of commodities available to copy TO
|| - does not consider applicability_type_id
|| - does not consider date ranges
||
|| Dependencies
|| TYPE copy_comm_jta_o
|| TYPE copy_comm_jta_t
|| (Currently only the ID of commodities for the list.
||  the UI will join to result table to get names and other info in pop-up screen)
*/

  function getcopyjtacomm(pProcessId in number) Return copy_comm_jta_t
  is
    l_recs copy_comm_jta_t;
  Begin
    Select copy_comm_jta_o(cc_id)
    bulk collect into l_recs
    from
    (select cc.id cc_id
     from commodities cc
     where cc.product_tree_id = 13
    MINUS
     Select jta.commodity_id from
     juris_tax_applicabilities jta
     join
    (Select distinct jta1.jurisdiction_nkid
     from juris_tax_applicabilities jta1
     join copy_from_tmp cp on (cp.juris_tax_app_id = jta1.id)
     where cp.process_id = pProcessId) JTAExisting
     on (JTAExisting.jurisdiction_nkid = jta.jurisdiction_nkid)
    );
    return l_recs;
  End;

  /*
  || Cleanup by process id.
  || For debug and devlopment purposes, disable this in the processing procedures below
  || if a log is needed.
  ||
  */
  procedure CleanUpProcess(pProcessId in number) is
  begin
   Execute immediate 'Delete From COPY_TAXABILITIES_A where process_copy_id = :pId' Using pProcessId;
   Execute immediate 'Delete from COPY_TAXABILITIES_ITEM where process_id = :pId' Using pProcessId;
   Execute immediate 'Delete from COPY_TO_TMP where process_id = :pId' Using pProcessId;
   Execute immediate 'Delete from COPY_FROM_TMP where process_id = :pId' Using pProcessId;
   Execute immediate 'Delete from Copy_Taxability_Commodities where process_id = :pId' Using pProcessId;
   Commit;
  end;


  PROCEDURE copyItems(pTaxabilityId in clob, oProcessId out number, pEnteredBy in number) is
    -- dep obj: create or replace type nnt_NumberTableType as table of number;
    -- dep obj: create or replace type nnt_VarCharTableType as table of varchar2(32);
    type rzx is table of varchar2(32);
    rz rzx:=rzx();
    reccount number:=0;

    -- Existing taxabilities [no copy to these]
    TYPE tblTaxabilities IS TABLE OF INTEGER;
    vT_Existing_Taxabilities tblTaxabilities := tblTaxabilities();

  begin
      with cmList as (select ''''||replace(pTaxabilityId,',',''''||','||' ''')||'''' colx from dual)
      select to_char(xt.column_value.getClobVal())
      bulk collect into rz
      from xmltable((select colx from cmList)) xt;


  if (rz.count>0) then
    oProcessId := cpy_taxability_seq.nextval();
    FORALL s1 IN rz.first..rz.last
      Insert Into COPY_TAXABILITIES_ITEM(process_id, juris_tax_applicability_id, entered_by) values(oProcessId, rz(s1), pEnteredBy);

  end if;

-- temp limit for test
/* -- crapp-2901 - removed

    if (rz.count>0) then
     oProcessId := cpy_taxability_seq.nextval();
     -- Main list
     FORALL s1 IN rz.first..rz.last
     -- Changes for CRAPP-2822, Included entered_by value
     Insert Into COPY_TAXABILITIES_ITEM(process_id, juris_tax_applicability_id, entered_by) values(oProcessId, rz(s1), pEnteredBy);

        -- Taxabilities with the same values and taxes associated with them [TAX_APPLICABILITY_TAXES] if any
        -- TODO: add next_rid = NULL
        Select distinct aq2.jurisdiction_nkid
        BULK COLLECT INTO vT_Existing_Taxabilities
        from
        (
          Select jta.id, jta.jurisdiction_nkid, jta.CALCULATION_METHOD_ID, jta.BASIS_PERCENT, jta.RECOVERABLE_PERCENT, jta.RECOVERABLE_AMOUNT,
          jta.START_DATE, jta.END_DATE, jta.ALL_TAXES_APPLY, jta.APPLICABILITY_TYPE_ID, -- jta.ALLOCATED_CHARGES,
          jta.UNIT_OF_MEASURE,
          jta.DEFAULT_TAXABILITY, jta.PRODUCT_TREE_ID, jta.COMMODITY_ID, jta.TAX_TYPE, --jta.RELATED_CHARGE,
          jta.IS_LOCAL,
          jta.no_tax, jta.exempt, xc1.reference_code, nvl(atr.attribute_id,0) attrib
          From juris_tax_applicabilities jta
          Left Join (Select jtx.id, jtx.juris_tax_applicability_id, jtx.start_date,  jti.reference_code
                     from tax_applicability_taxes jtx
                     join juris_tax_impositions jti on (jti.id = jtx.juris_tax_imposition_id)) XC1
               On (XC1.juris_tax_applicability_id = jta.id)
          left join juris_tax_app_attributes atr on (atr.juris_tax_applicability_id = jta.id)
        JOIN COPY_TAXABILITIES_ITEM fa on (jta.id = fa.juris_tax_applicability_id and process_id = oProcessId)
        ) AQ1
       JOIN
       (Select jta.id, jta.jurisdiction_nkid, jta.CALCULATION_METHOD_ID, jta.BASIS_PERCENT, jta.RECOVERABLE_PERCENT, jta.RECOVERABLE_AMOUNT,
       jta.START_DATE, jta.END_DATE, jta.ALL_TAXES_APPLY, jta.APPLICABILITY_TYPE_ID, -- jta.ALLOCATED_CHARGES,
       jta.UNIT_OF_MEASURE,
       jta.DEFAULT_TAXABILITY, jta.PRODUCT_TREE_ID, jta.COMMODITY_ID, jta.TAX_TYPE, -- jta.RELATED_CHARGE,
       jta.IS_LOCAL,
       jta.no_tax, jta.exempt, xc1.reference_code, nvl(atr.attribute_id,0) attrib
       From juris_tax_applicabilities jta
       Left Join (Select jtx.id, jtx.juris_tax_applicability_id, jtx.start_date, jti.reference_code
                from tax_applicability_taxes jtx
                join juris_tax_impositions jti on (jti.id = jtx.juris_tax_imposition_id)) XC1
       On (XC1.juris_tax_applicability_id = jta.id)
       left join juris_tax_app_attributes atr on (atr.juris_tax_applicability_id = jta.id)
       JOIN COPY_TAXABILITIES_ITEM fa on (jta.id != fa.juris_tax_applicability_id and process_id = oProcessId)
       ) AQ2
       -- (some are already NOT NULL fields, new fields just used in data load are not used)
       ON (      aq2.jurisdiction_nkid != aq1.jurisdiction_nkid AND     -- crapp-2833
                 aq2.calculation_method_id = aq1.calculation_method_id and
                 nvl(aq2.basis_percent,0) = nvl(aq1.basis_percent,0) and
                 nvl(aq2.recoverable_percent,0) = nvl(aq1.recoverable_percent,0) and
                 nvl(aq2.recoverable_amount,0) =nvl(aq1.recoverable_amount,0) and
                 (aq2.end_date IS NULL OR aq2.end_date >= aq1.start_date)
                 AND aq2.start_date <= aq1.start_date
                 and nvl(aq2.all_taxes_apply,0) = nvl(aq1.all_taxes_apply,0) and
                 aq2.applicability_type_id = aq1.applicability_type_id and
                 --nvl(aq2.allocated_charges,0) = nvl(aq1.allocated_charges,0) and
                 nvl(aq2.unit_of_measure,' ') = nvl(aq1.unit_of_measure,' ') and
                 nvl(aq2.default_taxability,'N') = nvl(aq1.default_taxability,'N') and
                 nvl(aq2.product_tree_id,0) = nvl(aq1.product_tree_id,0) and
                 nvl(aq2.commodity_id,0) = nvl(aq1.commodity_id,0) and
                 nvl(aq2.attrib,0) = nvl(aq1.attrib,0) and
--                 nvl(aq2.tax_type,' ') = nvl(aq1.tax_type,' ') and
--                 nvl(aq2.related_charge,' ') = nvl(aq1.related_charge,' ') and
--                 nvl(aq2.is_local,' ') = nvl(aq1.is_local,' ') and
--                 nvl(aq2.exempt,'N') = nvl(aq1.exempt,'N') and
--                 nvl(aq2.no_tax,'N') = nvl(aq1.no_tax,'N') and
                 nvl(aq1.reference_code,'xx') = nvl(aq2.reference_code,'xx')
                 );


        -- For now this is "where ALL meet the criteria"
        -- Records that are the same = no copy allowed
        FORALL i IN vT_Existing_Taxabilities.first..vT_Existing_Taxabilities.last
        Insert Into COPY_TAXABILITIES_A(jurisdiction_nkid, process_copy_id, stepStatus, objtype, entered_by)
             values(vT_Existing_Taxabilities(i), oProcessId, 0, 'I', pEnteredBy);

       -- Keep what taxability to copy
       Commit;
    else
      oProcessId := 0; -- Nothing to do, no list of juris_tax_applicabilities
    end if;
*/

  end copyItems;

  PROCEDURE processCopy(pProcessId in number, selectedJuris in clob, errMsg in out varchar2) is
    type rzx is table of varchar2(32);
    rz rzx:=rzx();
  begin
    with cmList as (select ''''||replace(selectedJuris,',',''''||','||' ''')||'''' colx from dual)
    select to_char(xt.column_value.getClobVal())
    bulk collect into rz
    from xmltable((select colx from cmList)) xt;

    errMsg:='Not ready yet';
  end processCopy;

  /*
  || OVERLOADED :: this is the one you are looking for
  ||
  */
  PROCEDURE processCopy(pProcessId in number, defStartDate in date, selectedJuris in clob, errMsg in out varchar2, defEndDate in date default null) is
    type rzx is table of varchar2(32);
    rz rzx:=rzx();
    errMsg_Out varchar2(100); -- concat(msg)
    n_Entered_By Number;
  begin
    with cmList as (select ''''||replace(selectedJuris,',',''''||','||' ''')||'''' colx from dual)
    select to_char(xt.column_value.getClobVal())
    bulk collect into rz
    from xmltable((select colx from cmList)) xt;

    -- Previous solution was based on join with this table - therefor insert of entered by from the beginning
    -- Changes for CRAPP-2822
    Select distinct entered_by
      into n_Entered_By
      from copy_taxabilities_item
     where process_id = pProcessId;

    --<> Loop by selected Jurisdictions selected to copy to
    FOR lg in rz.first..rz.last LOOP

      /*Insert Into copy_taxabilities_a(jurisdiction_nkid, process_copy_id, stepstatus, objtype)
      Values(rz(lg), pProcessId, 3, 'C');*/

      FOR insNewTx in
      (Select distinct n_Entered_By, juris_tax_app_id
       from copy_from_tmp
       where process_id = pProcessId)
      LOOP

        -- Changes for CRAPP-2721
        -- Changes for CRAPP-2823
        TAXABILITY.generate_xml(jta_id_i=> insNewTx.juris_tax_app_id, juris_nkid=>rz(lg), entered_by_i=> n_Entered_By,
                                start_date_i=> nvl(defStartDate, ''),
                                end_date_i => nvl(defEndDate, '')
                                );

      END LOOP;
    End loop;

    errMsg:='';
    CleanUpProcess(pProcessId);

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
                errMsg:='Could not copy selected taxabilities.';
            errlogger.report_and_stop(SQLCODE,SQLERRM);

  end processCopy;


  PROCEDURE getJurisdictions(pProcessId in number, ojuris_list in out clob) is
    nOutObject Varchar2(1):='P'; -- I is in data, P is the final list of jurisdictions, C is copied
    dmList clob:=empty_clob();
    n1 number;
    pProcess_copy_id number:=pProcessId;
    pRefCode varchar2(8):='';

    tmpCount number;   -- possible valid JTA/JTI to copy to.
    l_validTax number; -- count of found tax
    l_jtaCount number; -- count of # of commodities in JTA for specified Tax
    r number:=0;
    nc number:=0; -- length of clob
    l_taxable NUMBER := 0;  -- crapp-2901

  type r_applic is record
  (id number,
   start_date date,
   end_date date,
   applicability_type_id number,
   commodity_id number);

  TYPE tt_applic IS TABLE OF r_applic;
  t_applic tt_applic;
  l_exists number:=0;

  begin

    dbms_output.put_line('Step 11: '||SYSTIMESTAMP);
    Select count(1) into l_exists from copy_to_tmp where process_id = pProcessId;
    dbms_output.put_line('Step 12: '||SYSTIMESTAMP);

    if l_exists < 1 then
        dbms_output.put_line('Step 13: '||SYSTIMESTAMP);
    -- Copy From Applicability Type 1
       Insert into copy_from_tmp
       (PROCESS_ID, TXT_START_DATE, TXT_END_DATE, REFERENCE_CODE, JTI_START_DATE, JTI_END_DATE,
        JURIS_TAX_APP_ID, COMMODITY_ID, commodity_nkid, APPLICABILITY_TYPE_ID)
       (Select
         pProcess_copy_id
       , txt.start_date
       , txt.end_date
       , jti.reference_code
       , jti.start_date
       , jti.end_date
       , jtl.id
       , jtl.commodity_id
       , jtl.commodity_nkid
       , jtl.applicability_type_id
        from tax_applicability_taxes txt
        join juris_tax_impositions jti on (jti.id = txt.juris_tax_imposition_id)
        JOIN COPY_JTA_ITEMS_V jtl on (jtl.id = txt.juris_tax_applicability_id
        and jtl.process_id = pProcess_copy_id)
        where jtl.applicability_type_id = 1
       );
        dbms_output.put_line('Step 14: '||SYSTIMESTAMP);
    -- Copy From Applicability Type 2...
       Insert into copy_from_tmp
       (PROCESS_ID, JTI_START_DATE, JTI_END_DATE, JURIS_TAX_APP_ID, COMMODITY_ID, commodity_nkid, APPLICABILITY_TYPE_ID)
       (Select pProcess_copy_id, start_date, end_date, id, commodity_id, commodity_nkid, applicability_type_id
        From COPY_JTA_ITEMS_V where process_id = pProcess_copy_id AND applicability_type_id<>1);
        dbms_output.put_line('Step 15: '||SYSTIMESTAMP);
    Insert Into copy_to_tmp(process_id, juris_id, copyfrom)
    (select distinct pProcess_copy_id process_id, ax.id juris_id, 0
     from
    (
       Select id
       from
       (
       Select j.id, j.nkid, j.official_name
         From jurisdictions j
         where next_rid is null
         MINUS
         Select distinct j.id, j.nkid, j.official_name
         From jurisdictions j
         Join COPY_TAXABILITIES_A cr2 on (cr2.jurisdiction_nkid = j.nkid
         And next_rid is null)
         where cr2.process_copy_id = pProcess_copy_id
         and objtype='I'
       ) A
       where exists (select 1 from
       juris_tax_impositions jt2
       where jt2.jurisdiction_id = A.id
       and reference_code in (select reference_code
       from copy_from_tmp where process_id = pProcess_copy_id)
       )
       minus
       Select distinct b.jurisdiction_id from juris_tax_impositions b
       where exists (select 1 from
       juris_tax_impositions a
       join tax_applicability_taxes txt on (txt.juris_tax_imposition_id = a.id)
       join COPY_JTA_ITEMS_V jtl on (jtl.id = txt.juris_tax_applicability_id and jtl.process_id=pProcess_copy_id)
       where a.reference_code = b.reference_code
       and b.start_date >= a.start_date
       and a.end_date is not null)
      ) ax
      );

    dbms_output.put_line('Step 17: '||SYSTIMESTAMP);
      DBMS_OUTPUT.Put_Line( '2 or 3');

    /*  -- CRAPP-2894 - replaced with query after commented section
    FOR cur2 in (
     select jta.id, jta.start_date, jta.end_date, jta.commodity_id, jta.jurisdiction_id, jta.applicability_type_id
     from juris_tax_applicabilities jta
     join copy_taxabilities_item itm on (jta.id = itm.juris_tax_applicability_id)
     where itm.process_id = pProcess_copy_id and jta.applicability_type_id > 1
   )
    LOOP
        dbms_output.put_line('Step 18: '||SYSTIMESTAMP);
     Insert into copy_to_tmp(process_id, juris_id, copyfrom)
     (
     Select distinct pProcess_copy_id, id, cur2.id from
      jurisdictions
      where next_rid is null and end_date is null
      MINUS
         Select distinct j.id, j.nkid, cur2.id
         From jurisdictions j
         Join COPY_TAXABILITIES_A cr2 on (cr2.jurisdiction_nkid = j.nkid
         And next_rid is null)
         where cr2.process_copy_id = pProcess_copy_id
         and objtype='I'
      MINUS
      Select pProcess_copy_id, a.jurisdiction_id, cur2.id
      --, a.id, a.commodity_id, a.product_tree_id, a.applicability_type_id
      from
      juris_tax_applicabilities a
      where exists
     (select 1 from
      juris_tax_applicabilities b
      join copy_from_tmp ttt on (ttt.juris_tax_app_id = b.id)
      where a.applicability_type_id = b.applicability_type_id
      and nvl(a.commodity_id,0) = nvl(b.commodity_id,0)
      and nvl(a.all_taxes_apply,0) = nvl(b.all_taxes_apply,0)
      --and nvl(a.end_date,'01-JAN-2096') = nvl(b.end_date,'01-JAN-2096')   -- crapp-2833
      and ttt.process_id = pProcess_copy_id
      )
      and a.next_rid is null
      );
      dbms_output.put_line('Step 19: '||SYSTIMESTAMP);
    END LOOP;
    */
    COMMIT;
    -- CRAPP-2894 --
    dbms_output.put_line('Step 18: '||SYSTIMESTAMP);

    -- crapp-2901 - determine we have any taxable records, if so, use these to copy to, else pull all Jurisdictions
    SELECT COUNT(*) INTO l_taxable
    FROM
     (
      SELECT DISTINCT pProcess_copy_id, j.id, j.official_name  -- Find all Jurisdictions with Taxes that match the reference code and date range of those that are attempting to be copied
      FROM jurisdictions j
           JOIN juris_tax_impositions tib ON (tib.jurisdiction_nkid = j.nkid and tib.next_rid is null)
           JOIN tax_outlines tou ON (tou.juris_tax_imposition_nkid = tib.nkid)
      WHERE tib.reference_code IN (SELECT DISTINCT ttt.reference_code
                                   FROM copy_from_tmp ttt
                                        JOIN juris_tax_applicabilities a on (ttt.juris_tax_app_id = a.id)
                                   WHERE ttt.process_id = pProcess_copy_id
                                  )
        -- and tou.start_date <= '02-jan-2000'  --Requires that a tax exists that is active for the specified start date of the copy functionality, but if they change the start date we canít have this in here
        -- and nvl(tou.end_date,'31-dec-2099') >= '02-jan-2000'  -- requires that a tax exists that is active for the specified start date of the copy functionality, but if the user can modify the start date we canít have this
     );

    IF l_taxable > 0 THEN
        -- Find all Jurisdictions with Taxes that match the reference code and date range of those that are attempting to be copied
        INSERT INTO copy_to_tmp(process_id, juris_id, copyfrom)
         (
          SELECT DISTINCT pProcess_copy_id, j.id, j.official_name
          FROM jurisdictions j
               JOIN juris_tax_impositions tib ON (tib.jurisdiction_nkid = j.nkid and tib.next_rid is null)
               JOIN tax_outlines tou ON (tou.juris_tax_imposition_nkid = tib.nkid)
          WHERE tib.reference_code IN (SELECT DISTINCT ttt.reference_code
                                       FROM copy_from_tmp ttt
                                            JOIN juris_tax_applicabilities a on (ttt.juris_tax_app_id = a.id)
                                       WHERE ttt.process_id = pProcess_copy_id
                                      )
            -- and tou.start_date <= '02-jan-2000'  --Requires that a tax exists that is active for the specified start date of the copy functionality, but if they change the start date we canít have this in here
            -- and nvl(tou.end_date,'31-dec-2099') >= '02-jan-2000'  -- requires that a tax exists that is active for the specified start date of the copy functionality, but if the user can modify the start date we canít have this
         );
    ELSE -- Exempt, return ALL jurisdictions
        INSERT INTO copy_to_tmp(process_id, juris_id, copyfrom)
         (
          SELECT DISTINCT pProcess_copy_id, j.id, j.official_name
          FROM jurisdictions j
          WHERE EXISTS (SELECT 1
                        FROM   copy_from_tmp
                        WHERE  process_id = pProcess_copy_id
                              AND applicability_type_id <> 1
                        )
            AND next_rid IS NULL
         );
    END IF;
    COMMIT;


    -- Changes for CRAPP-2823
    dbms_output.put_line('Step 19: '||SYSTIMESTAMP);
    Insert into COPY_TAXABILITIES_A (jurisdiction_nkid, process_copy_id, objtype, stepStatus)
     (
     SELECT distinct j.nkid, pProcessId, 'P', 4
     FROM   copy_to_tmp t1
     join jurisdictions j on ( t1.juris_id = j.id )
     WHERE  process_id = pProcessId
     /* -- crapp-2901 - removed
     AND EXISTS (
     SELECT 1
     FROM   copy_to_tmp t2
     WHERE  process_id = pProcessId
     AND t2.copyfrom =  t1.copyfrom
     AND t2.juris_id <> t1.juris_id
     )
     */
     );
     COMMIT;

  End If; -- l_exist

   -- New: don't pass back the list of jurisdictions.
   -- UI will now query COPY_TAXABILITIES_A table and join back to Jurisdiction_Search_V
   -- xml OUT removed
 end;


 /*
 || Copy taxabilities based on commodity
 || is there a list of juris nkid's?
 || is there a list of commodities or one?
 || commodities in each jurisdiction (taxabilities) that are valid to copy to
 */
 PROCEDURE copyCommodity(pTaxabilityId in clob, oProcessId out number, pEnteredBy in number) is
    -- dep obj: create or replace type nnt_NumberTableType as table of number;
    -- dep obj: create or replace type nnt_VarCharTableType as table of varchar2(32);
    type rzx is table of varchar2(32);
    rz rzx:=rzx();
    reccount number:=0;

    -- Existing taxabilities [no copy to these]
    TYPE tblTaxabilities IS TABLE OF INTEGER;
    vT_Existing_Taxabilities tblTaxabilities := tblTaxabilities();

    -- JTA record
    jta_record juris_tax_applicabilities%ROWTYPE;
    l_commodity Number;

 BEGIN
   With cmList as (select ''''||replace(pTaxabilityId,',',''''||','||' ''')||'''' colx from dual)
   Select to_char(xt.column_value.getClobVal())
   Bulk collect into rz
   From xmltable((select colx from cmList)) xt;

   if (rz.count>0) then
     oProcessId := cpy_taxability_seq.nextval();

     -- Commodity (can use jta_record.commodity_id throughout)
     l_commodity := jta_record.commodity_id;

     -- list of taxability grid records to copy
     FORALL s1 IN rz.first..rz.last
     -- Changes for CRAPP-2822, Included entered_by column
     Insert Into COPY_TAXABILITIES_ITEM(process_id, juris_tax_applicability_id, entered_by) values(oProcessId, rz(s1), pEnteredBy);

     -- For copy taxability we don't have the jurisdiction nkid
     -- it will be picked up from COPY_TAXABILITIES_ITEM based on the applicability id
     -- (Dev Note: should probably be its own table for commodities only)
     Insert Into COPY_TAXABILITIES_A(jurisdiction_nkid, process_copy_id, stepStatus, objtype, entered_by)
             values(1, oProcessId, 0, 'I', pEnteredBy);

     Commit; -- nnt: seems wrong since call from PHP is suppose to be auto commit.
    else
      oProcessId := 0; -- Nothing to do, no list of juris_tax_applicabilities
    end if;

 END copyCommodity;


 PROCEDURE getCommodities(pProcessId in number)
 is
   type r_applic is record
   (id number,
   start_date date,
   end_date date,
   applicability_type_id number,
   commodity_id number);

   TYPE tt_applic IS TABLE OF r_applic;
   t_applic tt_applic;

   l_exists number:=0;
   l_processId number := pProcessId;
 begin
   Select count(1) into l_exists from copy_to_tmp where process_id = pProcessId;

   if l_exists = 0 then

       -- Store selected grid rows (using commodity_id to filter later)
      Insert into copy_from_tmp
      (PROCESS_ID, TXT_START_DATE, TXT_END_DATE, REFERENCE_CODE, JTI_START_DATE, JTI_END_DATE,
       JURIS_TAX_APP_ID, COMMODITY_ID, commodity_nkid, APPLICABILITY_TYPE_ID)
      (Select
        l_processId
      , txt.start_date
      , txt.end_date
      , jti.reference_code
      , jti.start_date
      , jti.end_date
      , jtl.id
      , jtl.commodity_id
      , jtl.commodity_nkid
      , jtl.applicability_type_id
       from
       COPY_JTA_ITEMS_V jtl
       left join tax_applicability_taxes txt on (txt.juris_tax_applicability_id = jtl.id)
       left join juris_tax_impositions jti on (jti.id = txt.juris_tax_imposition_id)
       where jtl.process_id = l_processId
     );

     --> data insert: commodities available joined with commodity table to get name
     --               copy_selected = 0
     Insert Into Copy_Taxability_Commodities(process_id, commodity_id, copy_selected, commodity_nkid)
     (Select l_processId, p.id, 0, cc.nkid
      From Commodities cc
      Join table( getcopyjtacomm(pprocessid=> l_processId)) p on (p.id = cc.id));
     Commit;
   end if;

 end;


 PROCEDURE processCopyComm(pProcessId in number, defStartDate in date, selectedComm in clob, errMsg in out varchar2, defEndDate in date default null)
 is
    rz VARCHAR2_32_T:=VARCHAR2_32_T();  -- global
    errMsg_Out varchar2(100); -- concat(msg)
    n_Entered_By Number;
  begin
    with cmList as (select ''''||replace(selectedComm,',',''''||','||' ''')||'''' colx from dual)
    select to_char(xt.column_value.getClobVal())
    bulk collect into rz
    from xmltable((select colx from cmList)) xt;

    -- Previous solution was based on join with this table - therefor insert of entered by from the beginning
    -- Changes for CRAPP-2822
    Select distinct entered_by
      into n_Entered_By
      from copy_taxabilities_item
     where process_id = pProcessId;

    -- Loop through the selected taxability source records selected in the grid,
    -- pass the collection of commodities to copy to
      FOR insNewTx in
      (Select distinct n_Entered_By, juris_tax_app_id
       from copy_from_tmp
       where process_id = pProcessId)
      LOOP

-- Look at what xml we get here....
DBMS_OUTPUT.Put_Line( 'TAXABILITY.generate_xml( jta_id_i=> '||insNewTx.juris_tax_app_id||', juris_id=> null
                               , entered_by_i=>'|| n_Entered_By ||'
                               , start_date_i=> null
                               , end_date_i=> null
                               , local_flag=> 0
                               , commodity_list=>'||rz(1));

        -- Changes for CRAPP-2721
        TAXABILITY.generate_xml( jta_id_i=> insNewTx.juris_tax_app_id
                               , juris_nkid=> null  -- Changes for CRAPP-2823
                               , entered_by_i=> n_Entered_By
                               , start_date_i=> nvl(defStartDate, '')
                               , end_date_i=> nvl(defEndDate, '')
                               , local_flag=> 0
                               , commodity_list=>rz);

      END LOOP;

    errMsg:='';

    CleanUpProcess(pProcessId);

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
                errMsg:='Could not copy selected taxabilities.';
            errlogger.report_and_stop(SQLCODE,SQLERRM);
 END processCopyComm;

End Taxability_Copy;
/