CREATE OR REPLACE PACKAGE content_repo."TAXABILITY_GRID" is
/*
|| Taxability Grid
||
||
*/
 -- Out table [taxability_search_v equivalent]
 Type T_TAXABILITY_TAB is Table Of IMPL_EXPL_XVIEW;
 TYPE jta_tab IS TABLE OF juris_tax_applicabilities%ROWTYPE;

 function getJurisTaxApplicability(pJurisdictionNkid in number) RETURN jta_tab PIPELINED;
 function setImpExp (pShow in number) return number;
 function setJTANKID(pJtaNkid in number) return number;
 function setProcessId(pProcessId in number) return number;
 /*
 || taxability_grid_t()
 ||
 || - output: taxability_search_v + additional fields
 ||           Implicit 0/1
 ||
 || - parameters
 || pImpExpl    => [0/1]
 || pJurisdictionNkid => [n]
 */
 Function FN_IMPLEXPL_XOUT(in_processId in number default null) return impl_expl_xtable pipelined;
 function taxability_grid_t(pJurisdictionNkid in number default null,
                            pImpExpl in number default null) return T_TAXABILITY_TAB pipelined;


End TAXABILITY_GRID;
/