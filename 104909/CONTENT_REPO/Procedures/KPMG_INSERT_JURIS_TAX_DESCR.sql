CREATE OR REPLACE PROCEDURE content_repo.kpmg_insert_juris_tax_descr(officialname varchar2)
is
  vcnt number;
  vrid number;
begin
   for i in (  select j.id, j.nkid, tax_description_id, ji.start_date, j.rid
               from jurisdictions j, juris_tax_impositions ji
                where j.id = ji.jurisdiction_id
                  and j.nkid = ji.jurisdiction_nkid
                  and official_name = officialname
                  and ji.entered_by = -2918
                  and trunc(ji.entered_date) = to_date('20161207','yyyymmdd')
            )
   loop

        begin
        select rid into vrid from jurisdictions where official_name = officialname and next_rid is null;
        exception
        when no_data_found
        then
            select max(rid) into vrid from jurisdictions where official_name = officialname;
        end;

         select count(1) into vcnt
         from juris_tax_descriptions jt
         where jt.tax_description_id = i.tax_description_id
           and jt.jurisdiction_nkid = i.nkid;

         if vcnt = 0
         then
              insert into juris_tax_descriptions
              (jurisdiction_id, jurisdiction_nkid, tax_description_id, start_date, entered_by, status, rid)
              values
              (i.id, i.nkid, i.tax_description_id, i.start_date, -2918, 0, vrid);
DBMS_OUTPUT.Put_Line( 'Insert --'||i.id );
         end if;

   end loop;

end;
/