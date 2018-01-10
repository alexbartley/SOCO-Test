CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_prod_cats (result_type,product_category_id,nkid,product_group,prodcode,"NAME",description,product_1_name,product_2_name,product_3_name,product_4_name,product_5_name,product_6_name,product_7_name,product_8_name,product_9_name,product_10_name) AS
select case when pp.product_category_id is null then 'add' else 'update' end result_type,
    pp.product_category_id, pp.nkid, pg.name product_group,pp.prodcode, pp.name, pp.description, product_1_name, product_2_name, product_3_name, product_4_name, product_5_name, product_6_name, product_7_name,
    product_8_name, product_9_name, product_10_name
from pvw_tb_product_categories pp
join tb_product_groups pg on (pg.product_group_id = pp.product_group_id)
join tmp_ct_product_Tree pt on (pt.product_tree = pg.name and pp.nkid = pt.nkid)
 
 ;