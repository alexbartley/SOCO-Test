CREATE OR REPLACE TYPE content_repo.xc_commodity_ob AS OBJECT(
 c_level number
,h_code_level number
,commodity_name varchar2(500)
,start_date date
,end_date date
,parent_h_code varchar2(128)
,CHILD_h_code varchar2(128)
,nkid number
,commodity_id number
,commodity_code varchar2(128)
,product_tree_id number
,status_modified_date date
,status varchar2(10)
);
/