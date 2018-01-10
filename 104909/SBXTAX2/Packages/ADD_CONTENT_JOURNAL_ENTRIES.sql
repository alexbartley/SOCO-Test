CREATE OR REPLACE package sbxtax2.add_content_journal_entries
as
/*
$Header:add_content_journal_entries.pk.cr.sql, 20, 5/3/2004 11:30:06 AM, Jim Barta$
*/
procedure make_content_journal_entry (p_table varchar2
                                     ,p_primary_key number
                                     ,p_operation varchar2
                                     ,p_unique_id varchar2
                                     ,p_merchant_id number default null
                                     );

procedure p_MERCHANTS (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_MERCHANTS%rowtype);

procedure p_AUTHORITY_LOGIC_ELEMENTS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_LOGIC_ELEMENTS%rowtype);

procedure p_AUTHORITY_LOGIC_GROUPS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_LOGIC_GROUPS%rowtype);

procedure p_AUTHORITY_LOGIC_GROUP_XREF (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_LOGIC_GROUP_XREF%rowtype);

procedure p_AUTHORITY_REQUIREMENTS (p_operation varchar2
                                   ,p_key number
                                   ,p_merchant_id number
                                   ,p_old TB_AUTHORITY_REQUIREMENTS%rowtype);

procedure p_AUTHORITY_TYPES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_AUTHORITY_TYPES%rowtype);

procedure p_AUTHORITIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_AUTHORITIES%rowtype);

procedure p_RATES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_RATES%rowtype);

procedure p_RATE_TIERS (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_RATE_TIERS%rowtype);

procedure p_RULES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_RULES%rowtype);

procedure p_ZONES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_ZONES%rowtype);

procedure p_ZONE_AUTHORITIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_ZONE_AUTHORITIES%rowtype);


procedure p_PRODUCT_CATEGORIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_CATEGORIES%rowtype);

procedure p_PRODUCT_ZONES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_ZONES%rowtype);

procedure p_PRODUCT_AUTHORITY_TYPES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_AUTHORITY_TYPES%rowtype);

procedure p_PRODUCT_AUTHORITIES (p_operation varchar2
                       ,p_key number
                       ,p_merchant_id number
                       ,p_old TB_PRODUCT_AUTHORITIES%rowtype);
                       
procedure p_APP_ERRORS (p_operation varchar2
               ,p_key number
               ,p_merchant_id number
               ,p_old TB_APP_ERRORS%rowtype);

procedure p_ZONE_MATCH_PATTERNS (p_operation varchar2
               ,p_key number
               ,p_merchant_id number
               ,p_old TB_ZONE_MATCH_PATTERNS%rowtype);
               
procedure p_ZONE_MATCH_CONTEXTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_ZONE_MATCH_CONTEXTS%rowtype);
               
procedure p_CONTRIBUTING_AUTHORITIES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_CONTRIBUTING_AUTHORITIES%rowtype);

procedure p_DELIVERY_TERMS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_DELIVERY_TERMS%rowtype);

procedure p_DATE_DETERMINATION_LOGIC (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_DATE_DETERMINATION_LOGIC%rowtype);
               

procedure p_DATE_DETERMINATION_RULES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_DATE_DETERMINATION_RULES%rowtype);
           
procedure p_RULE_QUALIFIERS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_RULE_QUALIFIERS%rowtype);
               
procedure p_AUTHORITY_MATERIAL_SETS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_AUTHORITY_MATERIAL_SETS%rowtype);        
               
procedure p_AUTHORITY_RATE_SET_RATES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_AUTHORITY_RATE_SET_RATES%rowtype);              
procedure p_AUTHORITY_RATE_SETS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_AUTHORITY_RATE_SETS%rowtype);

procedure p_MATERIAL_SET_LIST_PRODUCTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_MATERIAL_SET_LIST_PRODUCTS%rowtype);

procedure p_MATERIAL_SET_LISTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_MATERIAL_SET_LISTS%rowtype);

procedure p_MATERIAL_SETS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_MATERIAL_SETS%rowtype);

procedure p_REFERENCE_LISTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_REFERENCE_LISTS%rowtype);

procedure p_REFERENCE_VALUES (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_REFERENCE_VALUES%rowtype);

procedure p_RULE_OUTPUTS (p_operation varchar2
                   ,p_key number
                   ,p_merchant_id number
               ,p_old TB_RULE_OUTPUTS%rowtype);

PROCEDURE p_COMPLIANCE_AREAS ( p_operation VARCHAR2
                              ,p_key NUMBER
                              ,p_merchant_id NUMBER
                              ,p_old TB_COMPLIANCE_AREAS%ROWTYPE
                             );

PROCEDURE p_COMP_AREA_AUTHORITIES ( p_operation VARCHAR2
                                   ,p_key NUMBER
                                   ,p_merchant_id NUMBER
                                   ,p_old TB_COMP_AREA_AUTHORITIES%ROWTYPE
                                  );

end add_content_journal_entries;
/