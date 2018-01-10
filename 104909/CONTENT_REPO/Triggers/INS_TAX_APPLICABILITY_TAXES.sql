CREATE OR REPLACE TRIGGER content_repo."INS_TAX_APPLICABILITY_TAXES"
 BEFORE
 INSERT
 ON content_repo.TAX_APPLICABILITY_TAXES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
declare
vrefence_code varchar2(50 char);
vtax_type varchar2(10 char);
vcnt number;

BEGIN

  IF (:new.nkid IS NULL) THEN
    :new.id   := pk_tax_applicability_taxes.nextval;
    :new.nkid := nkid_tax_applicability_taxes.nextval;
    :new.rid  := tax_applicability.get_revision(entity_id_io => :new.juris_Tax_applicability_id, entity_nkid_i => null, entered_by_i => :new.entered_by);
  END IF;


  -- Auto assigning of Tax Types should happen only when we are inserting.
  -- On a published record, if the user updates the tax type and created a new revision, then whatever the user entered,
  -- the same value should be considered to create the new revision.

  select count(1) into vcnt from juris_tax_app_revisions where nkid = :new.JURIS_TAX_APPLICABILITY_NKID;

  if vcnt <= 1
  then

	  if :new.tax_type_id is null
	  then

		  select reference_code into vrefence_code from juris_tax_impositions where id = :new.juris_tax_imposition_id;

			IF vrefence_code LIKE '%CU%' THEN
			vtax_type := 'CU';
			ELSIF vrefence_code LIKE '%SU%' THEN
			vtax_type := 'US';
			ELSIF vrefence_code LIKE '%RU' THEN
			vtax_type := 'RU';
			ELSIF vrefence_code LIKE '%ST%' THEN
				vtax_type := null;
				/*
				if vrefence_code = 'ST'
				then vtax_type := null;
				else
					vtax_type := 'SA';
				end if;
				*/
			ELSIF vrefence_code LIKE '%RS' THEN
			vtax_type := 'RS';
			ELSIF vrefence_code LIKE 'TSP%' THEN
			vtax_type := 'SV';
			ELSIF vrefence_code LIKE 'TUT%' THEN
			vtax_type := 'UU';
			ELSIF vrefence_code LIKE 'TEX%' THEN
			vtax_type := 'EXC';
			ELSIF vrefence_code LIKE 'TGR%' THEN
			vtax_type := 'GR';
			ELSIF vrefence_code LIKE 'TS%'
			AND vrefence_code NOT LIKE 'TSP%'
			AND vrefence_code NOT LIKE 'TST%'
			AND vrefence_code NOT LIKE 'TSU%'
			THEN
			vtax_type := 'SC';
			ELSIF vrefence_code LIKE 'TBO%' THEN
			vtax_type := 'BO';
			ELSIF vrefence_code LIKE 'TLT%' THEN
			vtax_type := 'LT';
			END IF;
		  :new.tax_type := vtax_type;
			begin
				select id into :new.tax_type_id from tax_types where code = vtax_type and code_group = 'US_TAX_TYPE';
			exception
			when no_data_found
			then
				:new.tax_type_id := null;
			end;

	  end if;
  end if;

  IF (:new.ref_rule_order IS NULL) THEN
  begin

    SELECT distinct ref_rule_order
    INTO   :new.ref_rule_order
    FROM   tax_applicability_taxes
    WHERE nkid = :new.nkid
        AND ref_rule_order IS NOT NULL;

  exception
  when others then :new.ref_rule_order := null;
  end;
  END IF;

  :new.entered_date := SYSTIMESTAMP;
  :new.status_modified_date := SYSTIMESTAMP;

  INSERT INTO juris_tax_app_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
  VALUES ('TAX_APPLICABILITY_TAXES',:new.id,:new.entered_by,:new.rid, :new.juris_tax_applicability_id);

  INSERT INTO juris_tax_app_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
  VALUES ('TAX_APPLICABILITY_TAXES', :new.nkid, :new.id,:new.entered_by,:new.rid,(select jti.reference_code from juris_tax_impositions jti where jti.id = :new.juris_tax_imposition_id));
END;
/