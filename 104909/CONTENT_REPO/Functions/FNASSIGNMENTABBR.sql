CREATE OR REPLACE FUNCTION content_repo.fnassignmentabbr (pAssignmentType in number) return varchar2
is
  -- Have no table/column/settings for this yet.
  -- As the name says! DEV
  -- Abbr column on the assignment_type table is pref.
/*
  Final Review = FR
  Review 1 = R1
  Review 2 = R2
  Review 3 = R3
*/
  abbr varchar2(2);
begin
  CASE pAssignmentType
   WHEN 2 then abbr:='FR';
   WHEN 4 then abbr:='R1';
   WHEN 5 then abbr:='R2';
   WHEN 6 then abbr:='R3';
   -- Added Test in Staging, to get it displayed on the change log verification page correctly. CRAPP-3751
   WHEN 7 then abbr:='TS';
   ELSE abbr:='';
  END CASE;
  Return abbr;
end;
/