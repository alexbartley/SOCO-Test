CREATE OR REPLACE FUNCTION content_repo."JTA_PIPED_TXAPP" (jtaRid in number) return varchar2
is
  l_data   varchar2(32000);
begin

with jta_taxes as
( select jta.reference_code||'|'||jta.invoice_statement||'|'||to_char(jta.start_date)||'|'||to_char(jta.end_date)||'|'||jta.ref_rule_order||'|'||jta.tax_type_id
 taxappl
  from
  -- VAPPL_TAX_APPL_MIN jta
  vappl_tax_appl_inv jta
  where jta.juris_tax_applicability_rid = jtaRid
)
select listagg( taxappl, chr(13) )
                  within group (order by 1)
into l_data
from jta_taxes;

/*
select
listagg( jti.reference_code||'|'||nvl(tot1.short_text, tot2.short_text)||'|'||to_char(nvl(jta.start_date, jta.end_date))||'|'||to_char(nvl(tat.end_date, jta.end_date))||'|'||nvl(tat.ref_rule_order, jta.ref_rule_order)||'|'||tat.tax_type_id
        , chr(13) ) within group ( order by 1 )
into l_data
FROM juris_tax_app_revisions jtr
        JOIN juris_tax_applicabilities jta -- crapp-2662/2263, added CASE to handle Exempt and Taxable Applicable Taxes
        ON (JTR.NKID = JTA.NKID and
            rev_join (jta.rid, jtr.id, COALESCE (jta.next_rid, 999999999)) = 1
            )
        LEFT JOIN tax_applicability_taxes tat ON (rev_join (tat.rid, jtr.id, COALESCE (tat.next_rid, 999999999)) = 1
                                                 AND jta.nkid = tat.juris_tax_applicability_nkid)
        LEFT JOIN juris_tax_impositions jti ON (jti.id = tat.juris_tax_imposition_id)          -- added 05/12/16
        LEFT JOIN taxability_outputs tot1 ON ( tat.nkid = tot1.tax_applicability_tax_nkid AND jti.id IS NOT NULL     -- Added this to fix CRAPP-2682
                                               AND rev_join(tot1.rid, jtr.id, COALESCE (tot1.next_rid, 9999999999)) = 1
                                             )
        LEFT JOIN taxability_outputs tot2 ON ( jta.nkid = tot2.juris_tax_applicability_nkid AND jti.id IS NULL
                                               AND rev_join(tot2.rid, jtr.id, COALESCE (tot2.next_rid, 9999999999)) = 1
                                             )
where jtr.id = jtaRid;
*/
return l_data;

end jta_piped_txapp;
/