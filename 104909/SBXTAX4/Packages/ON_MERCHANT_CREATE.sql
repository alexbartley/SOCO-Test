CREATE OR REPLACE PACKAGE sbxtax4."ON_MERCHANT_CREATE" AS

procedure CCH_MERCHANTS;

cursor authorityLogicGroups(merchantId number) is
select *
  from tb_authority_logic_groups
 where merchant_id = merchantId;

cursor authorityTypes(merchantId number) is
select *
  from tb_authority_types
 where merchant_id = merchantId;

cursor merchant is
select name, merchant_id, created_by
  from tb_merchants
 order by creation_date desc;

AUTHORITY_LOGIC_GROUPS          varchar2(30) := 'TB_AUTHORITY_LOGIC_GROUPS';
AUTHORITY_TYPES                 varchar2(30) := 'TB_AUTHORITY_TYPES';
COUNTRY                         varchar2(30) := 'Country';
UNITED_STATES                   varchar2(13) := 'UNITED STATES';
ZONES                           varchar2(30) := 'TB_ZONES';

end ON_MERCHANT_CREATE;



 
 
 
/