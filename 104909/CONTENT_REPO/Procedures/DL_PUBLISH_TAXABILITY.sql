CREATE OR REPLACE procedure content_repo.dl_publish_taxability( jurisdiction_id_i number)
is
begin

execute immediate 'alter trigger INS_JURIS_TAX_APP_CHG_VLDS disable';
execute immediate 'alter trigger UPD_JURIS_TAX_APP_CHG_LOGS disable';
execute immediate 'alter trigger UPD_JURIS_TAX_APP_REVISIONS disable';
execute immediate 'alter trigger UPD_TAX_APPLICABILITY_TAXES disable';
execute immediate 'alter trigger UPD_TRAN_TAX_QUALIFIERS disable';
execute immediate 'alter trigger UPD_TAXABILITY_OUTPUTS disable';
execute immediate 'alter trigger UPD_TAX_APP_ATTRIBUTES disable';
execute immediate 'alter trigger UPD_JURIS_TAX_APPLICABILITIES disable';

declare
vcnt number;
BEGIN
for i in ( select distinct jtr.id rev_id, jtr.nkid rev_nkid from juris_tax_app_revisions jtr join juris_tax_applicabilities jta
                            on ( jta.nkid = jtr.nkid )
                    join jurisdictions j on ( j.nkid = jta.jurisdiction_nkid and j.next_rid is null)
                where j.id = jurisdiction_id_i
         )
loop

    for m in ( select * from juris_tax_app_chg_logs where rid = i.rev_id )
    loop
        select count(1) into vcnt from juris_tax_app_chg_vlds where juris_tax_app_chg_log_id = m.id and assignment_type_id = 2;
        if vcnt = 0 then
            INSERT INTO juris_tax_app_chg_vlds
            VALUES(pk_juris_tax_app_chg_vlds.nextval,-1703,sysdate,sysdate ,0,
            sysdate,m.id,2,-1703 , i.rev_id );
        end if;
    END LOOP;

UPDATE JURIS_TAX_APP_CHG_LOGS SET STATUS = 2 where rid = i.rev_id;
UPDATE JURIS_TAX_APP_REVISIONS SET STATUS = 2, SUMM_ASS_STATUS = 5 where id = i.rev_id;
UPDATE TRAN_TAX_QUALIFIERS SET STATUS = 2 where rid = i.rev_id;
UPDATE TAX_APPLICABILITY_TAXES SET STATUS = 2 where rid = i.rev_id;
UPDATE TAXABILITY_OUTPUTS SET STATUS = 2 where rid = i.rev_id;
UPDATE JURIS_TAX_APP_ATTRIBUTES SET STATUS = 2 where rid = i.rev_id;
UPDATE JURIS_TAX_APPLICABILITIES SET STATUS = 2 where rid = i.rev_id;

insert into sbxtax.extract_log ( tag_group, entity, nkid, rid, extract_date, queued_date, transformed, loaded  )
values ( 'Determination (All versions), United States', 'TAXABILITY', i.rev_nkid, i.rev_id, sysdate, sysdate, sysdate, sysdate );

insert into sbxtax4.extract_log ( tag_group, entity, nkid, rid, extract_date, queued_date, transformed, loaded  )
values ( 'Determination (All versions), United States', 'TAXABILITY', i.rev_nkid, i.rev_id, sysdate, sysdate, sysdate, sysdate );

end loop;
END;

execute immediate 'alter trigger INS_JURIS_TAX_APP_CHG_VLDS enable';
execute immediate 'alter trigger UPD_JURIS_TAX_APP_CHG_LOGS enable';
execute immediate 'alter trigger UPD_JURIS_TAX_APP_REVISIONS enable';
execute immediate 'alter trigger UPD_TAX_APPLICABILITY_TAXES enable';
execute immediate 'alter trigger UPD_TRAN_TAX_QUALIFIERS enable';
execute immediate 'alter trigger UPD_TAXABILITY_OUTPUTS enable';
execute immediate 'alter trigger UPD_TAX_APP_ATTRIBUTES enable';
execute immediate 'alter trigger UPD_JURIS_TAX_APPLICABILITIES enable';

end;
/