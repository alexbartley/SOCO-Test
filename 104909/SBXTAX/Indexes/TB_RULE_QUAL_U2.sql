CREATE UNIQUE INDEX sbxtax.tb_rule_qual_u2 ON sbxtax.tb_rule_qualifiers(rule_id,rule_qualifier_type,start_date,"ELEMENT","OPERATOR","VALUE",authority_id,reference_list_id)

TABLESPACE ositax;