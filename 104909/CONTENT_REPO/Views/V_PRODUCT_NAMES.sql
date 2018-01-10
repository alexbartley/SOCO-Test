CREATE OR REPLACE FORCE VIEW content_repo.v_product_names (tel_prod_cat_id,tel_name,tel_prodcode,tel_product_name,stan_prod_cat_id,stan_name,stan_prodcode,stan_product_name) AS
select distinct a.product_category_id tel_prod_cat_id, a.name tel_name,  a.prodcode tel_prodcode, a.name||'||'||a.prodcode tel_product_name,
       b.product_category_id stan_prod_cat_id, b.name stan_name,  b.prodcode stan_prodcode, b.name||'||'||b.prodcode stan_product_name
 from sbxtax4.tb_product_categories a left join sbxtax.tb_product_categories b
 on ( a.name||'||'||a.prodcode = b.name||'||'||b.prodcode and a.merchant_id = b.merchant_id ) 
 where a.merchant_id = 2;