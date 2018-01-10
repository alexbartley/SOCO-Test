CREATE OR REPLACE TRIGGER sbxtax3."DT_TB_ZONE_MATCH_CONTEXTS" 
after insert or update or delete on sbxtax3.TB_ZONE_MATCH_CONTEXTS
for each row
declare
  old TB_ZONE_MATCH_CONTEXTS%rowtype;
  v_merchant_id number;
begin
  old.ZONE_MATCH_CONTEXT_ID := :old.ZONE_MATCH_CONTEXT_ID;
  old.ZONE_MATCH_PATTERN_ID := :old.ZONE_MATCH_PATTERN_ID;
  old.ZONE_LEVEL_ID := :old.ZONE_LEVEL_ID;
  old.ZONE_ID := :old.ZONE_ID;
  /* get merchant_id */

select
TB_ZONE_MATCH_PATTERNS.MERCHANT_ID
 into v_merchant_id
 from tb_zone_match_patterns
 where TB_ZONE_MATCH_PATTERNS.ZONE_MATCH_PATTERN_ID = nvl(:new.ZONE_MATCH_PATTERN_ID, :old.ZONE_MATCH_PATTERN_ID)
;
  if inserting then
    add_content_journal_entries.p_ZONE_MATCH_CONTEXTS('A', :new.ZONE_MATCH_CONTEXT_ID, v_merchant_id, old);
  elsif updating then
    if (:new.zone_match_pattern_id != :old.zone_match_pattern_id or
       (:new.zone_level_id != :old.zone_level_id) or
       (:new.zone_id != :old.zone_id)) then
       add_content_journal_entries.p_ZONE_MATCH_CONTEXTS('U', :new.ZONE_MATCH_CONTEXT_ID, v_merchant_id, old);
    end if;
  elsif deleting then
    add_content_journal_entries.p_ZONE_MATCH_CONTEXTS('D', :old.ZONE_MATCH_CONTEXT_ID, v_merchant_id, old);
  end if;
end dt_TB_ZONE_MATCH_CONTEXTS;
/