CREATE OR REPLACE PROCEDURE content_repo."COMMODITY_TREE_BUILD" as
/*
|| Build Commodity tree based on Commodities and h_code
||
||
*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_process_id number;
Begin
 Insert Into COMMODITY_TREE_BUILD_LOG(job_start) values(sysdate)
 Returning process_id INTO l_process_id;
 -- l_process_id can be used for future notification
 -- Not developed in this version.

 --Execute immediate 'Truncate Table COMMODITIES_PCTREE Drop Storage';
 Delete from COMMODITIES_PCTREE;
 DBMS_OUTPUT.Put_Line( 'Build Commodity Parent Child Data' );

 -- Empty table: no constraints
 Insert Into COMMODITIES_PCTREE
 (SELECT
 id,
 rid,
 next_rid,
 nkid,
 product_tree_id,
 trim(h_code) h_code,
 trim(regexp_replace(h_code,
 '[^.]+.',' ',
 1,regexp_count(h_code,'[^.]+')) ) parent_h_code,
 trim(h_code) child_h_code,
 regexp_count(h_code,'[^.]+') level_id,
 name,
 description,
 commodity_code,
 entered_by,
 entered_date,
 status,
 status_modified_date,
 start_date,
 end_date
 FROM commodities
 where product_tree_id = 13 --njv only US
 and next_rid is null
 );

 Delete from Commodities_pctree_build;

 -- Build sibling tree to be used by Implicit/Explicit taxabilities
 Insert Into Commodities_pctree_build
 (select a.*,  rownum c_id
  from
  (SELECT distinct
  LEVEL ccc_level
  , level_id h_code_level
  --, sys_connect_by_path(ca.name, '/') AS cpath
  , LPAD(' ',4 * (LEVEL-1) ) || ca.NAME CommTree
  , NAME
  , CONNECT_BY_ISLEAF "Leaf"
  , ca.parent_h_code
  , ca.CHILD_h_code
  , ca.nkid
  , id commodity_id
  , ca.commodity_code
  , ca.product_tree_id
  FROM COMMODITIES_PCTREE ca
  where product_tree_id = 13
  Start with ca.parent_h_code = '000.'
  CONNECT BY PRIOR ca.child_h_code = ca.parent_h_code
  ORDER SIBLINGS BY ca.CHILD_h_code) a);

  Commit;

  -- CRAPP-3047
  EXCEPTION
  -- Unspecified error (no error codes specified for this error. The system oracle error will be reported)
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Building Commodity Tree failed.');


End COMMODITY_TREE_BUILD;
/