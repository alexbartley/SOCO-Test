CREATE UNIQUE INDEX sbxtax4.tb_rules_u2 ON sbxtax4.tb_rules(merchant_id,authority_id,rule_order,start_date,NVL("IS_LOCAL",'N'))

TABLESPACE ositax;