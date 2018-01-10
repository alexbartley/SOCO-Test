CREATE OR REPLACE PACKAGE BODY sbxtax."ON_MERCHANT_CREATE" AS

function getWorldZoneId(merchantId number) return number is
  zoneId number;
begin
  select zone_id
    into zoneId
    from tb_zones
   where merchant_id = merchantId
     and name = 'WORLD';

  return zoneId;
  exception
    when no_data_found then
      raise;
end getWorldZoneId;

function getZoneLevelId(level varchar2) return number is
  zoneLevelId number;
begin
  select zone_level_id
    into zoneLevelId
    from tb_zone_levels
   where name = level;

  return zoneLevelId;
  exception
    when no_data_found then
      raise;
end getZoneLevelId;

function getNextPrimaryKeyValue (tableName varchar2) return number is
  pk number;
begin
  select value
    into pk
    from tb_counters
   where name = tableName;

  return pk;
exception
  when no_data_found then
    raise;
end getNextPrimaryKeyValue;

procedure setPrimaryKeyValue (tableName varchar2, pk number) is
begin
  update tb_counters
     set value = pk
   where name = tableName;
exception
  when others then
    raise;
end setPrimaryKeyValue;

function getCchSourceMerchant return number is
  merchantId number;
begin
  select merchant_id
    into merchantId
    from tb_merchants
   where name = 'CCH US Tax Data';

  return merchantId;
exception
  when no_data_found then
    raise;
end getCchSourceMerchant;

procedure CCH_MERCHANTS is
  merchantName varchar2(100);
  pk           number;
  parentZoneId number;
  zoneLevelId  number;
  merchantId   number;
  userId       number;
begin
  dbms_output.put_line('in cch_merchants');
  for rec in merchant loop
    merchantName := rec.name;
    merchantId := rec.merchant_id;
    userId := rec.created_by;
    exit;
  end loop;

  if merchantName like 'CCH%' then
  --+
  --  Create UNITED STATES zone under this merchants World zone.
  --  Get next pk value and increament tb_counters.
  ---
  pk := getNextPrimaryKeyValue(ZONES);
  parentZoneId := getWorldZoneId(merchantId);
  zoneLevelId := getZoneLevelId(COUNTRY);
  insert into tb_zones(zone_id, name, parent_zone_id, merchant_id, zone_level_id, reverse_flag
       , terminator_flag, default_flag, created_by, creation_date, last_updated_by, last_update_date)
  values (pk, UNITED_STATES, parentZoneId, merchantId, zoneLevelId, 'N','N','N', userId, sysdate, userId, sysdate);
  setPrimaryKeyValue(ZONES, pk + 1);

  --+
  --  Copy CCH Tax Data authority types to this merchant.
  ---
  pk := getNextPrimaryKeyValue(AUTHORITY_TYPES);
  for rec in authorityTypes(getCchSourceMerchant) loop
    insert into tb_authority_types( authority_type_id, merchant_id, name, description
         , created_by, creation_date, last_updated_by, last_update_date)
    values(pk, merchantId, rec.name, rec.description, userId, sysdate, userId, sysdate);
    pk := pk + 1;
  end loop;
  setPrimaryKeyValue(AUTHORITY_TYPES, pk + 1);

  --+
  --  Copy CCH Tax Data authority logic groups to this merchant.
  ---
  pk := getNextPrimaryKeyValue(AUTHORITY_LOGIC_GROUPS);
  for rec in authorityLogicGroups(getCchSourceMerchant) loop
    insert into tb_authority_logic_groups( authority_logic_group_id, merchant_id, name
         , created_by, creation_date, last_updated_by, last_update_date)
    values(pk, merchantId, rec.name, userId, sysdate, userId, sysdate);
    pk := pk + 1;
  end loop;
  setPrimaryKeyValue(AUTHORITY_LOGIC_GROUPS, pk + 1);

  end if;
  exception
    when no_data_found then
      raise;
end CCH_MERCHANTS;

end ON_MERCHANT_CREATE;
/