CREATE INDEX sbxtax.tdr_etl_rule_products_n3 ON sbxtax.tdr_etl_rule_products(authority_uuid,hierarchy_level,no_tax,"EXEMPT",rate_code)
TABLESPACE ositax;