CREATE UNIQUE INDEX sbxtax.tb_prod_xref_u2 ON sbxtax.tb_product_cross_ref(product_cross_ref_group_id,source_product_code,product_category_id,start_date)

TABLESPACE ositax;