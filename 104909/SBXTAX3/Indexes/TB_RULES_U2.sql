CREATE UNIQUE INDEX sbxtax3.tb_rules_u2 ON sbxtax3.tb_rules(merchant_id,authority_id,rule_order,start_date,NVL("IS_LOCAL",'N'))

TABLESPACE ositax;