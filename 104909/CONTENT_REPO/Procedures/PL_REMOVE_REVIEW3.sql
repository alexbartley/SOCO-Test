CREATE OR REPLACE PROCEDURE content_repo."PL_REMOVE_REVIEW3" as
/*
 Remove assignment type 6 (review 3)
 CRAPP-1302

List of tables
------------------------
ADMIN_CHG_VLDS
JURIS_CHG_VLDS
JURIS_TAX_CHG_VLDS
JURIS_TAX_APP_CHG_VLDS
COMM_GRP_CHG_VLDS
COMM_CHG_VLDS
REF_GRP_CHG_VLDS
GEO_POLY_REF_CHG_VLDS
GEO_UNIQUE_AREA_CHG_VLDS
*/
Begin
--select * from admin_chg_vlds where assignment_type_id=6;
Update admin_chg_vlds set assignment_type_id=5
where assignment_type_id=6;

--Select * from juris_chg_vlds where assignment_type_id=6;
Update juris_chg_vlds set assignment_type_id=5
where assignment_type_id=6;

--Select * from JURIS_TAX_CHG_VLDS where assignment_type_id=6;
Update JURIS_TAX_CHG_VLDS set assignment_type_id=5
where assignment_type_id=6;

--Select * from juris_tax_app_chg_vlds where assignment_type_id=6;
Update juris_tax_app_chg_vlds set assignment_type_id=5
where assignment_type_id=6;

--Select * from COMM_CHG_VLDS where assignment_type_id=6;
Update COMM_CHG_VLDS set assignment_type_id=5
where assignment_type_id=6;

--Select * from REF_GRP_CHG_VLDS where assignment_type_id=6;
Update REF_GRP_CHG_VLDS set assignment_type_id=5
where assignment_type_id=6;

--Select * from GEO_POLY_REF_CHG_VLDS where assignment_type_id=6;
Update GEO_POLY_REF_CHG_VLDS set assignment_type_id=5
where assignment_type_id=6;

--Select * from GEO_UNIQUE_AREA_CHG_VLDS where assignment_type_id=6;
Update GEO_UNIQUE_AREA_CHG_VLDS set assignment_type_id=5
where assignment_type_id=6;

delete from assignment_types
where id=6;

commit;

end;
/