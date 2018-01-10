CREATE OR REPLACE PROCEDURE content_repo."IMP_JS_TREE_P" as
 type r_j3 is record
 (j3key varchar2(32),
  id number,
  offname varchar2(256));
 type t3 is table of r_j3;

 -- Storing all and not reused if needed for different type of build
 s1 t3:=t3();
 s2 t3:=t3();
 s3 t3:=t3();
 s4 t3:=t3();

begin

Delete from IMP_JS_TREE_BUILD;
Commit;

-- STATE
select
    substr(j.official_name,1,4)||j.nkid J3KEY
  , id
  , official_name
bulk collect into s1
from jurisdictions j
where j.geo_area_category_id=3
and j.next_rid is null;

  FORALL ii IN s1.first..s1.last
  Insert into IMP_JS_TREE_BUILD
  Values(s1(ii).j3key, 0, s1(ii).id, s1(ii).offname, 3);

-- COUNTY
for ii in s1.first..s1.last loop
  select substr(j.official_name,1,4)||j.nkid J4KEY, id, official_name
  bulk collect into s2
  from jurisdictions j
  where j.geo_area_category_id=4
    and substr(j.official_name,1,4) = substr(s1(ii).j3key,1,4)
    and j.next_rid is null;

  FORALL ix IN s2.first..s2.last
  Insert into IMP_JS_TREE_BUILD
  Values(s2(ix).j3key, s1(ii).id, s2(ix).id, s2(ix).offname, 4);

end loop;

-- CITY
for ii in s1.first..s1.last loop
  select substr(j.official_name,1,4)||j.nkid J4KEY, id, official_name
  bulk collect into s3
  from jurisdictions j
  where j.geo_area_category_id=5
    and substr(j.official_name,1,4) = substr(s1(ii).j3key,1,4)
    and j.next_rid is null;

  FORALL ix IN s3.first..s3.last
  Insert into IMP_JS_TREE_BUILD
  Values(s3(ix).j3key, s1(ii).id, s3(ix).id, s3(ix).offname, 5);

end loop;


-- DISTRICT
for ii in s1.first..s1.last loop
  select substr(j.official_name,1,4)||j.nkid J4KEY, id, official_name
  bulk collect into s4
  from jurisdictions j
  where j.geo_area_category_id=6
    and substr(j.official_name,1,4) = substr(s1(ii).j3key,1,4)
    and j.next_rid is null;

  FORALL ix IN s4.first..s4.last
  Insert into IMP_JS_TREE_BUILD
  Values(s4(ix).j3key, s1(ii).id, s4(ix).id, s4(ix).offname, 6);

end loop;

---> ENDE
Commit;

  -- CRAPP-3047
  EXCEPTION
  -- Jurisdiction hierarchy could not be built
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Error building Jurisdiction hierarchy');


End;
/