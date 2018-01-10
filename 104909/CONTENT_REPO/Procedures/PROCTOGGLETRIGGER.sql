CREATE OR REPLACE PROCEDURE content_repo."PROCTOGGLETRIGGER" (v_triggername in varchar2, OnOff number)
IS
BEGIN
  if OnOff = 0 then
    EXECUTE IMMEDIATE 'ALTER TRIGGER '||v_triggername||' DISABLE';
     -- Do work
  end if;

  if OnOff = 1 then
    EXECUTE IMMEDIATE 'ALTER TRIGGER '||v_triggername||' ENABLE';
     -- Do work
  end if;

EXCEPTION
   WHEN OTHERS
   THEN
      RAISE;
END procToggleTrigger;
 
/