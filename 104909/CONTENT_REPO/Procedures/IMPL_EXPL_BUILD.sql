CREATE OR REPLACE PROCEDURE content_repo."IMPL_EXPL_BUILD" (oProcessId out number, pJurisdictionNkid in jurisdictions.nkid%type) is

Type insTreeLevel3 is record
(
      process_id number,
      r_level number,
      impl number,
      commodity_id number,
      juris_tax_applicability_id number,
      applyfromcomm number,
      source_h_code varchar2(128 char)
      );
type insTreeTab is Table of insTreeLevel3;
instreeArray insTreeTab := insTreeTab();
/* ------------------------------------------------------------------------*/

Type gridRec is record
(
IMPL number,
C_ID number,
ccc_level number,
h_code_level number,
commtree varchar2(500),
ppc varchar2(128),
parent_h_code varchar2(128),
child_h_code varchar2(128),
parent_id number,
cc_commodity_id number,
cc_nkid number,
cc_code varchar2(128),
cc_name varchar2(500),
cc_product_tree_id number,
ID                             NUMBER                ,
REFERENCE_CODE                 VARCHAR2(100 CHAR)    ,
CALCULATION_METHOD_ID          NUMBER                ,
BASIS_PERCENT                  NUMBER,
RECOVERABLE_PERCENT            NUMBER,
START_DATE                     DATE,
END_DATE                       DATE,
ENTERED_BY                     NUMBER                ,
ENTERED_DATE                   DATE ,
STATUS                         NUMBER                ,
STATUS_MODIFIED_DATE           DATE ,
RID                            NUMBER                ,
NKID                           NUMBER                ,
NEXT_RID                       NUMBER,
JURISDICTION_ID                NUMBER ,
JURISDICTION_NKID              NUMBER  ,
ALL_TAXES_APPLY                NUMBER(1,0)           ,
RECOVERABLE_AMOUNT             NUMBER,
APPLICABILITY_TYPE_ID          NUMBER                ,
UNIT_OF_MEASURE                VARCHAR2(16 CHAR),
REF_RULE_ORDER                 NUMBER,
DEFAULT_TAXABILITY             VARCHAR2(1 CHAR),
PRODUCT_TREE_ID                NUMBER,
COMMODITY_ID                   NUMBER,
TAX_TYPE                       VARCHAR2(4 CHAR),
IS_LOCAL                       VARCHAR2(1 CHAR),
EXEMPT                         VARCHAR2(1 CHAR),
NO_TAX                         VARCHAR2(1 CHAR),
COMMODITY_NKID                 NUMBER,
CHARGE_TYPE_ID                 NUMBER,
SOURCE_H_CODE varchar2(128)
);

TYPE GridRecs IS TABLE OF gridRec;
level1_array GridRecs:=GridRecs(); -- default

Type gridRecLevel2 is record
(
id number,
IMPL number,
COMMODITY_ID number,
parent_id number,
parent_h_code varchar2(128),
commtree varchar2(500),
applythis number,
USE_START_DATE date,
start_date date,
X1 date,
c_id number,
REFERENCE_CODE                 VARCHAR2(100 CHAR),
source_h_code varchar2(128)
);
TYPE GridRecs2 IS TABLE OF gridRecLevel2;
level2_array GridRecs2:=GridRecs2(); -- cascading
level3_array GridRecs2:=GridRecs2(); -- selected jurisdiction

/*
|| Crs
||
*/
Cursor lvl2cur(p_commodity number, pLevel number, pProcessId in number) is
Select * from
(
  Select ccc.*
  --, first_value(dd.juris_tax_applicability_id) over (order by ppc) jta_id
  , last_value(dd.juris_tax_applicability_id ignore nulls) over (order by ppc, decode(jta.is_local,'Y',1,0)) jta_id
  , dd.juris_tax_applicability_id jta_id_existing
  , case when dd.juris_tax_applicability_id is not null then rownum else 10000 end rec_stop
  , dd.impl
  , first_value(ccc.CHILD_h_code ignore nulls) over (partition by dd.juris_tax_applicability_id order by ppc, decode(jta.is_local,'Y',1,0)) source_h_code
  from
  (
  SELECT distinct rownum c_id
  , LEVEL                ccc_level
, Level                h_code_level
--, sys_connect_by_path(ccc.name, '/') AS cpath
--, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
, CommTree
, connect_by_root child_h_code as ppc
--, CONNECT_BY_ISLEAF ppca
, ccc.parent_h_code
, ccc.CHILD_h_code
, PRIOR ccc.commodity_id parent_id
, ccc.commodity_id    commodity_id
, ccc.nkid            cc_nkid
, ccc.commodity_code  cc_code
, ccc.name            cc_name
, ccc.product_tree_id cc_product_tree_id
FROM commodities_pctree_build ccc
Start with ccc.commodity_id = p_commodity
--CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
CONNECT BY PRIOR ccc.parent_h_code = ccc.child_h_code
ORDER BY c_id
) ccc
join impl_process_levels dd on (dd.commodity_id = ccc.commodity_id and dd.r_level= pLevel)
left join juris_tax_applicabilities jta on (jta.id = dd.juris_tax_applicability_id)
where dd.process_id = pProcessId
ORDER BY ccc.c_id, impl asc
)
where rec_stop <10000
--and rownum=1
ORDER BY c_id desc;

  rr numtabletype;
  rs numtabletype;

  lvl3id number;
  lvl2id number;
  lvl1id number;

  lower_jnkid number := null;
  lower_offn  jurisdictions.official_name%type;
  lower_category jurisdictions.geo_area_category_id%type;

  upper_jnkid numtabletype;
  upperJurisNkidList varchar2(100);

  -- Process Id
  processId number := oProcessId; -- out parameter

  -- IN PARAMETERS (in package this will be defined at the top)
  l_JurisdictionNkid jurisdictions.nkid%type := pJurisdictionNkid;

  start_time  number;
  end_time   number;
Begin


  /*
  || Process information 5/1
  || [Message queue discussion - if this moves towards a "save and notify" functionality]
  || (Developed in 11g. In 12c we can use autoicrement of the primary key.)
  || CreTab process implicit explicit records
  ||
  || Build section for dependent objects
  ||
  exec drop_ifexists(pv_type=> 'SEQUENCE', pv_table=> 'IMPL_PROCESS_PK');
  exec drop_ifexists(pv_type=> 'TABLE', pv_table=> 'IMPL_PROCESS_LOG');
  Create sequence IMPL_PROCESS_PK start with 100;
  Create Table IMPL_PROCESS_LOG
  (processId number primary key
  , processTime date
  , stage number
  , message varchar2(50)
  );
  Create trigger impl_process_log_ti
       before insert on impl_process_log
      for each row
  Begin
      select impl_process_pk.nextval
        into :new.processId
        from dual;
  End;
  */

  -- Process log: When, what, message log
  Insert Into IMPL_PROCESS_LOG
  (processtime, stage, message)
  values(sysdate, 1, 'Init '||to_char(l_JurisdictionNkid))
  returning processid into processId;
  oProcessId := processId;

  -- This is the process id the UI will use in the view to get the data
  DBMS_OUTPUT.Put_Line( processId );

  /*
  || JTA_NKID
  || (could be its own function)
  || Get Jurisdiction information + upper level
  ||          Remember that a lower level can have multiple upper levels
  ||          Example: MO - EMMA has MO - STATE SALES/USE TAX and MO - STATE FEES
  ||
  || Even if the CITY jurisdiction is, for example, SALES, there is nothing in the
  || database that will tell you if it is a SALES jurisdiction except for the name.
  ||
  || Additions:
  ||  Level 1 (when looking at a STATE) IS_LOCAL should not apply
  ||
  */

  -- Selected Jurisdiction
  lower_jnkid := l_JurisdictionNkid;
  Select official_name, geo_area_category_id into lower_offn, lower_category
  from jurisdictions j where nkid = lower_jnkid;

  -- Get the NKID of jurisdictions above the selected one.
  -- (Obv. does not apply when STATE is selected)
  -- The level is based on geo_area_category_id = 3
  if lower_category<>3 then
    Select nkid
      bulk collect into upper_jnkid
      from jurisdictions j
    Where SUBSTR(j.official_name, 1, 4) = substr(lower_offn, 1, 4) and j.geo_area_category_id = 3
    order by nkid;
  else
    -- Hack: should have been a single variable and no bulk
    Select nkid
      bulk collect into upper_jnkid
      from jurisdictions j
    Where nkid = l_JurisdictionNkid;
  end if;

  /*
  || No upper levels for STATE
  || 20160629
  */
  If lower_category<>3 then
    -- Are there multiple upper level jurisdictions? If so, loop through all of
    -- them.
    -- (I have NO way to tell if lower and upper levels of Jurisdictions are
    --  Sales or Rentals except for using the TEXT of the jurisdiction and that
    --  wouldn't be right to use. This should be authority levels.)
   if upper_jnkid.count > 0 then

    For vii in upper_jnkid.first..upper_jnkid.last
    Loop

    -- LEVEL1
    -- 1. get the upper level from jurisdiction
    -- 2. populate Default taxabilities
    -- 3. if this one has multiple Jurisdictions the whole process need to go through and add
    --    to the output array
    --
    -- NOTE: Open up the sys_connect_by_path if you want to see the product
    -- while in the database.
    -- The tree table, COMMODITY_PCTREE_BUILD has a formatted column, COMMTREE, that
    -- can be used to see the hierarchy of the commodities.
    --

    WITH mydata AS
    (
      select 1 impl, LVL1.* from
      (SELECT distinct rownum c_id
       , LEVEL                ccc_level
       , Level                h_code_level
       --, sys_connect_by_path(ccc.name, '/') AS cpath
       --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
       , CommTree
       , connect_by_root child_h_code as ppc
       --, CONNECT_BY_ISLEAF ppca
       , ccc.parent_h_code
       , ccc.CHILD_h_code
       , PRIOR commodity_id parent_id
       , ccc.commodity_id    commodity_id
       , ccc.nkid            cc_nkid
       , ccc.commodity_code  cc_code
       , ccc.name            cc_name
       , ccc.product_tree_id cc_product_tree_id
       FROM commodities_pctree_build ccc
       Start with ccc.parent_h_code ='000.'
       CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
       ORDER SIBLINGS BY ccc.CHILD_h_code
       ) LVL1 where cc_code is not null
    ),
    myproperties AS
    (
      SELECT
      ID                             ,
      REFERENCE_CODE                 ,
      CALCULATION_METHOD_ID          ,
      BASIS_PERCENT                  ,
      RECOVERABLE_PERCENT            ,
      START_DATE                     ,
      END_DATE                       ,
      ENTERED_BY                     ,
      ENTERED_DATE                   ,
      STATUS                         ,
      STATUS_MODIFIED_DATE           ,
      RID                            ,
      NKID                           ,
      NEXT_RID                       ,
      JURISDICTION_ID                ,
      JURISDICTION_NKID              ,
      ALL_TAXES_APPLY                ,
      RECOVERABLE_AMOUNT             ,
      APPLICABILITY_TYPE_ID          ,
      UNIT_OF_MEASURE                ,
      REF_RULE_ORDER                 ,
      DEFAULT_TAXABILITY             ,
      PRODUCT_TREE_ID                ,
      COMMODITY_ID                   ,
      TAX_TYPE                       ,
      IS_LOCAL                       ,
      EXEMPT                         ,
      NO_TAX                         ,
      COMMODITY_NKID                 ,
      CHARGE_TYPE_ID,
      '' SOURCE_H_CODE               -- Processing level 1 we said no h_code for these
      FROM juris_tax_applicabilities e
      where jurisdiction_nkid = upper_jnkid(vii)
        and default_taxability='D'
        and is_local = (case when lower_category<>3 then 'Y' else 'N' end)
        and next_rid is null
    )
    Select rr.*, pp.*
    BULK COLLECT INTO level1_array
    From mydata rr
    left join myproperties pp partition by (pp.nkid)
    on (pp.product_tree_id = rr.cc_product_tree_id)
    -- and (pp.ccid = rr.commodity_id)
    Order By c_id, parent_h_code, child_h_code;

    -- Apply top level
    -- (Default taxability - all commodities)
    IF level1_array.count >0 then
      for ix1 in level1_array.first..level1_array.last loop
        if level1_array(ix1).parent_id is null then
        level1_array(ix1).ID                           := level1_array(1).id;
        level1_array(ix1).REFERENCE_CODE               := level1_array(1).REFERENCE_CODE;
        level1_array(ix1).CALCULATION_METHOD_ID        := level1_array(1).CALCULATION_METHOD_ID;
        level1_array(ix1).BASIS_PERCENT                := level1_array(1).BASIS_PERCENT        ;
        level1_array(ix1).RECOVERABLE_PERCENT          := level1_array(1).RECOVERABLE_PERCENT  ;
        level1_array(ix1).START_DATE                   := level1_array(1).START_DATE           ;
        level1_array(ix1).END_DATE                     := level1_array(1).END_DATE             ;
        level1_array(ix1).ENTERED_BY                   := level1_array(1).ENTERED_BY           ;
        level1_array(ix1).ENTERED_DATE                 := level1_array(1).ENTERED_DATE         ;
        level1_array(ix1).STATUS                       := level1_array(1).STATUS               ;
        level1_array(ix1).STATUS_MODIFIED_DATE         := level1_array(1).STATUS_MODIFIED_DATE ;
        level1_array(ix1).RID                          := level1_array(1).RID                  ;
        level1_array(ix1).NKID                         := level1_array(1).NKID                 ;
        level1_array(ix1).NEXT_RID                     := level1_array(1).NEXT_RID             ;
        level1_array(ix1).JURISDICTION_ID              := level1_array(1).JURISDICTION_ID      ;
        level1_array(ix1).JURISDICTION_NKID            := level1_array(1).JURISDICTION_NKID    ;
        level1_array(ix1).ALL_TAXES_APPLY              := level1_array(1).ALL_TAXES_APPLY      ;
        level1_array(ix1).RECOVERABLE_AMOUNT           := level1_array(1).RECOVERABLE_AMOUNT   ;
        level1_array(ix1).APPLICABILITY_TYPE_ID        := level1_array(1).APPLICABILITY_TYPE_ID;
        level1_array(ix1).UNIT_OF_MEASURE              := level1_array(1).UNIT_OF_MEASURE      ;
        level1_array(ix1).REF_RULE_ORDER               := level1_array(1).REF_RULE_ORDER       ;
        level1_array(ix1).DEFAULT_TAXABILITY           := level1_array(1).DEFAULT_TAXABILITY   ;
        level1_array(ix1).PRODUCT_TREE_ID              := level1_array(1).PRODUCT_TREE_ID      ;
        level1_array(ix1).COMMODITY_ID                 := level1_array(1).COMMODITY_ID         ;
        level1_array(ix1).TAX_TYPE                     := level1_array(1).TAX_TYPE             ;
        level1_array(ix1).IS_LOCAL                     := level1_array(1).IS_LOCAL             ;
        level1_array(ix1).EXEMPT                       := level1_array(1).EXEMPT               ;
        level1_array(ix1).NO_TAX                       := level1_array(1).NO_TAX               ;
        level1_array(ix1).COMMODITY_NKID               := level1_array(1).COMMODITY_NKID       ;
        level1_array(ix1).CHARGE_TYPE_ID               := level1_array(1).CHARGE_TYPE_ID       ;
        level1_array(ix1).SOURCE_H_CODE                := '';

       end if;
     end loop;

        FORALL ii in level1_array.first..level1_array.last
        INSERT INTO impl_process_levels VALUES (processId, 1, 1, level1_array(ii).cc_commodity_id,
        level1_array(ii).id, level1_array(ii).reference_code, level1_array(ii).parent_id, '');

    COMMIT;

    End If;

    -- No Tax
    -- Added 6/30/2016, removed 7/5/2016
    /*  level1_array :=GridRecs(); -- reset for 'no tax'
      WITH mydata AS
        (
        select 1 impl, LVL1.* from
        (SELECT distinct rownum c_id
        , LEVEL                ccc_level
        , Level                h_code_level
        --, sys_connect_by_path(ccc.name, '/') AS cpath
        --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
        , CommTree
        , connect_by_root child_h_code as ppc
        --, CONNECT_BY_ISLEAF ppca
        , ccc.parent_h_code
        , ccc.CHILD_h_code
        , PRIOR commodity_id parent_id
        , ccc.commodity_id    commodity_id
        , ccc.nkid            cc_nkid
        , ccc.commodity_code  cc_code
        , ccc.name            cc_name
        , ccc.product_tree_id cc_product_tree_id
        FROM commodities_pctree_build ccc
        Start with ccc.parent_h_code ='000.'
        CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
        ORDER SIBLINGS BY ccc.CHILD_h_code
        ) LVL1 where cc_code is not null
        ),
        myproperties AS
        (
        SELECT
        ID                             ,
        REFERENCE_CODE                 ,
        CALCULATION_METHOD_ID          ,
        BASIS_PERCENT                  ,
        RECOVERABLE_PERCENT            ,
        START_DATE                     ,
        END_DATE                       ,
        ENTERED_BY                     ,
        ENTERED_DATE                   ,
        STATUS                         ,
        STATUS_MODIFIED_DATE           ,
        RID                            ,
        NKID                           ,
        NEXT_RID                       ,
        JURISDICTION_ID                ,
        JURISDICTION_NKID              ,
        ALL_TAXES_APPLY                ,
        RECOVERABLE_AMOUNT             ,
        APPLICABILITY_TYPE_ID          ,
        UNIT_OF_MEASURE                ,
        REF_RULE_ORDER                 ,
        DEFAULT_TAXABILITY             ,
        PRODUCT_TREE_ID                ,
        COMMODITY_ID                   ,
        TAX_TYPE                       ,
        IS_LOCAL                       ,
        EXEMPT                         ,
        NO_TAX                         ,
        COMMODITY_NKID                 ,
        CHARGE_TYPE_ID
        FROM juris_tax_applicabilities e
        where jurisdiction_nkid = upper_jnkid(vii)
        and no_tax='Y' and COMMODITY_ID is null
        and is_local = (case when lower_category<>3 then 'Y' else 'N' end)
        and next_rid is null
        )
        Select rr.*, pp.*
        BULK COLLECT INTO level1_array
        From mydata rr
        left join myproperties pp partition by (pp.nkid)
        on (pp.product_tree_id = rr.cc_product_tree_id)
        Order By c_id, parent_h_code, child_h_code;

        IF level1_array.count >0 then
        FORALL ii in level1_array.first..level1_array.last
        INSERT INTO impl_process_levels VALUES (processId, 1, 1, level1_array(ii).cc_commodity_id,
        level1_array(ii).id, level1_array(ii).reference_code, level1_array(ii).parent_id);
        End If;
      */
      --DBMS_OUTPUT.Put_Line( 'NKID:'|| upper_jnkid(vii) );

      End Loop;  -- Jurisdiction geo_area_category_id 3 loop

    END IF;

  End if;

  /*
  || STATE level selected
  || 1.Build the default taxabilities first
  || 2.Skip the default taxabilities in LEVEL 3
  */
  If lower_category=3 then

   WITH mydata AS
   (
   select 1 impl, LVL1.* from
   (SELECT distinct rownum c_id
    , LEVEL                ccc_level
    , Level                h_code_level
    --, sys_connect_by_path(ccc.name, '/') AS cpath
    --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
    , CommTree
    , connect_by_root child_h_code as ppc
    --, CONNECT_BY_ISLEAF ppca
    , ccc.parent_h_code
    , ccc.CHILD_h_code
    , PRIOR commodity_id parent_id
    , ccc.commodity_id    commodity_id
    , ccc.nkid            cc_nkid
    , ccc.commodity_code  cc_code
    , ccc.name            cc_name
    , ccc.product_tree_id cc_product_tree_id
    FROM commodities_pctree_build ccc
    Start with ccc.parent_h_code ='000.'
    CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
    ORDER SIBLINGS BY ccc.CHILD_h_code
   ) LVL1 where cc_code is not null
   ),
  myproperties AS
   (
    SELECT
    ID                             ,
    REFERENCE_CODE                 ,
    CALCULATION_METHOD_ID          ,
    BASIS_PERCENT                  ,
    RECOVERABLE_PERCENT            ,
    START_DATE                     ,
    END_DATE                       ,
    ENTERED_BY                     ,
    ENTERED_DATE                   ,
    STATUS                         ,
    STATUS_MODIFIED_DATE           ,
    RID                            ,
    NKID                           ,
    NEXT_RID                       ,
    JURISDICTION_ID                ,
    JURISDICTION_NKID              ,
    ALL_TAXES_APPLY                ,
    RECOVERABLE_AMOUNT             ,
    APPLICABILITY_TYPE_ID          ,
    UNIT_OF_MEASURE                ,
    REF_RULE_ORDER                 ,
    DEFAULT_TAXABILITY             ,
    PRODUCT_TREE_ID                ,
    COMMODITY_ID                   ,
    TAX_TYPE                       ,
    IS_LOCAL                       ,
    EXEMPT                         ,
    NO_TAX                         ,
    COMMODITY_NKID                 ,
    CHARGE_TYPE_ID
    FROM juris_tax_applicabilities e
    where jurisdiction_nkid = lower_jnkid
    and default_taxability='D'
    -- 07/11 restrict is_local TEST
    and is_local = 'N'
    and next_rid is null
   )
    Select rr.*, pp.*,
    '' applythis
    BULK COLLECT INTO level1_array
    From mydata rr
    left join myproperties pp partition by (pp.nkid)
    on (pp.product_tree_id = rr.cc_product_tree_id)
    -- and (pp.ccid = rr.commodity_id)
    Order By c_id, parent_h_code, child_h_code;

    -- level1_array
    -- Apply top level to all blank parent_id records
    -- (Default taxability - all commodities)
   IF level1_array.count >0 then
     for ix1 in level1_array.first..level1_array.last loop
       if level1_array(ix1).parent_id is null then
        level1_array(ix1).ID                           := level1_array(1).id;
        level1_array(ix1).REFERENCE_CODE               := level1_array(1).REFERENCE_CODE;
        level1_array(ix1).CALCULATION_METHOD_ID        := level1_array(1).CALCULATION_METHOD_ID;
        level1_array(ix1).BASIS_PERCENT                := level1_array(1).BASIS_PERCENT        ;
        level1_array(ix1).RECOVERABLE_PERCENT          := level1_array(1).RECOVERABLE_PERCENT  ;
        level1_array(ix1).START_DATE                   := level1_array(1).START_DATE           ;
        level1_array(ix1).END_DATE                     := level1_array(1).END_DATE             ;
        level1_array(ix1).ENTERED_BY                   := level1_array(1).ENTERED_BY           ;
        level1_array(ix1).ENTERED_DATE                 := level1_array(1).ENTERED_DATE         ;
        level1_array(ix1).STATUS                       := level1_array(1).STATUS               ;
        level1_array(ix1).STATUS_MODIFIED_DATE         := level1_array(1).STATUS_MODIFIED_DATE ;
        level1_array(ix1).RID                          := level1_array(1).RID                  ;
        level1_array(ix1).NKID                         := level1_array(1).NKID                 ;
        level1_array(ix1).NEXT_RID                     := level1_array(1).NEXT_RID             ;
        level1_array(ix1).JURISDICTION_ID              := level1_array(1).JURISDICTION_ID      ;
        level1_array(ix1).JURISDICTION_NKID            := level1_array(1).JURISDICTION_NKID    ;
        level1_array(ix1).ALL_TAXES_APPLY              := level1_array(1).ALL_TAXES_APPLY      ;
        level1_array(ix1).RECOVERABLE_AMOUNT           := level1_array(1).RECOVERABLE_AMOUNT   ;
        level1_array(ix1).APPLICABILITY_TYPE_ID        := level1_array(1).APPLICABILITY_TYPE_ID;
        level1_array(ix1).UNIT_OF_MEASURE              := level1_array(1).UNIT_OF_MEASURE      ;
        level1_array(ix1).REF_RULE_ORDER               := level1_array(1).REF_RULE_ORDER       ;
        level1_array(ix1).DEFAULT_TAXABILITY           := level1_array(1).DEFAULT_TAXABILITY   ;
        level1_array(ix1).PRODUCT_TREE_ID              := level1_array(1).PRODUCT_TREE_ID      ;
        level1_array(ix1).COMMODITY_ID                 := level1_array(1).COMMODITY_ID         ;
        level1_array(ix1).TAX_TYPE                     := level1_array(1).TAX_TYPE             ;
        level1_array(ix1).IS_LOCAL                     := level1_array(1).IS_LOCAL             ;
        level1_array(ix1).EXEMPT                       := level1_array(1).EXEMPT               ;
        level1_array(ix1).NO_TAX                       := level1_array(1).NO_TAX               ;
        level1_array(ix1).COMMODITY_NKID               := level1_array(1).COMMODITY_NKID       ;
        level1_array(ix1).CHARGE_TYPE_ID               := level1_array(1).CHARGE_TYPE_ID       ;

       end if;

     end loop;

        -- DATA will show DEFAULT_TAXABILITY as IMPLICIT (there is no commodity)
        Start_time := DBMS_UTILITY.get_time;
        FORALL ii in level1_array.first..level1_array.last
        INSERT INTO impl_process_levels VALUES (processId, 1, 1, level1_array(ii).cc_commodity_id,
        level1_array(ii).id, level1_array(ii).reference_code, level1_array(ii).parent_id, '');
        end_time := DBMS_UTILITY.get_time;
        DBMS_OUTPUT.PUT_LINE('Bulk Insert: '||to_char(end_time-start_time));

        COMMIT;

      End If;

  End if;

/*
-- LEVEL 2
-- Here are the cascading rules from level above selected
-- NULLS must be replaced based on level, commodity_id and c_id (sort order)
*/

  IF lower_category<>3 THEN


   if upper_jnkid.count > 0 then
    For vii in upper_jnkid.first..upper_jnkid.last
    Loop

    -- orig
    WITH mydata AS
    (
    select LVL2.* from
    (SELECT distinct rownum c_id
    , LEVEL                ccc_level
    , Level                h_code_level
    --, sys_connect_by_path(ccc.name, '/') AS cpath
    --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
    , CommTree
    , connect_by_root child_h_code as ppc
    --, CONNECT_BY_ISLEAF ppca
    , ccc.parent_h_code
    , ccc.CHILD_h_code
    , PRIOR commodity_id parent_id
    , ccc.commodity_id    commodity_id
    , ccc.nkid            cc_nkid
    , ccc.commodity_code  cc_code
    , ccc.name            cc_name
    , ccc.product_tree_id cc_product_tree_id
    FROM commodities_pctree_build ccc
    Start with ccc.parent_h_code ='000.'
    CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
    ORDER SIBLINGS BY ccc.CHILD_h_code
    ) LVL2 where cc_code is not null
    ),
    myproperties AS
    (
    SELECT
    id,
    REFERENCE_CODE                 ,
    CALCULATION_METHOD_ID          ,
    BASIS_PERCENT                  ,
    DEFAULT_TAXABILITY             ,
    PRODUCT_TREE_ID                ,
    COMMODITY_ID ccid              ,
    start_date,
    1 applic_type,
    jurisdiction_nkid nkid,
    ref_rule_order
    FROM juris_tax_applicabilities e
    where jurisdiction_nkid = upper_jnkid(vii)
    and default_taxability is null and is_local= (case when lower_category<>3 then 'Y' else 'N' end)
    and next_rid is null
    ) , myhierarchy (commodity_id, parent_id, depth, parent_h_code, child_h_code, commtree, c_id, product_tree_id) AS --recursive
  (
   SELECT d.commodity_id, d.parent_id, 0, d.parent_h_code, d.child_h_code, d.commtree, d.c_id, d.cc_product_tree_id FROM mydata d
    )
    Select
    id,

    -- 7/31 test
    CASE WHEN lower_category=3 THEN decode(id,null,1,0) ELSE 1 END IMPL,

    COMMODITY_ID,
    parent_id,
    parent_h_code,
    commtree,
    decode(applythis,null,commodity_id,applythis) applythis,
    USE_START_DATE,
    start_date,
    LAST_VALUE(start_date IGNORE NULLS) over (partition by applythis) X1
    , c_id
    , reference_code

    ,Case When
      (CASE WHEN lower_category=3 THEN decode(id,null,1,0) ELSE 1 END)=1
       then fnlookupHcode(pCommodity=>applythis)
     Else '' end Source_H_Code

    bulk collect into level2_array
    from
    (Select rr.COMMODITY_ID, rr.parent_id, rr.parent_h_code, rr.commtree, rr.product_tree_id
    , LAST_VALUE(nvl(pp.ccid, parent_id) IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) ApplyThis
    , LAST_VALUE(pp.start_date IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) USE_START_DATE
    , start_date
    --, MIN(pp.ccid) KEEP (DENSE_RANK FIRST order BY NVL2(PARENT_H_CODE,1,2)) over (partition by parent_H_CODE) jta_parent_comm_id
    -- Taxability record LEVEL 2
    ,pp.id
    ,pp.REFERENCE_CODE
    ,pp.CALCULATION_METHOD_ID
    ,pp.BASIS_PERCENT
    ,pp.DEFAULT_TAXABILITY
    ,pp.PRODUCT_TREE_ID
    ,pp.ccid
    ,c_id
    From myhierarchy rr
    Left Join myproperties pp partition by (pp.nkid)
    On (pp.ccid = rr.commodity_id)
     Order By c_id, parent_h_code, child_h_code
    )
    Order By c_id, parent_h_code;

    -- Add level 2 (empty and filled mix)
    FORALL ii in level2_array.first..level2_array.last
    INSERT INTO impl_process_levels VALUES (processId, 2, level2_array(ii).impl, level2_array(ii).commodity_id,
    level2_array(ii).id, level2_array(ii).reference_code, level2_array(ii).applythis,
    level2_array(ii).source_h_code);

    End Loop;  -- Jurisdiction geo_area_category_id 3 loop

COMMIT;

  END IF;

 end if;

-- STATE LEVEL 2
--
/* if lower_category=3 then

    DBMS_OUTPUT.Put_Line( 'State selected' );

    WITH mydata AS
    (
    select LVL2.* from
    (SELECT distinct rownum c_id
    , LEVEL                ccc_level
    , Level                h_code_level
    --, sys_connect_by_path(ccc.name, '/') AS cpath
    --, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
    , CommTree
    , connect_by_root child_h_code as ppc
    --, CONNECT_BY_ISLEAF ppca
    , ccc.parent_h_code
    , ccc.CHILD_h_code
    , PRIOR commodity_id parent_id
    , ccc.commodity_id    commodity_id
    , ccc.nkid            cc_nkid
    , ccc.commodity_code  cc_code
    , ccc.name            cc_name
    , ccc.product_tree_id cc_product_tree_id
    FROM commodities_pctree_build ccc
    Start with ccc.parent_h_code ='000.'
    CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
    ORDER SIBLINGS BY ccc.CHILD_h_code
    ) LVL2 where cc_code is not null
    ),
    myproperties AS
    (
    SELECT
    id,
    REFERENCE_CODE                 ,
    CALCULATION_METHOD_ID          ,
    BASIS_PERCENT                  ,
    DEFAULT_TAXABILITY             ,
    PRODUCT_TREE_ID                ,
    COMMODITY_ID ccid              ,
    start_date,
    1 applic_type,
    jurisdiction_nkid nkid,
    ref_rule_order
    FROM juris_tax_applicabilities e
    where jurisdiction_nkid = lower_jnkid
    and default_taxability is null and is_local= (case when lower_category<>3 then 'Y' else 'N' end)
    and next_rid is null
    ) , myhierarchy (commodity_id, parent_id, depth, parent_h_code, child_h_code, commtree, c_id, product_tree_id) AS --recursive
    (
   SELECT d.commodity_id, d.parent_id, 0, d.parent_h_code, d.child_h_code, d.commtree, d.c_id, d.cc_product_tree_id FROM mydata d
   )
    Select
    id,
    decode(id,null,1,0) IMPL,
    COMMODITY_ID,
    parent_id,
    parent_h_code,
    commtree,
    decode(applythis,null,commodity_id,applythis) applythis,
    USE_START_DATE,
    start_date,
    LAST_VALUE(start_date IGNORE NULLS) over (partition by applythis) X1
    , c_id
    , reference_code
    bulk collect into level2_array
    from
    (Select rr.COMMODITY_ID, rr.parent_id, rr.parent_h_code, rr.commtree, rr.product_tree_id
    , LAST_VALUE(nvl(pp.ccid, parent_id) IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) ApplyThis
    , LAST_VALUE(pp.start_date IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) USE_START_DATE
    , start_date
    --, MIN(pp.ccid) KEEP (DENSE_RANK FIRST order BY NVL2(PARENT_H_CODE,1,2)) over (partition by parent_H_CODE) jta_parent_comm_id
    -- Taxability record LEVEL 2
    ,pp.id
    ,pp.REFERENCE_CODE
    ,pp.CALCULATION_METHOD_ID
    ,pp.BASIS_PERCENT
    ,pp.DEFAULT_TAXABILITY
    ,pp.PRODUCT_TREE_ID
    ,pp.ccid
    ,c_id
    From myhierarchy rr
    Left Join myproperties pp partition by (pp.nkid)
    On (pp.ccid = rr.commodity_id)
    Order By c_id, parent_h_code, child_h_code
    )
    Order By c_id, parent_h_code;

  -- Add level 2 (empty and filled mix)
  FORALL ii in level2_array.first..level2_array.last
   INSERT INTO impl_process_levels VALUES (processId, 2, level2_array(ii).impl, level2_array(ii).commodity_id,
   level2_array(ii).id, level2_array(ii).reference_code, level2_array(ii).applythis);

  END IF; -- State level end


20160729  */

  -- Update Level2 implicit lower level records with parent IDs
  -- Example
  --   Beverage 20350
  --    Soda    20350
  --      Carb1  20350

  FOR nn in (
  Select ll.commodity_id, cc.c_id from impl_process_levels ll
  join commodities_pctree_build cc on (cc.commodity_id = ll.commodity_id)
  Where ll.r_level=2
  And ll.process_id = processId and ll.juris_tax_applicability_id is null
  And ll.commodity_id <> ll.applyfromcomm order by c_id desc) LOOP

    FOR xx IN lvl2cur(nn.commodity_id, 2, processId) LOOP
       if xx.jta_id_existing is not null then

        Update impl_process_levels
        Set juris_tax_applicability_id = xx.jta_id_existing
        , source_h_code = xx.source_h_code
        Where commodity_id = nn.commodity_id
        And r_level = 2
        and impl = 1
        and process_id = processId
        and juris_tax_applicability_id is null;

       end if;

    END LOOP;

  END LOOP;
  Commit;


/*
|| Build Level 3
||
*/

WITH mydata AS
  (
 select LVL2.* from
(SELECT distinct rownum c_id
, LEVEL                ccc_level
, Level                h_code_level
--, sys_connect_by_path(ccc.name, '/') AS cpath
--, LPAD(' ',4 * (LEVEL-1) ) || ccc.cNAME CommTree
, CommTree
, connect_by_root child_h_code as ppc
--, CONNECT_BY_ISLEAF ppca
, ccc.parent_h_code
, ccc.CHILD_h_code
, PRIOR commodity_id parent_id
, ccc.commodity_id    commodity_id
, ccc.nkid            cc_nkid
, ccc.commodity_code  cc_code
, ccc.name            cc_name
, ccc.product_tree_id cc_product_tree_id
FROM commodities_pctree_build ccc
Start with ccc.parent_h_code ='000.'
CONNECT BY PRIOR ccc.child_h_code = ccc.parent_h_code
ORDER SIBLINGS BY ccc.CHILD_h_code
) LVL2 where cc_code is not null
  ),
myproperties AS
  (
SELECT
id,
REFERENCE_CODE                 ,
CALCULATION_METHOD_ID          ,
BASIS_PERCENT                  ,
DEFAULT_TAXABILITY             ,
PRODUCT_TREE_ID                ,
COMMODITY_ID ccid              ,
start_date,
1 applic_type,
jurisdiction_nkid nkid,
ref_rule_order
FROM juris_tax_applicabilities e
where jurisdiction_nkid = l_JurisdictionNkid
and next_rid is null
and is_local= 'N'
-- Do you want to see what applies to this Jurisdiction only or actually was created BY this Jurisdiction?
-- How would you create a cascading rule if they are not showing up?
--
) , myhierarchy (commodity_id, parent_id, depth, parent_h_code, child_h_code, commtree, c_id, product_tree_id) AS --recursive
  (
   SELECT d.commodity_id, d.parent_id, 0, d.parent_h_code, d.child_h_code, d.commtree, d.c_id, d.cc_product_tree_id FROM mydata d
   )
Select
id,
decode(id,null,1,0) IMPL,
COMMODITY_ID,
parent_id,
parent_h_code,
commtree,
decode(applythis,null,commodity_id,applythis) applythis,
USE_START_DATE,
start_date,
LAST_VALUE(start_date IGNORE NULLS) over (partition by applythis) X1
, c_id
, reference_code

    ,Case When decode(id,null,1,0)=1 then fnlookupHcode(pCommodity=>applythis)
     Else '' end Source_H_Code

bulk collect into level3_array
from
(Select rr.COMMODITY_ID, rr.parent_id, rr.parent_h_code, rr.commtree, rr.product_tree_id
, LAST_VALUE(nvl(pp.ccid, parent_id) IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) ApplyThis
, LAST_VALUE(pp.start_date IGNORE NULLS) over (partition by parent_id, ccid order by c_id ) USE_START_DATE
, start_date
--, MIN(pp.ccid) KEEP (DENSE_RANK FIRST order BY NVL2(PARENT_H_CODE,1,2)) over (partition by parent_H_CODE) jta_parent_comm_id
-- Taxability record LEVEL 2
,pp.id
,pp.REFERENCE_CODE
,pp.CALCULATION_METHOD_ID
,pp.BASIS_PERCENT
,pp.DEFAULT_TAXABILITY
,pp.PRODUCT_TREE_ID
,pp.ccid
,c_id
 From myhierarchy rr
 Left Join myproperties pp partition by (pp.nkid)
 On (pp.ccid = rr.commodity_id)
 Order By c_id, parent_h_code, child_h_code
)
Order By c_id, parent_h_code;

-- Add level 3 (empty and filled mix)
FORALL ii in level3_array.first..level3_array.last
 INSERT INTO impl_process_levels VALUES (processId, 3, level3_array(ii).impl, level3_array(ii).commodity_id,
 level3_array(ii).id, level3_array(ii).reference_code, level3_array(ii).applythis,
 level3_array(ii).source_h_code);

Commit;

-- Update Level3 implicit lower level records with parent IDs
-- Example
--   Beverage 20350
--    Soda    20350
--      Carb1  20350
-- Updated info in IMPL_PROCESS_LEVELS table
-- DISABLED TEMP: SOURCE_H_CODE TESTS LEVEL 3 - Implicit: Top level = FIRST_VALUE

FOR nn in (
  Select ll.commodity_id, cc.c_id, ll.impl from impl_process_levels ll
  join commodities_pctree_build cc on (cc.commodity_id = ll.commodity_id)
  Where ll.r_level=3
  And ll.process_id = processId
  -- 8/3
  -- AND ll.commodity_id = 859217
  -- and ll.juris_tax_applicability_id is null
  -- And ll.commodity_id <> ll.applyfromcomm
  order by c_id desc, ll.impl asc)

  LOOP
  FOR xx IN lvl2cur(nn.commodity_id, 3, processId) LOOP
    if xx.jta_id_existing is not null then

      -- Generate lookup test record DEV purposes only
      -- Insert Into impl_process_levels values(
      -- processId,3,1,nn.commodity_id,xx.jta_id,null,xx.commodity_id)


     if xx.jta_id_existing = xx.jta_id then

      Update impl_process_levels
      Set juris_tax_applicability_id = xx.jta_id_existing
        , source_h_code = xx.source_h_code
      Where commodity_id = nn.commodity_id
      And r_level=3
      and impl = 1
      and process_id=processId
      and juris_tax_applicability_id is null;

     else

instreeArray.extend;
instreeArray(instreeArray.last).process_Id := processId;
instreeArray(instreeArray.last).r_level := 3;
instreeArray(instreeArray.last).impl :=1;
instreeArray(instreeArray.last).commodity_id := nn.commodity_id;
instreeArray(instreeArray.last).juris_tax_applicability_id := xx.jta_id_existing;
instreeArray(instreeArray.last).applyfromcomm := xx.commodity_id;
instreeArray(instreeArray.last).source_h_code := xx.source_h_code;

     end if;

        end if;
  END LOOP;

END LOOP;

Commit;

FORALL ii in instreeArray.first..instreeArray.last
 INSERT INTO impl_process_levels VALUES (processId, 3, instreeArray(ii).impl, instreeArray(ii).commodity_id,
 instreeArray(ii).juris_tax_applicability_id, '', instreeArray(ii).applyfromcomm,
 instreeArray(ii).source_h_code);

Commit;

  -- CRAPP-3047
  EXCEPTION
  -- Explicit data error (no business logic exceptions defined)
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Error building Implicit taxability data');
    -- anything failed before commit points will be in the ERRLOG table

END IMPL_EXPL_BUILD;
/