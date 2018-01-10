CREATE OR REPLACE FORCE VIEW sbxtax.datax_tb_product_cat_vw (data_check_id,reviewed_approved,verified,record_key,product_group,product_name,commodity_code,product_1_name,product_2_name,product_3_name,product_4_name,product_5_name,product_6_name,product_7_name,product_8_name,product_9_name,primary_key,approved_date) AS
SELECT c.data_check_id, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'), 'Name='||pc.name||'| ProductGroupName='||pg.name||'| CommodityCode='||NVL(pc.prodcode,'null') record_key, pg.name product_group, pc.name product_name, pc.prodcode commodity_Code, product_1_name, product_2_name, product_3_name, product_4_name, product_5_name, product_6_name, product_7_name, product_8_name, product_9_name, o.primary_key, o.approved_date
FROM datax_check_output o
JOIN datax_checks c ON (c.data_Check_id = o.data_Check_id and c.data_owner_table = 'TB_PRODUCT_CATEGORIES')
JOIN ct_product_tree pt ON (pt.primary_key = o.primary_key)
JOIN tb_product_categories pc ON (pt.primary_key = pc.product_category_id)
JOIN tb_product_groups pg ON (pg.product_Group_id = pc.product_Group_id)
ORDER BY NVL(o.approved_Date,'31-DEC-9999') DESC
 
 
 ;