CREATE OR REPLACE TRIGGER sbxtax2."DT_TB_ZONE_MATCH_PATTERNS" 
after insert or update or delete on sbxtax2.TB_ZONE_MATCH_PATTERNS
for each row
declare
  old TB_ZONE_MATCH_PATTERNS%rowtype;
  v_merchant_id number;
begin
  old.ZONE_MATCH_PATTERN_ID := :old.ZONE_MATCH_PATTERN_ID;
  old.PATTERN := :old.PATTERN;
  old.VALUE := :old.VALUE;
  old.TYPE := :old.TYPE;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_ZONE_MATCH_PATTERNS('A', :new.ZONE_MATCH_PATTERN_ID, v_merchant_id, old);
  elsif updating then
    if (:new.pattern != :old.pattern or
       (:new.value != :old.value) or
       (:new.type != :old.type)) then
      add_content_journal_entries.p_ZONE_MATCH_PATTERNS('U', :new.ZONE_MATCH_PATTERN_ID, v_merchant_id, old);
    end if;
  elsif deleting then
    add_content_journal_entries.p_ZONE_MATCH_PATTERNS('D', :old.ZONE_MATCH_PATTERN_ID, v_merchant_id, old);
  end if;
end dt_TB_ZONE_MATCH_PATTERNS;
/