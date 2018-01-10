CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_cont_auths (contributor,contributee,basis_percent,start_date,end_date) AS
select a.name contributor, ta.name contributee, ca.basis_percent, ca.start_date, ca.end_date
from pvw_tb_contributing_auths ca
join (
    select name, authority_uuid uuid
    from tmp_tb_authorities
    union
    select name, uuid
    from tb_authorities
    ) a on (a.uuid = ca.authority_uuid)
join (
    select name, authority_uuid uuid
    from tmp_tb_authorities
    union
    select name, uuid
    from tb_authorities
    ) ta on (ta.uuid = ca.this_authority_uuid)
 
 ;