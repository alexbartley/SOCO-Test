CREATE OR REPLACE PROCEDURE content_repo."IMPL_EXPL_COMM_BUILD" (oProcessId out number, pCommodityNkid in commodities.id%type,
pTest in number default 0, ppart in number default 1) is
/*
|| IMPL/EXPL build for selected Commodity for all Jurisdictions
|| ToDo: Code cleanup
*/
Type gridRecLevel2 is record
(
parent_id number,
child_id number,
offname varchar2(500),
h_code varchar2(128), --njv
commodity_name varchar2(500),--njv
commodity_code varchar2(100),
c_id number,
jta_id number,
id number,
ref_rule_order number,
IMPL number,
rid number
);
--test
TYPE GridRecs2 IS TABLE OF gridRecLevel2;

level1_array GridRecs2:=GridRecs2(); -- default
level2_array GridRecs2:=GridRecs2(); -- cascading default
level3_array GridRecs2:=GridRecs2(); -- regular explicit
level4_array GridRecs2:=GridRecs2(); -- regular cascading
level5_array GridRecs2:=GridRecs2(); -- regular flowdown

l_CommodityNkid number:=pCommodityNkid;
l_CommodityId number;
-- Process Id
processId number := 0; -- out parameter

-- Records for upper commodities
type rec_comms is record
(c_id number,
ccc_level number,
h_code_level number,
commtree varchar2(500),
CHILD_h_code varchar2(64),
commodity_id number,
cc_code varchar2(100)
);
TYPE tab_comms IS TABLE OF rec_comms;
t_commodities tab_comms:=tab_comms();


/*
|| Test section : Build one list
*/
/*
BatchSize number:=200;
dst varchar2(2);
cursor FullList(processId number) is
    select ipx.process_id, ipx.parent_id, ipx.child_id, ipx.offname, ipx.h_code, ipx.commodity_name, ipx.commodity_code, ipx.c_id, ipx.jta_id, ipx.impl, ipx.jta_level,
    ipx.rid
    from impl_comm_data_t ipx
    where ipx.process_id = processId
    order by ipx.c_id, ipx.parent_id, ipx.child_id, ipx.jta_level;

  TYPE tbl_levels IS TABLE OF FullList%ROWTYPE;
  l_table tbl_levels;
*/
  r_rec impl_expl_xview;
  l_processId number;

  uSelectedCommodity commodities.name%type;
  uSelectedCommCode commodities.h_code%type;
  uSelectedCommodityCode commodities.commodity_code%type;
  uSelectedCommLevel commodities_pctree_build.ccc_level%type;

begin
  -- ToDo: Refact. 1 call for the 4 statements
  begin
    Select cc.name into uSelectedCommodity from commodities cc where cc.nkid=pCommodityNkid and
    product_tree_id = 13 and next_rid is null;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error(-20001,'Commodity not found in the US product tree.');
  END;

Select cc.commodity_code into uSelectedCommodityCode from commodities cc where cc.nkid=pCommodityNkid and
product_tree_id = 13 and next_rid is null;

Select cc.id into l_CommodityId from commodities cc where cc.nkid=pCommodityNkid and
product_tree_id = 13 and next_rid is null;

select cc.h_code into uSelectedCommCode from commodities cc where cc.nkid=pCommodityNkid and
product_tree_id = 13 and next_rid is null;--njv

select ccc_level into uSelectedCommLevel from commodities_pctree_build where nkid = pCommodityNkid and
product_tree_id = 13;--njv

  -- Process log: When, what, message log
  Insert Into IMPL_PROCESS_LOG
  (processtime, stage, message)
  values(sysdate, 1, to_char(l_CommodityId)||':')
  returning processid into processId;

  -- This is the process id the UI will use in the view to get the data
  DBMS_OUTPUT.Put_Line( processId );
  oProcessId := processId;
  l_processId := processId;


-- What is the commodity selected:
-- pCommodityNkid


-- Get commodities above
WITH upCommodity as
(
 SELECT distinct
 --CASE when LEVEL = 1 THEN '* you selected this one' else '' end SL,
 rownum c_id
 , -1*LEVEL                ccc_level
 , Level                h_code_level
 --, sys_connect_by_path(ccc.name, '/') AS cpath
 --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
 , CommTree
 --, connect_by_root child_h_code as ppc
 --, CONNECT_BY_ISLEAF ppca
 --, ccc.parent_h_code
 , ccc.CHILD_h_code
 --, PRIOR commodity_id parent_id
 , ccc.commodity_id    commodity_id
 --, ccc.nkid            cc_nkid
 , ccc.commodity_code  cc_code
 --, ccc.name            cc_name
 --, ccc.product_tree_id cc_product_tree_id
 FROM commodities_pctree_build ccc
 Start with ccc.commodity_id = l_CommodityId
 CONNECT BY PRIOR ccc.parent_h_code = ccc.child_h_code
 ORDER SIBLINGS BY ccc.CHILD_h_code)
 Select *
 bulk collect into t_commodities
 from upCommodity
 order by c_id desc;

-- Got the commodities in the tree
DBMS_OUTPUT.Put_Line( t_commodities.count );

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- 1..ITS OWN - STATE LEVEL (or any without cascading default taxabilities)
-- LEVEL 1 = PROCESS_ORDER 3
-- TODO: DUPLICATE records for all parent commodities show up, we only need to show where the selected commodity default taxability exists
-- DEFAULT and APPLIED ONCE ONLY 7/15/2016
FOR recs1 in t_commodities.first..t_commodities.last LOOP
  DBMS_OUTPUT.Put_Line( t_commodities(recs1).CHILD_h_code||t_commodities(recs1).commtree );

With jtree as
(
SELECT rownum c_id
, LEVEL                ccc_level
--, sys_connect_by_path(ccc.name, '/') AS cpath
--, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
, connect_by_root child_id as ppc
, child_id
--, CONNECT_BY_ISLEAF ppca
, ccc.parent_id
, ccc.offname offname --NJV
, t_commodities(recs1).CHILD_h_code h_code --njv
, t_commodities(recs1).commtree commodity_name --njv
, t_commodities(recs1).cc_code commodity_code--njv
, PRIOR child_id prev_parent_id
, ccc.j_level
 FROM imp_js_tree_build ccc
 Start with ccc.parent_id = 0
 CONNECT BY PRIOR ccc.child_id = ccc.parent_id
 ORDER SIBLINGS BY ccc.j_level,ccc.parent_id
)
, datax as
(
Select jta.id,
jta.jurisdiction_id,
jta.jurisdiction_nkid,
jta.default_taxability,
jta.is_local,
jta.exempt,
jta.no_tax,
jta.reference_code,
jta.commodity_id,
jta.ref_rule_order
,j.rid
 from juris_tax_applicabilities jta
join jurisdictions j on (j.id = jta.jurisdiction_id)
 where
 (jta.commodity_id = t_commodities(recs1).commodity_id and jta.default_taxability='D' and is_local='N')
  or (jta.default_taxability='D' and jta.is_local='N')
)
Select distinct *
bulk collect into level1_array
from
-- you can wonder why it says too many values with a distinct in this one...
(Select parent_id, child_id, offname, h_code, commodity_name, commodity_code, 1 c_id, jta_id, id, ref_rule_order, decode(W_IF,0,1,1) IMPL
, rid
from
(Select
FIRST_VALUE(rr.parent_id) over (order by rr.child_id ) parent_id,
--rr.parent_id,
rr.child_id, rr.offname, rr.h_code, rr.commodity_name, rr.commodity_code, rr.c_id
--, LAST_VALUE(nvl(pp.id, rr.parent_id) IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) jta_id
--, LAST_VALUE(pp.start_date IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) USE_START_DATE
, MIN(pp.id) KEEP (DENSE_RANK FIRST order BY NVL2(parent_id,1,2)) over (partition by rr.parent_id, pp.id ) jta_id
, pp.id
,(select count(1) from juris_tax_applicabilities where id = pp.id and jurisdiction_nkid = rr.child_id) W_IF
,pp.reference_code
,pp.commodity_id
,pp.ref_rule_order
,pp.rid
--From myhierarchy rr
From jtree rr
join datax pp
on (pp.jurisdiction_id = rr.child_id)
)
);
IF recs1 = uSelectedCommLevel then --only insert if recs1 is the level of the commodity we care about
        FORALL ii in level1_array.first..level1_array.last
        INSERT INTO impl_comm_data_t
        VALUES (processId,
        level1_array(ii).parent_id,
        level1_array(ii).child_id,
        level1_array(ii).offname,
        level1_array(ii).c_id,
        level1_array(ii).jta_id,
        level1_array(ii).impl,
        1,
        level1_array(ii).rid
        , recs1,
        level1_array(ii).h_code,
        level1_array(ii).commodity_name,
        level1_array(ii).commodity_code
        );
        DBMS_OUTPUT.PUT_LINE('Bulk Insert');
end if;
END LOOP;
commit;



-- 2 DEFAULT CASCADING (all jurisdictions below each one)
-- LEVEL 2 = PROCESS ORDER 5
--FOR recs1 in t_commodities.first..t_commodities.last LOOP
--DBMS_OUTPUT.Put_Line( t_commodities(recs1).CHILD_h_code||t_commodities(recs1).commtree );
-- Only the single oommodity?
--

With jtree as
(
SELECT rownum c_id
, LEVEL                ccc_level
--, sys_connect_by_path(ccc.name, '/') AS cpath
--, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
, connect_by_root child_id as ppc
, child_id
--, CONNECT_BY_ISLEAF ppca
, ccc.parent_id
--, ccc.offname ||' ('||uSelectedCommodity||' '||uSelectedCommCode||')' offname --njv
, ccc.offname offname --NJV
, uSelectedCommCode h_code --njv
, uSelectedCommodity commodity_name --njv
, uSelectedCommodityCode commodity_code --njv
, PRIOR child_id prev_parent_id
, ccc.j_level
FROM imp_js_tree_build ccc
Start with ccc.parent_id = 0
CONNECT BY PRIOR ccc.child_id = ccc.parent_id
ORDER SIBLINGS BY ccc.j_level,ccc.parent_id
)
, datax as
(
Select jta.id,
jta.jurisdiction_id,
jta.jurisdiction_nkid,
jta.default_taxability,
jta.is_local,
jta.exempt,
jta.no_tax,
jta.reference_code,
jta.commodity_id,
jta.ref_rule_order
,j.rid
 from juris_tax_applicabilities jta
join jurisdictions j on (j.id = jta.jurisdiction_id)
 where
  (jta.commodity_id = l_CommodityId and jta.default_taxability='D' and is_local='Y')
   or (jta.default_taxability='D' and jta.is_local='Y')
)
/*,
myhierarchy (parent_id, depth, child_id, offname, c_id) AS
  (
   SELECT d.parent_id, 0, d.child_id, d.offname, d.c_id FROM jtree d
   )*/
/*Select parent_id, child_id, offname, c_id, jta_id, id, ref_rule_order, decode(id,null,1,0) IMPL
from
(*/
Select parent_id, child_id, offname, h_code, commodity_name, commodity_code, c_id, jta_id, id, ref_rule_order, 1 IMPL
, rid
bulk collect into level2_array
from
(
Select rr.parent_id, rr.child_id, rr.offname, rr.h_code, rr.commodity_name, rr.commodity_code, rr.c_id
--, LAST_VALUE(nvl(pp.id, rr.parent_id) IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) ApplyThis
--, LAST_VALUE(pp.start_date IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) USE_START_DATE
, LAST_VALUE(pp.id IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) jta_id

, LAST_VALUE(pp.id) over (order by rr.child_id ) jta_wid

,pp.id
,(select count(1) from juris_tax_applicabilities where id = pp.id and jurisdiction_nkid = rr.child_id) W_IF
,pp.reference_code
,pp.commodity_id
,pp.ref_rule_order
,pp.rid
From datax pp
join jtree rr partition by (rr.child_id)
on (pp.jurisdiction_id = case when rr.parent_id = 0 then rr.child_id else rr.parent_id end )
)
--where child_id is not null
Order By c_id, parent_id, child_id;


        FORALL ii in level2_array.first..level2_array.last
        INSERT INTO impl_comm_data_t
        VALUES (processId,
        level2_array(ii).parent_id,
        level2_array(ii).child_id,
        level2_array(ii).offname,
        level2_array(ii).c_id,
        level2_array(ii).jta_id,
        level2_array(ii).impl,
        2,
        level2_array(ii).rid,
        0,
        level2_array(ii).h_code,
        level2_array(ii).commodity_name,
        level2_array(ii).commodity_code
        );

commit;



/*
||  LEVEL 3 = PROCESS_ORDER 1
||  Non-Cascading normal for each jurisdiction
||
||
*/
With jtree as
(
SELECT rownum c_id
, LEVEL                ccc_level
--, sys_connect_by_path(ccc.name, '/') AS cpath
--, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
, connect_by_root child_id as ppc
, child_id
--, CONNECT_BY_ISLEAF ppca
, ccc.parent_id
, ccc.offname offname --NJV
, uSelectedCommCode h_code --njv
, uSelectedCommodity commodity_name --njv
, uSelectedCommodityCode commodity_code --njv
, PRIOR child_id prev_parent_id
, ccc.j_level
FROM imp_js_tree_build ccc
Start with ccc.parent_id = 0
CONNECT BY PRIOR ccc.child_id = ccc.parent_id
ORDER SIBLINGS BY ccc.j_level,ccc.parent_id
)
, datax as
(
Select
--j.official_name,
jta.id,
jta.jurisdiction_id,
jta.jurisdiction_nkid,
jta.default_taxability,
jta.is_local,
jta.exempt,
jta.no_tax,
jta.reference_code,
jta.commodity_id,
jta.ref_rule_order
,j.rid
 from juris_tax_applicabilities jta
join jurisdictions j on (j.id = jta.jurisdiction_id)
 where jta.commodity_id = l_CommodityId --only do this for the commodity we are choosing
     and jta.default_taxability is null
     and jta.is_local='N'
)
,
myhierarchy (parent_id, depth, child_id, offname, h_code, commodity_name, commodity_code, c_id) AS
  (
   SELECT d.parent_id, 0, d.child_id, d.offname, d.h_code, d.commodity_name, d.commodity_code, d.c_id FROM jtree d
   )
Select parent_id, child_id, offname, h_code, commodity_name, commodity_code, c_id, jta_id, id, ref_rule_order, decode(w_if,1,0,1) IMPL
, rid
bulk collect into level3_array
from
(
  Select rr.parent_id, rr.child_id, rr.offname, rr.h_code, rr.commodity_name, rr.commodity_code, rr.c_id
  , LAST_VALUE(nvl(pp.id, rr.parent_id) IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) ApplyThis
  , LAST_VALUE(pp.id IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) jta_id
  , pp.id
  ,(select count(1) from juris_tax_applicabilities where id = pp.id and jurisdiction_nkid = rr.child_id) W_IF
  ,pp.reference_code
  ,pp.commodity_id
  ,pp.ref_rule_order
  ,pp.rid
  From myhierarchy rr
  --left
  join datax pp
  on (pp.jurisdiction_id = rr.child_id)
)
Order By c_id, parent_id, child_id;


        FORALL ii in level3_array.first..level3_array.last
        INSERT INTO impl_comm_data_t (
        PROCESS_ID
        ,PARENT_ID
        ,CHILD_ID
        ,OFFNAME
        ,C_ID
        ,JTA_ID
        ,IMPL
        ,JTA_LEVEL
        ,RID
        ,TREE_ORDER
        ,H_CODE
        ,COMMODITY_NAME
        ,COMMODITY_CODE
        )
        VALUES (processId,
        level3_array(ii).parent_id,
        level3_array(ii).child_id,
        level3_array(ii).offname,
        level3_array(ii).c_id,
        level3_array(ii).jta_id,
        0,
        3
        , level3_array(ii).rid
        , uSelectedCommLevel
        , level3_array(ii).h_code
        , level3_array(ii).commodity_name
        , level3_array(ii).commodity_code
        );

commit;

FOR recs5 in t_commodities.first..t_commodities.last LOOP
  DBMS_OUTPUT.Put_Line( t_commodities(recs5).CHILD_h_code||t_commodities(recs5).commtree );

/*
||  LEVEL 5 = PROCESS_ORDER 2
||  Non-Cascading flow down for each jurisdiction and every commodity except the one we are looking at
||
||
*/
with datax as
(
Select rownum c_id,
j.id parent_id,
j.id child_id,
j.official_name offname,
cp.h_code,
cp.name commodity_name,
cp.commodity_code commodity_code,
jta.id,
jta.jurisdiction_id,
jta.jurisdiction_nkid,
jta.default_taxability,
jta.is_local,
jta.exempt,
jta.no_tax,
jta.reference_code,
jta.commodity_id,
jta.ref_rule_order
,j.rid
 from juris_tax_applicabilities jta
join jurisdictions j on (j.id = jta.jurisdiction_id)
join commodities_pctree cp on (cp.id = jta.commodity_id)
 where jta.commodity_id = t_commodities(recs5).commodity_id
     and jta.default_taxability is null
     and jta.commodity_id != l_CommodityId -- don't show flow-down from provided commodity in a local Jurisdiction
     and jta.is_local='N'
)
Select parent_id, child_id, offname, h_code, commodity_name, commodity_code, c_id, jta_id, id, ref_rule_order, decode(w_if,1,0,1) IMPL
, rid
bulk collect into level5_array
from
(
  Select pp.parent_id, pp.child_id, pp.offname, pp.h_code, pp.commodity_name, pp.commodity_code, pp.c_id
  --, LAST_VALUE(nvl(pp.id, rr.parent_id) IGNORE NULLS) over (partition by pp.parent_id, pp.id order by pp.parent_id ) ApplyThis
  --, LAST_VALUE(pp.id IGNORE NULLS) over (partition by pp.parent_id, pp.id order by pp.parent_id ) jta_id
  ,pp.id jta_id
  , pp.id

  ,(select count(1) from juris_tax_applicabilities where id = pp.id and jurisdiction_nkid = pp.child_id) W_IF
  ,pp.reference_code
  ,pp.commodity_id
  ,pp.ref_rule_order
  ,pp.rid
  From datax pp
 --on (pp.jurisdiction_id = rr.child_id)
)
Order By c_id, parent_id, child_id;


        FORALL ii in level5_array.first..level5_array.last
        INSERT INTO impl_comm_data_t (
        PROCESS_ID
        ,PARENT_ID
        ,CHILD_ID
        ,OFFNAME
        ,C_ID
        ,JTA_ID
        ,IMPL
        ,JTA_LEVEL
        ,RID
        ,TREE_ORDER
        ,H_CODE
        ,COMMODITY_NAME
        ,COMMODITY_CODE
        )
        VALUES (processId,
        level5_array(ii).parent_id,
        level5_array(ii).child_id,
        level5_array(ii).offname,
        level5_array(ii).c_id,
        level5_array(ii).jta_id,
        1,
        5
        , level5_array(ii).rid
        , recs5
        , level5_array(ii).h_code
        , level5_array(ii).commodity_name
        , level5_array(ii).commodity_code
        );

end loop;
commit;


/*
|| IMPL/EXPL LEVEL 4 : Cascading REGULAR rule
|| LEVEL 4 = PROCESS_ORDER 4
||
||
*/
FOR recs4 in t_commodities.first..t_commodities.last LOOP
  DBMS_OUTPUT.Put_Line( t_commodities(recs4).CHILD_h_code||t_commodities(recs4).commtree );

With jtree as
(
SELECT rownum c_id
, LEVEL                ccc_level
--, sys_connect_by_path(ccc.name, '/') AS cpath
--, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
, connect_by_root child_id as ppc
, child_id
--, CONNECT_BY_ISLEAF ppca
, ccc.parent_id
, ccc.offname offname --NJV
, t_commodities(recs4).CHILD_h_code h_code --njv
, t_commodities(recs4).commtree commodity_name --njv
, t_commodities(recs4).cc_code commodity_code --njv
, PRIOR child_id prev_parent_id
, ccc.j_level
FROM imp_js_tree_build ccc
Start with ccc.parent_id = 0
CONNECT BY PRIOR ccc.child_id = ccc.parent_id
ORDER SIBLINGS BY ccc.j_level,ccc.parent_id
)
, datax as
(
Select jta.id,
jta.jurisdiction_id,
jta.jurisdiction_nkid,
jta.default_taxability,
jta.is_local,
jta.exempt,
jta.no_tax,
jta.reference_code,
jta.commodity_id,
jta.ref_rule_order
,j.rid
from juris_tax_applicabilities jta
join jurisdictions j on (j.id = jta.jurisdiction_id)
 where jta.commodity_id = t_commodities(recs4).commodity_id
   and jta.default_taxability is null
   and jta.is_local='Y'
)
/*,
myhierarchy (parent_id, depth, child_id, offname, c_id) AS
  (
   SELECT d.parent_id, 0, d.child_id, d.offname, d.c_id FROM jtree d
   )*/
/*Select parent_id, child_id, offname, c_id, jta_id, id, ref_rule_order, decode(id,null,1,0) IMPL
from
(*/
Select parent_id, child_id, offname, h_code, commodity_name, commodity_code, c_id, jta_id, id, ref_rule_order, decode(w_if,1,0,1) IMPL
, rid
bulk collect into level4_array
from
(
Select rr.parent_id, rr.child_id, rr.offname, rr.h_code, rr.commodity_name, rr.commodity_code, rr.c_id
--, LAST_VALUE(nvl(pp.id, rr.parent_id) IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) ApplyThis
--, LAST_VALUE(pp.start_date IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) USE_START_DATE
, LAST_VALUE(pp.id IGNORE NULLS) over (partition by rr.parent_id, pp.id order by rr.parent_id ) jta_id

, LAST_VALUE(pp.id) over (order by rr.child_id ) jta_wid

,pp.id
,(select count(1) from juris_tax_applicabilities where id = pp.id and jurisdiction_nkid = rr.child_id) W_IF
,pp.reference_code
,pp.commodity_id
,pp.ref_rule_order
,pp.rid
From datax pp
join jtree rr partition by (rr.child_id)
on (pp.jurisdiction_id = case when rr.parent_id = 0 then rr.child_id else rr.parent_id end )
)
--where child_id is not null
Order By c_id, parent_id, child_id;

        FORALL ii in level4_array.first..level4_array.last
        INSERT INTO impl_comm_data_t
        VALUES (processId,
        level4_array(ii).parent_id,
        level4_array(ii).child_id,
        level4_array(ii).offname,
        level4_array(ii).c_id,
        level4_array(ii).jta_id,
        level4_array(ii).impl,
        4,
        level4_array(ii).rid
        , recs4,
                level4_array(ii).h_code,
        level4_array(ii).commodity_name,
        level4_array(ii).commodity_code
        );

End loop;
update impl_process_log
set message = message||substr(to_char((sysdate - processtime)*24*60*60),0,4)
where processid = l_processId;
  commit;--njv


INSERT INTO IMPL_EXPL_RAW_DS
(
--  use_hash (ipx, xx) parallel(ipx, 4) parallel(xx, 4)
select /*+index(ipx impl_comm_data_i1)*/ -- 08/01/16 using new index instead of parallel hash
   processid
           ,ipx.impl IMPLICIT
           ,ipx.jta_level IMPLEXPL_AUTH_LEVEL
           ,ipx.c_id IMPL_CM_ORDER
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
           ,ipx.child_id jurisdiction_id
           ,xx.jurisdiction_nkid
           ,ipx.rid jurisdiction_rid
           ,ipx.offname jurisdiction_official_name
           ,xx.all_taxes_apply
           ,xx.applicability_type_id
           ,xx.charge_type_id
           ,xx.unit_of_measure
           ,xx.ref_rule_order
           ,xx.default_taxability
           ,xx.product_tree_id
           ,xx.commodity_id
           ,xx.commodity_nkid
           ,xx.commodity_rid
           ,ipx.commodity_name
           ,ipx.commodity_code
           ,ipx.h_code
           ,' ' conditions
           --,xx.conditions
           ,xx.tax_type
           ,xx.tax_applicabilities
           ,xx.verification
           ,xx.change_count
           ,xx.commodity_tree_id
           ,xx.is_local
           ,xx.legal_statement
           ,xx.canbedeleted
           ,xx.maxstatus
           ,xx.tag_collection
           ,xx.condition_collection
           ,xx.applicable_tax_collection
           ,CASE WHEN ipx.jta_level = 3 THEN 1 -- EXPLICIT AT THE JURISDICTION ONLY SELECTED COMMODITY
                WHEN ipx.jta_level = 5 THEN 2 -- EXPLICIT AT THE JURISDICTION'S ANY PARENT COMMODITY
                WHEN ipx.jta_level = 4 THEN 4 -- STATE LEVEL CASCADING FLOW-DOWN
                WHEN ipx.jta_level = 1 THEN 3 -- STATE LEVEL DEFAULT TAXABILITY
                WHEN ipx.jta_level = 2 THEN 5 -- STATE LEVEL DEFAULT CASCADING TAXABILITY
            ELSE 9
            END processing_order
           ,xx.verifylist
           ,ipx.h_code SOURCE_H_CODE
   from impl_comm_data_t ipx
   join
   taxability_search_v xx on (xx.id = ipx.jta_id)
   where ipx.process_id=l_processId);

--END LOOP;
update impl_process_log
set message = message||'|'||substr(to_char((sysdate - processtime)*24*60*60),0,5)
where processid = l_processId;
Commit;

  -- CRAPP-3047
  EXCEPTION
  -- Any failure report and stop. No point giving partial data.
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Implicit commodity failed');


end impl_expl_comm_build;
/