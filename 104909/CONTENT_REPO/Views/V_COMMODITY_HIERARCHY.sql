CREATE OR REPLACE FORCE VIEW content_repo.v_commodity_hierarchy (product_tree_id,"NAME",commodity_code,h_code,product_1_name,product_2_name,product_3_name,product_4_name,product_5_name,product_6_name,product_7_name,product_8_name,product_9_name,product_10_name) AS
select product_Tree_id, name, commodity_code, h_code, c.name product_1_name, null product_2_name, null product_3_name,
    null product_4_name, null product_5_name, null product_6_name, null product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
where length(h_code) = 4
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c1.name product_1_name, c.name product_2_name, null product_3_name,
    null product_4_name, null product_5_name, null product_6_name, null product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 4 and substr(c.h_code,1,4) = c1.h_code and c1.product_tree_id = c.product_tree_id)
where length(c.h_code) = 8
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c2.name product_1_name, c1.name product_2_name, c.name product_3_name,
    null product_4_name, null product_5_name, null product_6_name, null product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 8 and substr(c.h_code,1,8) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 4 and substr(c1.h_code,1,4) = c2.h_code and c2.product_tree_id = c.product_tree_id)
where length(c.h_code) = 12
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c3.name product_1_name, c2.name product_2_name, c1.name product_3_name,
    c.name product_4_name, null product_5_name, null product_6_name, null product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 12 and substr(c.h_code,1,12) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 8 and substr(c1.h_code,1,8) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 4 and substr(c2.h_code,1,4) = c3.h_code and c3.product_tree_id = c.product_tree_id)
where length(c.h_code) = 16
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c4.name product_1_name, c3.name product_2_name, c2.name product_3_name,
    c1.name product_4_name, c.name product_5_name, null product_6_name, null product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 16 and substr(c.h_code,1,16) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 12 and substr(c1.h_code,1,12) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 8 and substr(c2.h_code,1,8) = c3.h_code and c3.product_tree_id = c.product_tree_id)
join commodities c4 on (length(c4.h_code) = 4 and substr(c3.h_code,1,4) = c4.h_code and c4.product_tree_id = c.product_tree_id)
where length(c.h_code) = 20
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c5.name product_1_name, c4.name product_2_name, c3.name product_3_name,
    c2.name product_4_name, c1.name product_5_name, c.name product_6_name, null product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 20 and substr(c.h_code,1,20) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 16 and substr(c1.h_code,1,16) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 12 and substr(c2.h_code,1,12) = c3.h_code and c3.product_tree_id = c.product_tree_id)
join commodities c4 on (length(c4.h_code) = 8 and substr(c3.h_code,1,8) = c4.h_code and c4.product_tree_id = c.product_tree_id)
join commodities c5 on (length(c5.h_code) = 4 and substr(c4.h_code,1,4) = c5.h_code and c5.product_tree_id = c.product_tree_id)
where length(c.h_code) = 24
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c6.name product_1_name, c5.name product_2_name, c4.name product_3_name,
    c3.name product_4_name, c2.name product_5_name, c1.name product_6_name, c.name product_7_name, null product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 24 and substr(c.h_code,1,24) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 20 and substr(c1.h_code,1,20) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 16 and substr(c2.h_code,1,16) = c3.h_code and c3.product_tree_id = c.product_tree_id)
join commodities c4 on (length(c4.h_code) = 12 and substr(c3.h_code,1,12) = c4.h_code and c4.product_tree_id = c.product_tree_id)
join commodities c5 on (length(c5.h_code) = 8 and substr(c4.h_code,1,8) = c5.h_code and c5.product_tree_id = c.product_tree_id)
join commodities c6 on (length(c6.h_code) = 4 and substr(c5.h_code,1,4) = c6.h_code and c6.product_tree_id = c.product_tree_id)
where length(c.h_code) = 28
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c7.name product_1_name, c6.name product_2_name, c5.name product_3_name,
    c4.name product_4_name, c3.name product_5_name, c2.name product_6_name, c1.name product_7_name, c.name  product_8_name, null product_9_name, null product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 28 and substr(c.h_code,1,28) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 24 and substr(c1.h_code,1,24) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 20 and substr(c2.h_code,1,20) = c3.h_code and c3.product_tree_id = c.product_tree_id)
join commodities c4 on (length(c4.h_code) = 16 and substr(c3.h_code,1,16) = c4.h_code and c4.product_tree_id = c.product_tree_id)
join commodities c5 on (length(c5.h_code) = 12 and substr(c4.h_code,1,12) = c5.h_code and c5.product_tree_id = c.product_tree_id)
join commodities c6 on (length(c6.h_code) = 8 and substr(c5.h_code,1,8) = c6.h_code and c6.product_tree_id = c.product_tree_id)
join commodities c7 on (length(c7.h_code) = 4 and substr(c6.h_code,1,4) = c7.h_code and c7.product_tree_id = c.product_tree_id)
where length(c.h_code) = 32
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c8.name product_1_name, c7.name product_2_name, c6.name product_3_name,
    c5.name product_4_name, c4.name product_5_name, c3.name product_6_name, c2.name product_7_name, c1.name  product_8_name, c.name product_9_name, null
from commodities c
join commodities c1 on (length(c1.h_code) = 32 and substr(c.h_code,1,32) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 28 and substr(c1.h_code,1,28) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 24 and substr(c2.h_code,1,24) = c3.h_code and c3.product_tree_id = c.product_tree_id)
join commodities c4 on (length(c4.h_code) = 20 and substr(c3.h_code,1,20) = c4.h_code and c4.product_tree_id = c.product_tree_id)
join commodities c5 on (length(c5.h_code) = 16 and substr(c4.h_code,1,16) = c5.h_code and c5.product_tree_id = c.product_tree_id)
join commodities c6 on (length(c6.h_code) = 12 and substr(c5.h_code,1,12) = c6.h_code and c6.product_tree_id = c.product_tree_id)
join commodities c7 on (length(c7.h_code) = 8 and substr(c6.h_code,1,8) = c7.h_code and c7.product_tree_id = c.product_tree_id)
join commodities c8 on (length(c8.h_code) = 4 and substr(c7.h_code,1,4) = c8.h_code and c8.product_tree_id = c.product_tree_id)
where length(c.h_code) = 36
union
select c.product_Tree_id, c.name, c.commodity_code, c.h_code, c9.name product_1_name, c8.name product_2_name, c7.name product_3_name,
    c6.name product_4_name, c5.name product_5_name, c4.name product_6_name, c3.name product_7_name, c2.name  product_8_name, c1.name product_9_name, c.name product_10_name
from commodities c
join commodities c1 on (length(c1.h_code) = 36 and substr(c.h_code,1,36) = c1.h_code and c1.product_tree_id = c.product_tree_id)
join commodities c2 on (length(c2.h_code) = 32 and substr(c1.h_code,1,32) = c2.h_code and c2.product_tree_id = c.product_tree_id)
join commodities c3 on (length(c3.h_code) = 28 and substr(c2.h_code,1,28) = c3.h_code and c3.product_tree_id = c.product_tree_id)
join commodities c4 on (length(c4.h_code) = 24 and substr(c3.h_code,1,24) = c4.h_code and c4.product_tree_id = c.product_tree_id)
join commodities c5 on (length(c5.h_code) = 20 and substr(c4.h_code,1,20) = c5.h_code and c5.product_tree_id = c.product_tree_id)
join commodities c6 on (length(c6.h_code) = 16 and substr(c5.h_code,1,16) = c6.h_code and c6.product_tree_id = c.product_tree_id)
join commodities c7 on (length(c7.h_code) = 12 and substr(c6.h_code,1,12) = c7.h_code and c7.product_tree_id = c.product_tree_id)
join commodities c8 on (length(c8.h_code) = 8 and substr(c7.h_code,1,8) = c8.h_code and c8.product_tree_id = c.product_tree_id)
join commodities c9 on (length(c9.h_code) = 4 and substr(c8.h_code,1,4) = c9.h_code and c9.product_tree_id = c.product_tree_id)
where length(c.h_code) = 40
 
 ;