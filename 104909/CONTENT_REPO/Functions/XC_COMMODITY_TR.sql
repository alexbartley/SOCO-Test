CREATE OR REPLACE Function content_repo.xc_commodity_tr(pHcode in varchar2 default '000.') 
return xc_Commodity_TT pipelined is
Cursor crsC(pHcode varchar2) is
with sx1 as
(
SELECT
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
 where product_tree_id = 13 
 and next_rid is null
 )
,sx2 as   
(  
SELECT distinct
  LEVEL c_level
  , level_id h_code_level
  , LPAD(' ',4 * (LEVEL-1) ) || ca.NAME commodity_name
,ca.start_date
,ca.end_date
  , ca.parent_h_code
  , ca.CHILD_h_code
  , ca.nkid
  , id commodity_id
  , ca.commodity_code
  , ca.product_tree_id
  , ca.status_modified_date
  , decode(ca.status,0,'Pending',1,'Locked',2,'Published',3,'Deprecated','---') status
  FROM sx1 ca
  where product_tree_id = 13
  Start with ca.parent_h_code = pHCode
  CONNECT BY PRIOR ca.child_h_code = ca.parent_h_code
  ORDER SIBLINGS BY ca.CHILD_h_code
)
select * from sx2;

begin

  for r_row in crsC(pHCode)
  loop
    pipe row(xc_commodity_ob(
     r_row.c_level
,r_row.h_code_level 
,r_row.commodity_name 
,r_row.start_date 
,r_row.end_date 
,r_row.parent_h_code 
,r_row.CHILD_h_code 
,r_row.nkid 
,r_row.commodity_id 
,r_row.commodity_code 
,r_row.product_tree_id 
,r_row.status_modified_date 
,r_row.status ));
  end loop;
end xc_commodity_tr;
/