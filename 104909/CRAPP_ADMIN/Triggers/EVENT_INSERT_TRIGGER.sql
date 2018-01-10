CREATE OR REPLACE TRIGGER crapp_admin."EVENT_INSERT_TRIGGER"
 BEFORE
 INSERT
 ON crapp_admin.EVENT
 FOR EACH ROW
begin
    select event_id_seq.nextval
    into :new.id
    from dual;
    :new.creation_time := sysdate;
    :new.expiration_time := sysdate+1;
    :new.status := 0;
end;
/