CREATE OR REPLACE PROCEDURE sbxtax4."RESET_IDS" 
is
    cursor authorities is
    select authority_id
    from tb_authorities
    where authority_id > 2000000000;
    
    cursor rates is
    select rate_id
    from tb_rates
    where rate_id > 2000000000;
    
    cursor trules is
    select rule_id
    from tb_rules
    where rule_id > 2000000000;
    
    cursor zones is
    select zone_id
    from tb_zones
    where zone_id > 2000000000;
    
    cursor zone_authorities is
    select zone_authority_id
    from tb_zone_authorities
    where zone_authority_id > 2000000000;
    
    cursor rate_tiers is
    select rate_tier_id
    from tb_rate_tiers
    where rate_tier_id > 2000000000;
    
    
    cursor rule_qualifiers is
    select rule_qualifier_id
    from tb_rule_qualifiers
    where rule_qualifier_id > 2000000000;

    newRateId number := 64210458;
    newRuleId number:= 655520332;
    newRateTierId  number := 22573;
    newZoneId number:= 14108186;
    newZoneAuthId  number := 581154;
    newAuthId  number := 250672;
    newRuleQId number;
begin


select max(rate_id)
into newRateId
from tb_rates
where rate_id < 2000000000;
                         
select max(rate_tier_id)
into newRateTierId
from tb_rate_tiers
where rate_tier_id < 2000000000;
                                                   
select max(rule_id)
into newRuleId
from tb_rules
where rule_id < 2000000000;

select max(rule_qualifier_id)
into newRuleQId
from tb_rule_qualifiers
where rule_qualifier_id < 2000000000;


select max(zone_authority_id)
into newZoneAuthId
from tb_zone_authorities
where zone_authority_id < 2000000000;

select max(zone_id)
into newZoneId
from tb_zones
where zone_id < 2000000000;

select max(authority_id)
into newAuthId
from tb_authorities
where authority_id < 2000000000;

    
    
 

    --update Rate_ID's
    execute immediate 'alter trigger dt_rates disable';
    execute immediate 'alter trigger dt_rate_tiers disable';
    for r in rates loop
        newRateId := newRateId+1;
        --update rates table
        update tb_rates
        set rate_id = newRateId
        where rate_id = r.rate_id;
        --update rate references in content_journal
        update tb_content_journal
        set primary_key = newRateId
        where table_name = 'TB_RATES'
        and primary_key = r.rate_id;
        --update rate references in datax_check_output
        update datax_check_output o
        set primary_key = newRateId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_RATES'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = r.rate_id;
        --update rate tier references
        update tb_rate_tiers
        set rate_id = newRateId
        where rate_id = r.rate_id;
        --update rate tier references in content_journal
        update tb_content_journal
        set unique_id_xml = replace(unique_id_xml,'RATE_ID="'||r.rate_id||'"','RATE_ID="'||newRateId||'"')
        where table_name = 'TB_RATE_TIERS'
        and primary_key = r.rate_id;
    end loop;
    commit;
    execute immediate 'alter trigger dt_rates enable';
    --update Rate_Tier_ID's
    for rt in rate_tiers loop
        newRateTierId := newRateTierId+1;
        --update rate tiers table
        update tb_rate_tiers
        set rate_tier_id = newRateTierId
        where rate_tier_id = rt.rate_tier_id;
        --update rate tier references in content_journal
        update tb_content_journal
        set primary_key = newRateTierId
        where table_name = 'TB_RATE_TIERS'
        and primary_key = rt.rate_tier_id;
        --update rate references in datax_check_output
        update datax_check_output o
        set primary_key = newRateTierId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_RATE_TIERS'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = rt.rate_tier_id;
    end loop;
    commit;
    execute immediate 'alter trigger dt_rate_tiers enable';
    execute immediate 'alter trigger dt_rules disable';
    execute immediate 'alter trigger dt_rule_qualifiers disable';  
    --update Rule_Qualifier's
    for rt in Rule_Qualifiers loop
        newRuleQId := newRuleQId+1;
        --update rate tiers table
        update tb_Rule_Qualifiers
        set rule_qualifier_id = newRuleQId
        where rule_qualifier_id = rt.rule_qualifier_id;
        --update rate tier references in content_journal
        update tb_content_journal
        set primary_key = newRuleQId
        where table_name = 'TB_RULE_QUALIFIERS'
        and primary_key = rt.rule_qualifier_id;
        --update rate references in datax_check_output
        update datax_check_output o
        set primary_key = newRuleQId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_RULE_QUALIFIERS'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = rt.rule_qualifier_id;
    end loop;
    commit;
    --Update Rule_ID's
    for tr in trules loop
        newRuleId := newRuleId+1;
        --update rules table
        update tb_rules
        set rule_id = newRuleId
        where rule_id = tr.rule_id;
        --update rule qualifier references
        update tb_rule_qualifiers
        set rule_id = newRuleId
        where rule_id = tr.rule_id;
        --update rule references in content_journal
        update tb_content_journal
        set primary_key = newRuleId
        where table_name = 'TB_RULES'
        and primary_key = tr.rule_id;
        --update rule qualifier references in content_journal
        update tb_content_journal
        set unique_id_xml = replace(unique_id_xml,'RULE_ID="'||tr.rule_id||'"','RULE_ID="'||newRuleId||'"')
        where table_name = 'TB_RULE_QUALIFIERS'
        and primary_key = tr.rule_id;
        --update rule references in datax_check_output
        update datax_check_output o
        set primary_key = newRuleId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_RULES'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = tr.rule_id;
    end loop;
    commit;
    execute immediate 'alter trigger dt_authorities disable';
    --Update Authority_ID's
    for a in authorities loop
        newAuthId := newAuthId+1;
        --update authorities table
        update tb_authorities
        set authority_id = newAuthId
        where authority_id = a.authority_id;
        --update rate references
        update tb_rates
        set authority_id = newAuthId
        where authority_id = a.authority_id;  
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_RATES'
        and exists (
            select 1
            from tb_rates r
            where r.authority_id = a.authority_id
            and r.rate_id = cj.primary_key
            )
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';   
        --update rule references
        update tb_rules
        set authority_id = newAuthId
        where authority_id = a.authority_id;  
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_RULES'
        and exists (
            select 1
            from tb_rules r
            where r.authority_id = a.authority_id
            and r.rule_id = cj.primary_key)
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';   
        --update zone authority references
        update tb_zone_authorities
        set authority_id = newAuthId
        where authority_id = a.authority_id;  
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_ZONE_AUTHORITIES'
        and exists (
            select 1
            from TB_ZONE_AUTHORITIES r
            where r.authority_id = a.authority_id
            and r.zone_authority_id = cj.primary_key)
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';      
        --update rule qualifier references
        update tb_rule_qualifiers
        set authority_id = newAuthId
        where authority_id is not null
        and authority_id = a.authority_id;   
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_RULE_QUALIFIERS'
        and exists (
            select 1
            from tb_rule_qualifiers r
            where r.authority_id = a.authority_id
            and r.rule_qualifier_id = cj.primary_key)
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';   
        --update authority requirement references
        update tb_authority_requirements
        set authority_id = newAuthId
        where authority_id = a.authority_id;   
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_AUTHORITY_REQUIREMENTS'
        and exists (
            select 1
            from tb_authority_requirements r
            where r.authority_id = a.authority_id
            and r.authority_requirement_id = cj.primary_key)
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';     
        --update algx references
        update tb_authority_logic_group_xref
        set authority_id = newAuthId
        where authority_id = a.authority_id; 
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_AUTHORITY_LOGIC_GROUP_XREF'
        and exists (
            select 1
            from TB_AUTHORITY_LOGIC_GROUP_XREF r
            where r.authority_id = a.authority_id
            and r.authority_logic_group_xref_id = cj.primary_key)
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';   
        --update contributing authority references
        update tb_contributing_authorities
        set authority_id = newAuthId
        where authority_id = a.authority_id;
        update tb_content_journal cj
        set unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name ='TB_CONTRIBUTING_AUTHORITIES'
        and exists (
            select 1
            from TB_CONTRIBUTING_AUTHORITIES r
            where r.authority_id = a.authority_id
            and r.contributing_authority_id = cj.primary_key)
        and unique_id_xml like '%AUTHORITY_ID="'||a.authority_id||'"%';  
        --update authority references in content_journal
        update tb_content_journal
        set primary_key = newZoneAuthId, unique_id_xml = replace(unique_id_xml,'AUTHORITY_ID="'||a.authority_id||'"','AUTHORITY_ID="'||newAuthId||'"')
        where table_name = 'TB_AUTHORITIES'
        and primary_key = a.authority_id;
        --update zone references in datax_check_output
        update datax_check_output o
        set primary_key = newAuthId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_AUTHORITIES'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = a.authority_id;
    end loop;
    commit;
    execute immediate 'alter trigger dt_authorities enable';
    execute immediate 'alter trigger dt_rates enable';
    execute immediate 'alter trigger dt_rules enable';
    execute immediate 'alter trigger dt_rule_qualifiers enable';
    execute immediate 'alter trigger dt_rule_qualifiers enable';
    execute immediate 'LOCK TABLE tb_zones IN EXCLUSIVE MODE';
    execute immediate 'LOCK TABLE tb_zone_authorities IN EXCLUSIVE MODE';
    execute immediate 'alter trigger dt_zones disable';
    execute immediate 'alter trigger dt_zone_authorities disable'; 
    --Update Zone_ID's
    for z in zones loop
        newZoneId := newZoneId+1;
        --update zones table
        update tb_zones
        set zone_id = newZoneId
        where zone_id = z.zone_id;
        --update zone authority references
        update tb_zone_authorities
        set zone_id = newZoneId
        where zone_id = z.zone_id;
        --update zone references in content_journal
        update tb_content_journal
        set primary_key = newZoneId, unique_id_xml = replace(unique_id_xml,'ZONE_ID="'||z.zone_id||'"','ZONE_ID="'||newZoneId||'"')
        where table_name = 'TB_ZONES'
        and primary_key = z.zone_id;
        --update zone references in content_journal
        update tb_content_journal
        set unique_id_xml = replace(unique_id_xml,'ZONE_ID="'||z.zone_id||'"','ZONE_ID="'||newZoneId||'"')
        where table_name = 'TB_ZONE_AUTHORITIES'
        and unique_id_xml like '%ZONE_ID="'||z.zone_id||'"%';
        --update zone references in datax_check_output
        update datax_check_output o
        set primary_key = newZoneId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_ZONES'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = z.zone_id;
    end loop;
    
    --Update Zone_Authority_ID's
    for za in zone_authorities loop
        newZoneAuthId := newZoneAuthId+1;
        --update zones table
        update tb_zone_authorities
        set zone_authority_id = newZoneAuthId
        where zone_authority_id = za.zone_authority_id;
        --update zone authority references in content_journal
        update tb_content_journal
        set primary_key = newZoneAuthId, unique_id_xml = replace(unique_id_xml,'ZONE_AUTHORITY_ID="'||za.zone_authority_id||'"','ZONE_AUTHORITY_ID="'||newZoneAuthId||'"')
        where table_name = 'TB_ZONE_AUTHORITIES'
        and primary_key = za.zone_authority_id;
        --update zone references in datax_check_output
        update datax_check_output o
        set primary_key = newZoneAuthId
        where exists (
            select 1
            from datax_checks dc
            where data_owner_table = 'TB_ZONE_AUTHORITIES'
            and dc.data_check_id = o.data_check_id
            )
        and primary_key = za.zone_authority_id;
    end loop;
    commit;
    execute immediate 'alter trigger dt_zones enable';
    execute immediate 'alter trigger dt_zone_authorities enable'; 
    update tb_counters
    set value = (select max(authority_id) from tb_authorities)
    where name = 'TB_AUTHORITIES';
    update tb_counters
    set value = (select max(rate_id) from tb_rates)
    where name = 'TB_RATES';
    update tb_counters
    set value = (select max(rate_tier_id) from tb_rate_tiers)
    where name = 'TB_RATE_TIERS';
    update tb_counters
    set value = (select max(rule_id) from tb_rules)
    where name = 'TB_RULES';
    update tb_counters
    set value = (select max(rule_qualifier_id) from tb_rule_qualifiers)
    where name = 'TB_RULE_QUALIFIERS';
    update tb_counters
    set value = (select max(zone_authority_id) from tb_zone_authorities)
    where name = 'TB_ZONE_AUTHORITIES';
    update tb_counters
    set value = (select max(zone_id) from tb_zones)
    where name = 'TB_ZONES';
    commit;
    
    
    
    

end;
/