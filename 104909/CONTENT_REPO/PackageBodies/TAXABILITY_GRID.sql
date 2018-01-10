CREATE OR REPLACE PACKAGE BODY content_repo."TAXABILITY_GRID" AS
/*
||
||
||
*/
  display_implicit number := null;
  c_jta_nkid       juris_tax_applicabilities.nkid%type := null;
  c_jti_nkid       juris_tax_impositions.nkid%type := null;
  c_processid      number := null;
  c_commodity_nkid commodities.nkid%type := null;

  start_time  number;
  end_time   number;

  -- Functions
  Function getJurisTaxApplicability(pJurisdictionNkid in number) RETURN jta_tab PIPELINED
  AS
    outp juris_tax_applicabilities%ROWTYPE;
  BEGIN
    FOR outp IN (SELECT * FROM juris_tax_applicabilities where jurisdiction_nkid = pJurisdictionNkid) LOOP
      PIPE ROW(outp);
    END LOOP;
    RETURN;
  END getJurisTaxApplicability;


    function setImpExp(pShow in number) return number is
    begin
      display_implicit := pShow;
      return(pShow);
    end setImpExp;

    function setJTANkid(pJTANkid in number) return number is
    begin
      c_jta_nkid := pJTANkid;
      return(pJTANkid);
    end setJTANkid;

  function setProcessId(pProcessId in number) return number is
  begin
     c_processid := pProcessId;
     return(pProcessId);
  end setProcessId;


Function FN_IMPLEXPL_XOUT(in_processId in number default null) return impl_expl_xtable pipelined is
 cursor FullList(processId number) is
 Select
 distinct
 ccc.product_tree_id,
 ccc.commodity_id,
 ccc.commtree,
 ccc.c_id,
 cc.nkid commodity_nkid,
 cc.rid commodity_rid,
 cc.commodity_code,
 cc.h_code,
 ccc.ccc_level,
 lvlx.rlvl, lvlx.process_id, lvlx.r_level,
 lvlx.impl,
 lvlx.juris_tax_applicability_id,
 jta.reference_code
 ,lvlx.source_h_code  -- crapp-2908
 from
 (
Select 3 rlvl, lvl.* From impl_process_levels lvl
Where r_level=3
and process_id=processId
and juris_tax_applicability_id is not null
UNION ALL
Select 2 rlvl, lvl.* From impl_process_levels lvl
Where r_level=2
and process_id=processId
and juris_tax_applicability_id is not null
UNION ALL
Select 1 rlvl, lvl.* From impl_process_levels lvl
Where r_level=1
and process_id=processId
and juris_tax_applicability_id is not null
) LVLX
join commodities_pctree_build ccc on (ccc.commodity_id = lvlx.commodity_id)
join commodities cc on (cc.id = ccc.commodity_id and cc.next_rid is null)
join juris_tax_applicabilities jta on (jta.id = lvlx.juris_tax_applicability_id)
order by ccc.c_id, lvlx.rlvl, lvlx.impl;

SUBTYPE T_record IS FullList%rowtype;
TYPE tbl_levels IS TABLE OF FullList%ROWTYPE;
l_table tbl_levels;

--r_rec impl_expl_xview;
r_rec impl_expl_xview;

l_processId number;
--in_processId number := in_processId;
-- cursor by record from impl table : use jta_id and commodity_id
begin
  l_processId := nvl(in_processId, c_processid);
--DBMS_OUTPUT.Put_Line( l_processId );

 OPEN FullList(l_processId);
 FETCH FullList BULK COLLECT INTO l_table;
 CLOSE FullList;
 --DBMS_OUTPUT.Put_Line( l_table.count );
 if l_table.count >0 then
  FOR ii in l_table.first..l_table.last loop
  --DBMS_OUTPUT.Put_Line( l_table(ii).JURIS_TAX_APPLICABILITY_ID );

     For xx in (Select jta.* from taxability_search_v jta
                where jta.id = l_table(ii).JURIS_TAX_APPLICABILITY_ID)
     LOOP
     r_rec := new impl_expl_xview
           (l_table(ii).IMPL
           ,l_table(ii).RLVL
           ,l_table(ii).c_id
           ,xx.id
           ,xx.reference_code
           ,xx.calculation_method_id
           ,xx.basis_percent
           ,xx.recoverable_percent
           ,xx.recoverable_amount
           ,xx.start_date
           ,xx.end_date
           ,xx.entered_by
           ,xx.entered_date
           ,xx.status
           ,xx.status_modified_date
           ,xx.rid
           ,xx.nkid
           ,xx.next_rid
           ,xx.jurisdiction_id
           ,xx.jurisdiction_nkid
           ,xx.jurisdiction_rid
           ,xx.jurisdiction_official_name
           ,xx.all_taxes_apply
           ,xx.applicability_type_id
           ,xx.charge_type_id
           ,xx.unit_of_measure
           ,xx.ref_rule_order
           ,xx.default_taxability
           ,xx.product_tree_id
           ,l_table(ii).commodity_id
           ,l_table(ii).commodity_nkid
           ,l_table(ii).commodity_rid
           ,l_table(ii).commtree
           ,l_table(ii).commodity_code
/*           ,xx.commodity_id
           ,xx.commodity_nkid
           ,xx.commodity_rid
           ,xx.commodity_name
           ,xx.commodity_code
*/
           --,xx.h_code
           ,l_table(ii).h_code
           ,xx.conditions
           ,xx.tax_type
           ,xx.tax_applicabilities
           ,xx.verification
           ,xx.change_count
--           ,xx.commodity_tree_id
           ,l_table(ii).product_tree_id
           ,xx.is_local
           ,xx.legal_statement
           ,xx.canbedeleted
           ,xx.maxstatus
           ,xx.tag_collection
           ,xx.condition_collection
           ,xx.applicable_tax_collection

           -- 1 => Explicit Taxability in this Jurisdiction
           -- 2 => Implied Taxability inherited from a Parent Taxability in this Jurisdiction
           -- 3 => Default Taxability in this Jurisdiction
           -- 4 => Implied Taxability inherited from a Parent Taxability in the Parent Jurisdiction
           -- 5 => Default Taxability from the Parent Jurisdiction

           , CASE WHEN l_table(ii).IMPL = 0 AND l_table(ii).RLVL = 3 THEN 1 -- AND xx.is_local = 0
                  WHEN l_table(ii).IMPL = 1 AND l_table(ii).RLVL = 3 AND xx.default_taxability = 0 THEN 2 -- 07/07/16 - added default_taxability
                  WHEN xx.default_taxability = 1 AND xx.is_local = 0 THEN 3 -- 07/07/16 - added default_taxability, removed l_table(ii).IMPL = 1 AND l_table(ii).RLVL = 1
                  WHEN l_table(ii).RLVL = 2 AND xx.is_local = 1 THEN 4      -- added is_local - 06/28/16
                  WHEN xx.default_taxability = 1 AND xx.is_local = 1 THEN 5 -- 07/07/16 - added default_taxability, removed l_table(ii).IMPL = 1 AND l_table(ii).RLVL = 1
                  ELSE 9
             END -- crapp-2754 - override_order
           /*
           -- original --
           , CASE WHEN l_table(ii).IMPL = 0 AND l_table(ii).RLVL = 3 THEN 1 -- AND xx.is_local = 0   -- Explicit Taxability in this Jurisdiction
                  WHEN l_table(ii).IMPL = 1 AND l_table(ii).RLVL = 3 THEN 2 -- AND xx.is_local = 0   -- Implied Taxability inherited from a Parent Taxability in this Jurisdiction
                  WHEN l_table(ii).IMPL = 1 AND l_table(ii).RLVL = 1 AND xx.is_local = 0 THEN 3      -- Default Taxability in this Jurisdiction
                  WHEN l_table(ii).RLVL = 2 AND xx.is_local = 1 THEN 4  -- Added is_local - 06/28/16 -- Implied Taxability inherited from a Parent Taxability in the Parent Jurisdiction
                  WHEN l_table(ii).IMPL = 1 AND l_table(ii).RLVL = 1 AND xx.is_local = 1 THEN 5      -- Default Taxability from the Parent Jurisdiction
                  ELSE 9
             END -- crapp-2754 - override_order
           */
           ,xx.verifylist   -- crapp-2801
           ,l_table(ii).source_h_code
           );
     pipe row (r_rec);
  End loop;  -- Taxabilities
 End Loop; -- Level

 end if; -- l_table.count

End FN_IMPLEXPL_XOUT;

    function taxability_grid_t(pJurisdictionNkid in number default null,
                               pImpExpl in number default null) return T_TAXABILITY_TAB pipelined
    is

      -- TAXABILITY_SEARCH_V
      -- Stays the same with the exception of requesting data by where statement;
      /*
         Example:
         .. where taxability_grid.setImpExp(1) = 1
            and taxability_grid.setJTANkid(31651) = 31651

      */
      Cursor taxability_crs_expl(cpJurisdictionNkid number) is
      Select
      0 IMPLICIT,            -- no, all of them are explicit
      3 IMPLEXPL_AUTH_LEVEL, -- only one jurisdiction at the time in the grid
      0 IMPL_CM_ORDER,       -- no specific order as default
       ID, REFERENCE_CODE, CALCULATION_METHOD_ID,
       BASIS_PERCENT, RECOVERABLE_PERCENT,
       RECOVERABLE_AMOUNT, START_DATE, END_DATE,
       ENTERED_BY, ENTERED_DATE, STATUS,
       STATUS_MODIFIED_DATE,
       RID, NKID, NEXT_RID,
       JURISDICTION_ID,
       JURISDICTION_NKID,
       JURISDICTION_RID,
       JURISDICTION_OFFICIAL_NAME,
       ALL_TAXES_APPLY,
       APPLICABILITY_TYPE_ID,
       CHARGE_TYPE_ID,
       UNIT_OF_MEASURE,
       REF_RULE_ORDER,
       DEFAULT_TAXABILITY,
       PRODUCT_TREE_ID,
       COMMODITY_ID,
       COMMODITY_NKID,
       COMMODITY_RID, COMMODITY_NAME, COMMODITY_CODE,
       H_CODE, CONDITIONS,
       TAX_TYPE, TAX_APPLICABILITIES, VERIFICATION,
       CHANGE_COUNT, COMMODITY_TREE_ID, IS_LOCAL,
       LEGAL_STATEMENT, CANBEDELETED, MAXSTATUS
      From taxability_search_v Where jurisdiction_nkid = cpJurisdictionNkid;

      /*
      || Do you want to see implicit only or implicit and explicit at the same time?
      || Do you want the explicit ones to be the priority in sorting the result set?
      || Do you want the default taxabilities to be applied to all commodities in the tree
      ||   regardless of tax type?
      || (Since commodities do NOT have anything that says it is a taxable or exempt product,
      ||  except by part of a name, all are being used)
      ||
      || Do you want the Excplicit records (when looking at Implicit) to be applied to
      || commodities in the same tree or should the default taxability be shown?
      */
      Cursor taxability_crs_impl(cpJurisdictionNkid number) is
      Select
       1 IMPLICIT,
       3 IMPLEXPL_AUTH_LEVEL,
       0 IMPL_CM_ORDER,
       ID, REFERENCE_CODE, CALCULATION_METHOD_ID,
       BASIS_PERCENT, RECOVERABLE_PERCENT,
       RECOVERABLE_AMOUNT, START_DATE, END_DATE,
       ENTERED_BY, ENTERED_DATE, STATUS,
       STATUS_MODIFIED_DATE,
       RID, NKID, NEXT_RID,
       JURISDICTION_ID,
       JURISDICTION_NKID,
       JURISDICTION_RID,
       JURISDICTION_OFFICIAL_NAME,
       ALL_TAXES_APPLY,
       APPLICABILITY_TYPE_ID,
       CHARGE_TYPE_ID,
       UNIT_OF_MEASURE,
       REF_RULE_ORDER,
       DEFAULT_TAXABILITY,
       PRODUCT_TREE_ID,
       COMMODITY_ID,
       COMMODITY_NKID,
       COMMODITY_RID, COMMODITY_NAME, COMMODITY_CODE,
       H_CODE, CONDITIONS,
       TAX_TYPE, TAX_APPLICABILITIES, VERIFICATION,
       CHANGE_COUNT, COMMODITY_TREE_ID, IS_LOCAL,
       LEGAL_STATEMENT, CANBEDELETED, MAXSTATUS
       from
      (
        Select
        Case When (XSETA.commodity_id is null and XSETA.start_date is null) then 1
        When (XSETA.commodity_id is not null) then 0
        When (XSETA.start_date is not null and XSETA.commodity_id is null) then 0 else 0 end IMPLICIT,
        x1.*, xseta.* from
      (
      SELECT distinct rownum cm_row
      , LEVEL                cm_level
      , Level                cm_h_code_level
      --, sys_connect_by_path(ccc.name, '/') AS cpath
      --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
      , CommTree             cm_commtree
      , connect_by_root child_h_code as cm_ppc
      --, CONNECT_BY_ISLEAF ppca
      , ccc.parent_h_code    cm_parent_h_code
      , ccc.CHILD_h_code     cm_child_h_code
      , ccc.commodity_id     cm_commodity_id
      , ccc.nkid             cm_nkid
      , ccc.commodity_code   cm_commodity_code
      , ccc.name             cm_name
      , ccc.product_tree_id  cm_product_tree_id
      FROM commodities_pctree_build ccc
      Start with ccc.parent_h_code ='000.'
      CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
      ORDER SIBLINGS BY ccc.CHILD_h_code
      ) X1
        --
        -- This is TAXABILITY_SEARCH_V
        --
        LEFT JOIN TAXABILITY_SEARCH_V XSETA
        PARTITION BY (xseta.jurisdiction_nkid)
        ON (XSETA.commodity_id = X1.cm_commodity_id or
        case when XSETA.product_tree_id is not null and XSETA.commodity_id is null then XSETA.product_tree_id end = X1.cm_product_tree_id)
        where xseta.jurisdiction_nkid = cpJurisdictionNkid
      )
      where next_rid is null
      --and implicit=0
      --and default_taxability is null
      order by cm_row, implicit;

      -- LOCALS
      outp IMPL_EXPL_XVIEW;
      l_JurisdictionNkid jurisdictions.nkid%type;
      l_ImplExpl Number;

      lower_jnkid number := null;
      lower_offn  jurisdictions.official_name%type;
      upper_jnkid numtabletype;
      upperJurisNkidList varchar2(100);

    begin
      --DBMS_OUTPUT.Put_Line( '-- Taxability_Grid_T --' );

      -- Parameters
      --
      l_JurisdictionNkid := nvl(pJurisdictionNkid, c_jta_nkid);
      l_ImplExpl := nvl(pImpExpl, display_implicit);
      --DBMS_OUTPUT.Put_Line(' J NKID:'||l_JurisdictionNkid);
      --DBMS_OUTPUT.Put_Line(' Impl:'||l_ImplExpl);

        if l_ImplExpl = 0 then
          For ii IN taxability_crs_expl(l_JurisdictionNkid)
          Loop
            outp := new IMPL_EXPL_XVIEW(ii.IMPLICIT,
              ii.IMPLEXPL_AUTH_LEVEL,
              ii.IMPL_CM_ORDER
            , ii.id
            , ii.reference_code
            , ii.calculation_method_id
            , ii.basis_percent
            , ii.recoverable_percent
            , ii.recoverable_amount
            , ii.start_date
            , ii.end_date
            , ii.entered_by
            , ii.entered_date
            , ii.status
            , ii.status_modified_date
            , ii.rid
            , ii.nkid
            , ii.next_rid
            , ii.jurisdiction_id
            , ii.jurisdiction_nkid
            , ii.jurisdiction_rid
            , ii.jurisdiction_official_name
            , ii.all_taxes_apply
            , ii.applicability_type_id
            , ii.charge_type_id
            , ii.unit_of_measure
            , ii.ref_rule_order
            , ii.default_taxability
            , ii.product_tree_id
            , ii.commodity_id
            , ii.commodity_nkid
            , ii.commodity_rid
            , ii.commodity_name
            , ii.commodity_code
            , ii.h_code
            , ii.conditions
            , ii.tax_type
            , ii.tax_applicabilities
            , ii.verification
            , ii.change_count
            , ii.commodity_tree_id
            , ii.is_local
            , ii.legal_statement
            , ii.canbedeleted
            , ii.maxstatus
            , NULL  -- tag_collection
            , NULL  -- condition_collection
            , NULL  -- applicable_tax_collection
            , NULL  -- crapp-2754 - override_order
            , NULL  -- crapp-2801 - VerifyList
            , ii.h_code
            );

            pipe row (outp);
          End Loop;
          Return;

         else  -- Implicit Records

/* This part is for the flexible view DISABLED

         -- get the name -- can be used later
         lower_jnkid := l_JurisdictionNkid;
         Select official_name into lower_offn
         from jurisdictions j where nkid = lower_jnkid;

          Select nkid
          bulk collect into upper_jnkid
          from jurisdictions j
          Where SUBSTR(j.official_name, 1, 4) = substr(lower_offn, 1, 4) and j.geo_area_category_id = 3;

For vii in upper_jnkid.first..upper_jnkid.last
Loop
  DBMS_OUTPUT.Put_Line( 'NKID:'|| upper_jnkid(vii) );
End Loop;

/*          For ii IN taxability_crs_impl(pJurisdictionNkid)
          Loop
            outp := new IMPL_EXPL_XVIEW(ii.IMPLICIT,
             ii.IMPLEXPL_AUTH_LEVEL,
             ii.IMPL_CM_ORDER
            ,ii.id
            ,ii.reference_code
            ,ii.calculation_method_id
            ,ii.basis_percent
            ,ii.recoverable_percent
            ,ii.recoverable_amount
            ,ii.start_date
            ,ii.end_date
            ,ii.entered_by
            ,ii.entered_date
            , ii.status
            ,ii.status_modified_date
            ,ii.rid
            , ii.nkid
            ,ii.next_rid
            , ii.jurisdiction_id
            , ii.jurisdiction_nkid
            , ii.jurisdiction_rid
            , ii.jurisdiction_official_name
            , ii.all_taxes_apply
            , ii.applicability_type_id
            ,ii.charge_type_id
            , ii.unit_of_measure
            , ii.ref_rule_order
            , ii.default_taxability
            , ii.product_tree_id
            , ii.commodity_id
            , ii.commodity_nkid
            , ii.commodity_rid
            , ii.commodity_name
            , ii.commodity_code
            , ii.h_code
            , ii.conditions
            , ii.tax_type
            , ii.tax_applicabilities
            , ii.verification
            , ii.change_count
            , ii.commodity_tree_id
            , ii.is_local
            , ii.legal_statement
            , ii.canbedeleted
            , ii.maxstatus);
            pipe row (outp);
           End Loop;*/
           null;
         end if;


    end taxability_grid_t;
END TAXABILITY_GRID;
/