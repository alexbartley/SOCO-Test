CREATE OR REPLACE PROCEDURE content_repo."CRAPP_1884_DATA_CONV_CLEANUP" is
/*
|| Cleanup RepCode
|| Used for rollback of the data during development
*/
  cursor c1 is
  select id from jurisdiction_attributes
  where attribute_id=23;
  rc number:=0;
begin
  For z in c1 loop
   DBMS_OUTPUT.Put_Line( z.id );
   delete from jurisdiction_attributes where id = z.id;
   rc:=rc+1;
   if rc>50 then
     commit;
     rc:=0;
   end if;
  end loop;
  commit;
end CRAPP_1884_DATA_CONV_CLEANUP;
 
/