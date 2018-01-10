CREATE OR REPLACE PACKAGE BODY content_repo."POST_PUBLISH"
IS
-- *****************************************************************
-- Description:
--
-- Revision History
-- Date            Author       Reason for Change
-- ----------------------------------------------------------------
-- 14 OCT 2014     TNN          Removed Drop and Create
-- 15 OCT 2014     DLG          Crapp-809 - Added DESCRIPTION to Reference_Groups
-- 16 JAN 2015     DLG          Added GIS
-- 11/30/2016      TNN          removed comm_group_TAGS ref
-- *****************************************************************

PROCEDURE refresh_hierarchy_levels
IS
BEGIN
    execute immediate 'truncate table crapp_extract.hierarchy_levels drop storage';
    execute immediate 'insert into crapp_extract.hierarchy_levels (select * from hierarchy_levels)';
END refresh_hierarchy_levels;


PROCEDURE refresh_TRAN_TAX_QUALIFIERS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tran_tax_qualifiers;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TRAN_TAX_QUALIFIERS a
           USING (SELECT * FROM TRAN_TAX_QUALIFIERS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TRAN_TAX_QUALIFIERS
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            -- (the ones that are valid to update of course. ToDo: come back and remove fields that will not change)
            SET     a.juris_tax_applicability_id = b.juris_tax_applicability_id,
                    a.juris_tax_applicability_nkid = b.juris_tax_applicability_nkid,
                    a.taxability_element_id = b.taxability_element_id,
                    a.logical_qualifier = b.logical_qualifier,
                    a.value = b.value,
                    a.element_qual_group = b.element_qual_group,
                    a.start_date = b.start_date,
                    a.end_date = b.end_date,
                    a.entered_by = b.entered_by,
                    a.entered_date = b.entered_date,
                    a.status = b.status,
                    a.status_modified_date = b.status_modified_date,
                    a.next_rid = b.next_rid,
                    a.jurisdiction_id = b.jurisdiction_id,
                    a.jurisdiction_nkid = b.jurisdiction_nkid,
                    a.reference_group_id = b.reference_group_id,
                    a.reference_group_nkid = b.reference_group_nkid,
                    a.qualifier_type = b.qualifier_type
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.juris_tax_applicability_id, a.juris_tax_applicability_nkid,a.taxability_element_id, a.logical_qualifier, a.value, a.element_qual_group,
             a.start_date, a.end_date, a.entered_by, a.entered_date, a.status, a.status_modified_date, a.rid, a.nkid,
             a.next_rid, a.jurisdiction_id, a.jurisdiction_nkid,a.reference_group_id, a.reference_group_nkid,a.qualifier_type)
            VALUES (
             b.id, b.juris_tax_applicability_id, b.juris_tax_applicability_nkid, b.taxability_element_id, b.logical_qualifier, b.value, b.element_qual_group,
             b.start_date, b.end_date, b.entered_by, b.entered_date, b.status, b.status_modified_date, b.rid, b.nkid,
             b.next_rid, b.jurisdiction_id, b.jurisdiction_nkid,  b.reference_group_id, b.reference_group_nkid, b.qualifier_type
            );

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TRAN_TAX_QUALIFIERS l_ct: '||l_ct);

    COMMIT;
END refresh_TRAN_TAX_QUALIFIERS;


PROCEDURE refresh_geo_area_categories
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.geo_area_categories drop storage';
    execute immediate 'Insert Into crapp_extract.geo_area_categories (select * from geo_area_categories where status=2)';
END refresh_geo_area_categories;

PROCEDURE refresh_TRANSACTION_TYPES
IS
BEGIN
  MERGE /*+ APPEND */
      INTO crapp_extract.TRANSACTION_TYPES a
           USING (Select * from TRANSACTION_TYPES where status=2) b
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.name = b.name,
            a.description = b.description,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.ui_order = b.ui_order,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.name, a.description, a.entered_by, a.entered_date,
            a.ui_order, a.status, a.status_modified_date)
            VALUES (b.id, b.name, b.description, b.entered_by, b.entered_date,
            b.ui_order, b.status, b.status_modified_date
            );
  Commit;
END refresh_TRANSACTION_TYPES;

PROCEDURE refresh_QUALIFIER_TYPES
IS
BEGIN
    -- Small (no pk/index table)
    execute immediate 'Truncate Table crapp_extract.QUALIFIER_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.QUALIFIER_TYPES (select * from QUALIFIER_TYPES) ';
    -- ToDo: Don't forget to add 'where status=2' if this should follow the pending/published concept
END refresh_QUALIFIER_TYPES;

PROCEDURE refresh_TAX_STRUCTURE_TYPES
IS
BEGIN
    -- Small (pk only)
    execute immediate 'Truncate Table crapp_extract.TAX_STRUCTURE_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.TAX_STRUCTURE_TYPES (select * from tax_structure_types)';
END refresh_TAX_STRUCTURE_TYPES;

PROCEDURE refresh_TAXATION_TYPES
IS
BEGIN
    -- small (pk only)
    execute immediate 'Truncate table crapp_extract.TAXATION_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.taxation_types (select * from taxation_types)';
END refresh_TAXATION_TYPES;


PROCEDURE refresh_TAX_DESCRIPTIONS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_descriptions;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAX_DESCRIPTIONS a
           USING (SELECT * FROM TAX_DESCRIPTIONS
                  WHERE status = 2
                        -- crapp-3028, now pulling the past 60 days
                        AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            -- (the ones that are valid to update of course. Using all just for test)
            SET
            a.name = b.name,
            a.transaction_type_id = b.transaction_type_id,
            a.taxation_type_id = b.taxation_type_id,
            a.spec_applicability_type_id = b.spec_applicability_type_id,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.entered_date = b.entered_date,
            a.entered_by = b.entered_by,
            a.description = b.description,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.name, a.transaction_type_id, a.taxation_type_id, a.spec_applicability_type_id, a.start_date, a.end_date,
             a.entered_date, a.entered_by, a.description, a.status, a.status_modified_date)
            VALUES (b.id, b.name, b.transaction_type_id, b.taxation_type_id, b.spec_applicability_type_id, b.start_date,
            b.end_date, b.entered_date, b.entered_by, b.description, b.status, b.status_modified_date
            );

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_DESCRIPTIONS l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_DESCRIPTIONS;

PROCEDURE refresh_TAX_CALC_STRUCTURES
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.tax_calculation_structures drop storage';
    execute immediate 'Insert Into crapp_extract.tax_calculation_structures (Select * from tax_calculation_structures)';
END refresh_TAX_CALC_STRUCTURES;

PROCEDURE refresh_TAXABILITY_ELEMENTS
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.TAXABILITY_ELEMENTS drop storage';
    execute immediate 'Insert Into crapp_extract.taxability_elements (select * from taxability_elements)';
END refresh_TAXABILITY_ELEMENTS;

PROCEDURE refresh_SPEC_APP_TYPES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.SPECIFIC_APPLICABILITY_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.specific_applicability_types (select * from specific_applicability_types)';
END refresh_SPEC_APP_TYPES;

PROCEDURE refresh_TAG_TYPES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.TAG_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.TAG_TYPES (Select * from TAG_TYPES)';
END refresh_TAG_TYPES;

PROCEDURE refresh_RECORD_STATUSES
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.RECORD_STATUSES drop storage';
    execute immediate 'Insert Into crapp_extract.RECORD_STATUSES (select * from RECORD_STATUSES)';
END refresh_RECORD_STATUSES;

PROCEDURE refresh_QUALIFICATION_METHODS
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.QUALIFICATION_METHODS drop storage';
    execute immediate 'Insert Into crapp_extract.QUALIFICATION_METHODS (select * from QUALIFICATION_METHODS) ';
END refresh_QUALIFICATION_METHODS;

PROCEDURE refresh_REFERENCE_GROUPS
IS
BEGIN
    -- crapp_extract.REFERENCE_GROUPS has different fieldset
    execute immediate 'truncate table crapp_extract.REFERENCE_GROUPS drop storage';
    INSERT INTO crapp_extract.reference_groups
        (id, rid, nkid, next_rid, name, start_date, end_date, status, status_modified_date, entered_by, entered_date, description) --CRAPP-809 dlg
    (
        SELECT id, rid, nkid, next_rid, name, start_date, end_Date, status, status_modified_date, entered_by, entered_date, description
        FROM   reference_groups
        WHERE  status = 2
    );
    COMMIT;
END refresh_REFERENCE_GROUPS;

PROCEDURE refresh_REFERENCE_ITEMS
IS
BEGIN
    execute immediate 'truncate table crapp_extract.REFERENCE_ITEMS drop storage';
    INSERT INTO crapp_extract.reference_items (id, rid, nkid, next_rid, value, value_type, description, ref_nkid, reference_group_id, reference_group_nkid, start_date, end_date, status, status_modified_date, entered_by, entered_date) (
    SELECT id, rid, nkid, next_rid, value, value_type, description, ref_nkid, reference_Group_id, reference_group_nkid, start_date, end_Date, status, status_modified_date, entered_by, entered_date
    FROM reference_items
    WHERE status=2
    );
    COMMIT;
END refresh_REFERENCE_ITEMS;

PROCEDURE refresh_ref_group_revisions
IS
BEGIN
    -- Diff fieldset
    execute immediate 'truncate table crapp_extract.ref_group_revisions drop storage';
    insert into crapp_extract.ref_group_revisions (id, nkid, next_rid, status, status_modified_Date, entered_by, entered_date) (
    select id, nkid, next_rid, status, status_modified_Date, entered_by, entered_date
    from ref_group_revisions
    where status=2
    );
    COMMIT;
END refresh_ref_group_revisions;

PROCEDURE refresh_PRODUCT_TREES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.PRODUCT_TREES drop storage';
    execute immediate 'Insert Into crapp_extract.product_trees (Select * from product_trees)';
END refresh_PRODUCT_TREES;

PROCEDURE refresh_LOGICAL_QUALIFIERS
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.LOGICAL_QUALIFIERS drop storage';
    execute immediate 'Insert Into crapp_extract.LOGICAL_QUALIFIERS (select * from logical_qualifiers)';
END refresh_LOGICAL_QUALIFIERS;

PROCEDURE refresh_PACKAGES
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.PACKAGES drop storage';
    execute immediate 'Insert Into crapp_extract.PACKAGES (select * from PACKAGES)';
END refresh_PACKAGES;

PROCEDURE refresh_HIERARCHY_DEFINITIONS
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.HIERARCHY_DEFINITIONS drop storage';
    execute immediate 'Insert Into crapp_extract.HIERARCHY_DEFINITIONS (select * from HIERARCHY_DEFINITIONS)';
END refresh_HIERARCHY_DEFINITIONS;

PROCEDURE refresh_CURRENCIES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.CURRENCIES drop storage';
    execute immediate 'Insert Into crapp_extract.currencies (Select * from currencies)';
END refresh_CURRENCIES;

PROCEDURE refresh_CALCULATION_METHODS
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.CALCULATION_METHODS drop storage';
    execute immediate 'Insert Into crapp_extract.calculation_methods (Select * from calculation_methods)';
END refresh_CALCULATION_METHODS;

PROCEDURE refresh_LANGUAGES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.LANGUAGES drop storage';
    execute immediate 'Insert Into crapp_extract.LANGUAGES (select * from LANGUAGES)';
END refresh_LANGUAGES;

PROCEDURE refresh_ATTRIBUTE_CATEGORIES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.ATTRIBUTE_CATEGORIES drop storage';
    execute immediate 'Insert Into crapp_extract.ATTRIBUTE_CATEGORIES (select * from ATTRIBUTE_CATEGORIES)';
END refresh_ATTRIBUTE_CATEGORIES;

PROCEDURE refresh_ATTRIBUTE_LOOKUPS
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.ATTRIBUTE_LOOKUPS drop storage';
    execute immediate 'Insert Into crapp_extract.ATTRIBUTE_LOOKUPS (select * from ATTRIBUTE_LOOKUPS)';
END refresh_ATTRIBUTE_LOOKUPS;

PROCEDURE refresh_ADMINISTRATOR_TYPES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.ADMINISTRATOR_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.ADMINISTRATOR_TYPES (select * from ADMINISTRATOR_TYPES)';
END refresh_ADMINISTRATOR_TYPES;

PROCEDURE refresh_APPLICABILITY_TYPES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.APPLICABILITY_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.APPLICABILITY_TYPES (select * from APPLICABILITY_TYPES)';
END refresh_APPLICABILITY_TYPES;

PROCEDURE refresh_AMOUNT_TYPES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.AMOUNT_TYPES drop storage';
    execute immediate 'Insert Into crapp_extract.AMOUNT_TYPES (select * from AMOUNT_TYPES)';
END refresh_AMOUNT_TYPES;

PROCEDURE refresh_ADDITIONAL_ATTRIBUTES
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.ADDITIONAL_ATTRIBUTES drop storage';
    execute immediate 'Insert Into crapp_extract.ADDITIONAL_ATTRIBUTES (select * from ADDITIONAL_ATTRIBUTES) ';
END refresh_ADDITIONAL_ATTRIBUTES;

PROCEDURE refresh_TAGS
IS
BEGIN
    execute immediate 'Truncate table crapp_extract.TAGS drop storage';
    execute immediate 'Insert Into crapp_extract.TAGS (select * from TAGS)';
END refresh_TAGS;


PROCEDURE refresh_COMMODITIES
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.commodities;

    MERGE /*+ APPEND */
      INTO crapp_extract.COMMODITIES a
           USING (SELECT * FROM COMMODITIES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM COMMODITIES
                                                WHERE status = 2
                                                      AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            -- (clean out the ones that stays the same. Using all just for dev)
            SET
            a.name = b.name,
            a.description = b.description,
            a.commodity_code = b.commodity_code,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.rid = b.rid,
            a.nkid = b.nkid,
            a.next_rid = b.next_rid,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.product_tree_id = b.product_tree_id,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.h_code = b.h_code
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.name, a.description, a.commodity_code, a.entered_by,
             a.entered_date, a.rid, a.nkid, a.next_rid, a.status,
             a.status_modified_date, a.product_tree_id, a.start_date,
             a.end_date, a.h_code)
            VALUES (b.id, b.name, b.description, b.commodity_code, b.entered_by,
             b.entered_date, b.rid, b.nkid, b.next_rid, b.status,
             b.status_modified_date, b.product_tree_id, b.start_date,
             b.end_date, b.h_code);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('COMMODITIES l_ct: '||l_ct);

    COMMIT;   -- Mandatory for Merge
END refresh_COMMODITIES;


PROCEDURE refresh_TAX_OUTLINES
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_outlines;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAX_OUTLINES a
           USING (SELECT * FROM TAX_OUTLINES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAX_OUTLINES
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.juris_tax_imposition_id = b.juris_tax_imposition_id,
            a.juris_tax_imposition_nkid = b.juris_tax_imposition_nkid,
            a.calculation_structure_id = b.calculation_structure_id,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.entered_by = b.entered_by,
            a.status = b.status,
            a.entered_date = b.entered_date,
            a.status_modified_date = b.status_modified_date,
            a.nkid = b.nkid,
            a.rid = b.rid,
            a.next_rid = b.next_rid
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.juris_tax_imposition_id, a.juris_tax_imposition_nkid,a.calculation_structure_id,
             a.start_date, a.end_date, a.entered_by, a.status, a.entered_date,
             a.status_modified_date, a.nkid, a.rid, a.next_rid)
            VALUES (b.id, b.juris_tax_imposition_id, b.juris_tax_imposition_nkid,b.calculation_structure_id,
                    b.start_date, b.end_date, b.entered_by, b.status, b.entered_date,
                    b.status_modified_date, b.nkid, b.rid, b.next_rid);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_OUTLINES l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_OUTLINES;

PROCEDURE refresh_JURIS_TAX_APPS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_applicabilities;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.JURIS_TAX_APPLICABILITIES a
           USING (SELECT * FROM JURIS_TAX_APPLICABILITIES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid
                                                FROM JURIS_TAX_APPLICABILITIES
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.reference_code = b.reference_code,
            a.calculation_method_id = b.calculation_method_id,
            a.basis_percent = b.basis_percent,
            a.recoverable_percent = b.recoverable_percent,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.rid = b.rid,
            a.nkid = b.nkid,
            a.next_rid = b.next_rid,
            a.jurisdiction_id = b.jurisdiction_id,
            a.jurisdiction_nkid = b.jurisdiction_nkid,
            a.unit_of_measure = b.unit_of_measure,
            a.charge_type_id = b.charge_type_id,
            a.recoverable_amount = b.recoverable_amount,
            a.ref_rule_order = b.ref_rule_order,
            --a.related_charge = b.related_charge,
            a.commodity_nkid = b.commodity_nkid,
            a.default_taxability = b.default_taxability,
            a.product_tree_id = b.product_tree_id,
            a.all_taxes_apply = b.all_taxes_apply
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.calculation_method_id, a.basis_percent, a.recoverable_percent,
       a.recoverable_amount, a.start_date, a.end_date, a.entered_by,
       a.entered_date, a.status, a.status_modified_date, a.rid, a.nkid,
       a.next_rid, a.jurisdiction_id, a.jurisdiction_nkid,
       a.all_taxes_apply, a.applicability_type_id, a.charge_type_id,
       a.unit_of_measure, a.ref_rule_order, a.default_taxability,
       a.product_tree_id, a.commodity_id, a.tax_type,
       a.is_local, a.exempt, a.no_tax, a.commodity_nkid,
       a.reference_code
             )
            VALUES ( b.id, b.calculation_method_id, b.basis_percent, b.recoverable_percent,
       b.recoverable_amount, b.start_date, b.end_date, b.entered_by,
       b.entered_date, b.status, b.status_modified_date, b.rid, b.nkid,
       b.next_rid, b.jurisdiction_id, b.jurisdiction_nkid,
       b.all_taxes_apply, b.applicability_type_id, b.charge_type_id,
       b.unit_of_measure, b.ref_rule_order, b.default_taxability,
       b.product_tree_id, b.commodity_id, b.tax_type,
       b.is_local, b.exempt, b.no_tax, b.commodity_nkid,
       b.reference_code);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_APPLICABILITIES l_ct: '||l_ct);

    COMMIT;
END refresh_JURIS_TAX_APPS;


PROCEDURE refresh_TAX_APP_TAXES
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_applicability_taxes;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAX_APPLICABILITY_TAXES a
           USING (SELECT * FROM TAX_APPLICABILITY_TAXES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAX_APPLICABILITY_TAXES
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.juris_tax_imposition_id=b.juris_tax_imposition_id,
            a.juris_tax_imposition_nkid=b.juris_tax_imposition_nkid,
            a.start_date=b.start_date,
            a.end_date=b.end_date,
            a.nkid=b.nkid,
            a.rid=b.rid,
            a.entered_by=b.entered_by,
            a.status=b.status,
            a.status_modified_date=b.status_modified_date,
            a.entered_date=b.entered_date,
            a.next_rid=b.next_rid,
            a.juris_tax_applicability_id=b.juris_tax_applicability_id,
            a.juris_tax_applicability_nkid=b.juris_tax_applicability_nkid,
            a.tax_type_id = b.tax_type_id,
            a.ref_rule_order = b.ref_rule_order
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.juris_tax_imposition_id, a.juris_tax_imposition_nkid,a.start_date, a.end_date,
       a.nkid, a.rid, a.entered_by, a.status, a.status_modified_date,
       a.entered_date, a.next_rid, a.juris_tax_applicability_id, a.juris_tax_applicability_nkid,
       a.tax_type_id, a.ref_rule_order
       )
            VALUES (b.id, b.juris_tax_imposition_id,  b.juris_tax_imposition_nkid,b.start_date, b.end_date,
       b.nkid, b.rid, b.entered_by, b.status, b.status_modified_date,
       b.entered_date, b.next_rid, b.juris_tax_applicability_id , b.juris_tax_applicability_nkid,
       b.tax_type_id, b.ref_rule_order);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_APPLICABILITY_TAXES l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_APP_TAXES;

PROCEDURE refresh_JURISDICTIONS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.jurisdictions;

    MERGE /*+ APPEND */
      INTO crapp_extract.JURISDICTIONS a
           USING (SELECT * FROM JURISDICTIONS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM JURISDICTIONS
                                                WHERE status = 2
                                                      AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.rid = b.rid,
            a.official_name = b.official_name,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.nkid = b.nkid,
            a.next_rid = b.next_rid,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.description = b.description,
            a.currency_id = b.currency_id,
            a.geo_area_category_id = b.geo_area_category_id,
            a.default_admin_id = b.default_admin_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.rid, a.official_name, a.start_date, a.end_date,
             a.entered_by, a.entered_date, a.nkid, a.next_rid, a.status,
             a.status_modified_date, a.description, a.currency_id,
             a.geo_area_category_id, a.default_admin_id)
            VALUES (b.id, b.rid, b.official_name, b.start_date, b.end_date,
            b.entered_by, b.entered_date, b.nkid, b.next_rid, b.status,
            b.status_modified_date, b.description, b.currency_id,
            b.geo_area_category_id, b.default_admin_id);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURISDICTIONS l_ct: '||l_ct);

    COMMIT;
END refresh_JURISDICTIONS;

PROCEDURE refresh_JURIS_ATTRIBUTES
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.jurisdiction_attributes;

    MERGE /*+ APPEND */
      INTO crapp_extract.JURISDICTION_ATTRIBUTES a
           USING (SELECT * FROM JURISDICTION_ATTRIBUTES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM JURISDICTION_ATTRIBUTES
                                                WHERE status = 2
                                                      AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.rid = b.rid,
            a.jurisdiction_id = b.jurisdiction_id,
            a.jurisdiction_nkid = b.jurisdiction_nkid,
            a.attribute_id = b.attribute_id,
            a.value = b.value,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.nkid = b.nkid,
            a.next_rid = b.next_rid,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.rid, a.jurisdiction_id, a.attribute_id, a.value,
            a.start_date, a.end_date, a.entered_by, a.entered_date, a.nkid,
            a.next_rid, a.status, a.status_modified_date, a.jurisdiction_nkid)
            VALUES (b.id, b.rid, b.jurisdiction_id, b.attribute_id, b.value,
            b.start_date, b.end_date, b.entered_by, b.entered_date, b.nkid,
            b.next_rid, b.status, b.status_modified_date,b.jurisdiction_nkid);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURISDICTION_ATTRIBUTES l_ct: '||l_ct);

    COMMIT;
END refresh_JURIS_ATTRIBUTES;

PROCEDURE refresh_TAX_LOCATIONS
IS
BEGIN
    -- obsolete
    execute immediate 'drop table crapp_extract.TAX_LOCATIONS drop storage';
    execute immediate 'create table crapp_extract.TAX_LOCATIONS as select * from TAX_LOCATIONS where status=2';
END refresh_TAX_LOCATIONS;


PROCEDURE refresh_TAXABILITY_OUTPUTS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.taxability_outputs;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAXABILITY_OUTPUTS a
           USING (SELECT * FROM TAXABILITY_OUTPUTS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAXABILITY_OUTPUTS
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.juris_tax_applicability_id = b.juris_tax_applicability_id,
            a.juris_tax_applicability_nkid = b.juris_tax_applicability_nkid,
            a.short_text = b.short_text,
            a.full_text = b.full_text,
            a.entered_by = b.entered_by,
            a.status = b.status,
            a.entered_date = b.entered_date,
            a.status_modified_date = b.status_modified_date,
            a.rid = b.rid,
            a.next_rid = b.next_rid,
            a.nkid = b.nkid,
            a.tax_applicability_tax_id = b.tax_applicability_tax_id,
            a.tax_applicability_tax_nkid = b.tax_applicability_tax_nkid
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.juris_tax_applicability_id, a.juris_tax_applicability_nkid,a.short_text, a.full_text,
             a.entered_by, a.status, a.entered_date, a.status_modified_date,
             a.rid, a.next_rid, a.nkid, a.tax_applicability_tax_id, a.tax_applicability_tax_nkid)
            VALUES (b.id, b.juris_tax_applicability_id, b.juris_tax_applicability_nkid,b.short_text, b.full_text,
            b.entered_by, b.status, b.entered_date, b.status_modified_date,
            b.rid, b.next_rid, b.nkid, b.tax_applicability_tax_id, b.tax_applicability_tax_nkid);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAXABILITY_OUTPUTS l_ct: '||l_ct);

    COMMIT;
END refresh_TAXABILITY_OUTPUTS;


PROCEDURE refresh_TRAN_TAXABILITIES
IS
BEGIN
    MERGE /*+ APPEND */
      INTO crapp_extract.TRANSACTION_TAXABILITIES a
           USING (Select * from TRANSACTION_TAXABILITIES where status=2) b
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.juris_tax_applicability_id = b.juris_tax_applicability_id,
            a.applicability_type_id = b.applicability_type_id,
            a.reference_code = b.reference_code,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.rid = b.rid,
            a.nkid = b.nkid,
            a.next_rid = b.next_rid
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.juris_tax_applicability_id, a.applicability_type_id,
             a.reference_code, a.start_date, a.end_date, a.entered_by,
             a.entered_date, a.status, a.status_modified_date, a.rid, a.nkid,
             a.next_rid)
            VALUES (b.id, b.juris_tax_applicability_id, b.applicability_type_id,
            b.reference_code, b.start_date, b.end_date, b.entered_by,
            b.entered_date, b.status, b.status_modified_date, b.rid, b.nkid,
            b.next_rid);
    COMMIT;
END refresh_TRAN_TAXABILITIES;

PROCEDURE refresh_ADMIN_ATTRIBUTES
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.administrator_attributes;

    MERGE /*+ APPEND */
      INTO crapp_extract.ADMINISTRATOR_ATTRIBUTES a
           USING (SELECT * FROM ADMINISTRATOR_ATTRIBUTES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM ADMINISTRATOR_ATTRIBUTES
                                                WHERE status = 2
                                                      AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.administrator_id = b.administrator_id,
            a.administrator_nkid = b.administrator_nkid,
            a.attribute_id = b.attribute_id,
            a.value = b.value,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.rid = b.rid,
            a.nkid = b.nkid,
            a.next_rid = b.next_rid,
            a.start_date = b.start_date,
            a.end_date = b.end_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.administrator_id, a.administrator_nkid,a.attribute_id, a.value, a.entered_by,
             a.entered_date, a.rid, a.nkid, a.next_rid, a.start_date,
             a.end_date, a.status, a.status_modified_date)
            VALUES (b.id, b.administrator_id, b.administrator_nkid,b.attribute_id, b.value, b.entered_by,
            b.entered_date, b.rid, b.nkid, b.next_rid, b.start_date,
            b.end_date, b.status, b.status_modified_date);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('ADMINISTRATOR_ATTRIBUTES l_ct: '||l_ct);

    COMMIT;
END refresh_ADMIN_ATTRIBUTES;

PROCEDURE refresh_ADMIN_TAGS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.administrator_tags;

    MERGE /*+ APPEND */
      INTO crapp_extract.ADMINISTRATOR_TAGS a
           USING (SELECT * FROM ADMINISTRATOR_TAGS
                  WHERE status = 2 AND ref_nkid IN (SELECT DISTINCT ref_nkid FROM ADMINISTRATOR_TAGS
                                                    WHERE status = 2
                                                          AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                   )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.ref_nkid = b.ref_nkid,
            a.tag_id = b.tag_id,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.first_etl_rid = b.first_etl_rid,
            a.last_etl_rid = b.last_etl_rid
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.ref_nkid, a.tag_id, a.entered_by, a.entered_date,
             a.status, a.status_modified_date, a.first_etl_rid,
             a.last_etl_rid)
            VALUES (b.id, b.ref_nkid, b.tag_id, b.entered_by, b.entered_date,
            b.status, b.status_modified_date, b.first_etl_rid,
            b.last_etl_rid);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('ADMINISTRATOR_TAGS l_ct: '||l_ct);

    COMMIT;
END refresh_ADMIN_TAGS;

PROCEDURE refresh_JURIS_TAGS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.jurisdiction_tags;

    MERGE /*+ APPEND */
      INTO crapp_extract.JURISDICTION_TAGS a
           USING (SELECT * FROM JURISDICTION_TAGS
                  WHERE status = 2 AND ref_nkid IN (SELECT DISTINCT ref_nkid FROM JURISDICTION_TAGS
                                                    WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                   )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.ref_nkid = b.ref_nkid,
            a.tag_id = b.tag_id,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.first_etl_id = b.first_etl_id,
            a.last_etl_id = b.last_etl_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.ref_nkid, a.tag_id, a.entered_by, a.entered_date,
             a.status, a.status_modified_date, a.first_etl_id,
             a.last_etl_id)
            VALUES (b.id, b.ref_nkid, b.tag_id, b.entered_by, b.entered_date,
            b.status, b.status_modified_date, b.first_etl_id,
            b.last_etl_id);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURISDICTION_TAGS l_ct: '||l_ct);

    COMMIT;
END refresh_JURIS_TAGS;

PROCEDURE refresh_TAX_TAGS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_imposition_tags;

    MERGE /*+ APPEND */
      INTO crapp_extract.JURIS_TAX_IMPOSITION_TAGS a
           USING (SELECT * FROM JURIS_TAX_IMPOSITION_TAGS
                  WHERE status = 2 AND ref_nkid IN (SELECT DISTINCT ref_nkid FROM JURIS_TAX_IMPOSITION_TAGS
                                                    WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                   )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.ref_nkid = b.ref_nkid,
            a.tag_id = b.tag_id,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.first_etl_id = b.first_etl_id,
            a.last_etl_id = b.last_etl_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.ref_nkid, a.tag_id, a.entered_by, a.entered_date,
             a.status, a.status_modified_date, a.first_etl_id,
             a.last_etl_id)
            VALUES (b.id, b.ref_nkid, b.tag_id, b.entered_by, b.entered_date,
            b.status, b.status_modified_date, b.first_etl_id,
            b.last_etl_id);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_IMPOSITION_TAGS l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_TAGS;

PROCEDURE refresh_commodity_TAGS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.commodity_tags;

    MERGE /*+ APPEND */
      INTO crapp_extract.COMMODITY_TAGS a
           USING (SELECT * FROM COMMODITY_TAGS
                  WHERE status = 2 AND ref_nkid IN (SELECT DISTINCT ref_nkid FROM COMMODITY_TAGS
                                                    WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                   )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.ref_nkid = b.ref_nkid,
            a.tag_id = b.tag_id,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.first_etl_id = b.first_etl_id,
            a.last_etl_id = b.last_etl_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.ref_nkid, a.tag_id, a.entered_by, a.entered_date,
             a.status, a.status_modified_date, a.first_etl_id,
             a.last_etl_id)
            VALUES (b.id, b.ref_nkid, b.tag_id, b.entered_by, b.entered_date,
            b.status, b.status_modified_date, b.first_etl_id,
            b.last_etl_id);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('COMMODITY_TAGS l_ct: '||l_ct);

    COMMIT;
END refresh_commodity_TAGS;

/*
PROCEDURE refresh_comm_group_TAGS
IS
BEGIN
  MERGE + APPEND
      INTO crapp_extract.commodity_group_TAGS a
           USING (Select * from commodity_group_TAGS where status=2) b
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.ref_nkid = b.ref_nkid,
            a.tag_id = b.tag_id,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.first_etl_id = b.first_etl_id,
            a.last_etl_id = b.last_etl_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.ref_nkid, a.tag_id, a.entered_by, a.entered_date,
             a.status, a.status_modified_date, a.first_etl_id,
             a.last_etl_id)
            VALUES (b.id, b.ref_nkid, b.tag_id, b.entered_by, b.entered_date,
            b.status, b.status_modified_date, b.first_etl_id,
            b.last_etl_id);
  Commit;
END refresh_comm_group_TAGS;
*/

PROCEDURE refresh_TAXABILITY_TAGS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_app_tags;

    MERGE /*+ APPEND */
      INTO crapp_extract.JURIS_TAX_APP_TAGS a
           USING (SELECT * FROM JURIS_TAX_APP_TAGS
                  WHERE status = 2 AND ref_nkid IN (SELECT DISTINCT ref_nkid FROM JURIS_TAX_APP_TAGS
                                                    WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                   )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.ref_nkid = b.ref_nkid,
            a.tag_id = b.tag_id,
            a.entered_by = b.entered_by,
            a.entered_date = b.entered_date,
            a.status = b.status,
            a.status_modified_date = b.status_modified_date,
            a.first_etl_id = b.first_etl_id,
            a.last_etl_id = b.last_etl_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.ref_nkid, a.tag_id, a.entered_by, a.entered_date,
             a.status, a.status_modified_date, a.first_etl_id,
             a.last_etl_id)
            VALUES (b.id, b.ref_nkid, b.tag_id, b.entered_by, b.entered_date,
            b.status, b.status_modified_date, b.first_etl_id,
            b.last_etl_id);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_APP_TAGS l_ct: '||l_ct);

    COMMIT;
END refresh_TAXABILITY_TAGS;

PROCEDURE refresh_REF_GROUP_TAGS
IS
BEGIN
-- min impact
    execute immediate 'truncate table crapp_extract.REF_GROUP_TAGS drop storage';
    insert into crapp_extract.ref_group_tags (id, ref_nkid, tag_id, entered_by, entered_date, status, status_modified_date)
    (
    select id, ref_nkid, tag_id, entered_by, entered_date, status, status_modified_date
    from ref_group_tags
    where status=2
    );
    COMMIT;
END refresh_REF_GROUP_TAGS;


PROCEDURE refresh_JURIS_TAX_DESCS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_descriptions;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.JURIS_TAX_DESCRIPTIONS a
           USING (SELECT * FROM JURIS_TAX_DESCRIPTIONS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM JURIS_TAX_DESCRIPTIONS
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.rid=b.rid,
            a.nkid=b.nkid,
            a.next_rid=b.next_rid,
            a.jurisdiction_id=b.jurisdiction_id,
            a.jurisdiction_nkid=b.jurisdiction_nkid,
            a.tax_description_id=b.tax_description_id,
            a.start_date=b.start_date,
            a.end_date=b.end_date,
            a.entered_date=b.entered_date,
            a.status_modified_date=b.status_modified_date,
            a.entered_by=b.entered_by,
            a.status=b.status
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.rid, a.nkid, a.next_rid, a.jurisdiction_id, a.jurisdiction_nkid,
             a.tax_description_id, a.start_date, a.end_date, a.entered_date,
             a.status_modified_date, a.entered_by, a.status
            )
            VALUES (b.id, b.rid, b.nkid, b.next_rid, b.jurisdiction_id, b.jurisdiction_nkid,
            b.tax_description_id, b.start_date, b.end_date, b.entered_date,
            b.status_modified_date, b.entered_by, b.status
            );

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_DESCRIPTIONS l_ct: '||l_ct);

    COMMIT;
END refresh_JURIS_TAX_DESCS;


PROCEDURE refresh_JURIS_TAX_IMPOSITIONS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_impositions;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.JURIS_TAX_IMPOSITIONS a
           USING (SELECT * FROM JURIS_TAX_IMPOSITIONS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM JURIS_TAX_IMPOSITIONS
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.jurisdiction_id=b.jurisdiction_id,
            a.jurisdiction_nkid=b.jurisdiction_nkid,
            a.tax_description_id=b.tax_description_id,
            a.reference_code=b.reference_code,
            a.start_date=b.start_date,
            a.end_date=b.end_date,
            a.entered_by=b.entered_by,
            a.entered_date=b.entered_date,
            a.rid=b.rid,
            a.nkid=b.nkid,
            a.next_rid=b.next_rid,
            a.status=b.status,
            a.status_modified_date=b.status_modified_date,
            a.description=b.description,
            a.revenue_purpose_id=b.revenue_purpose_id
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.jurisdiction_id, a.tax_description_id, a.reference_code,
       a.start_date, a.end_date, a.entered_by, a.entered_date, a.rid,
       a.nkid, a.next_rid, a.status, a.status_modified_date,
       a.description, a.revenue_purpose_id, a.jurisdiction_nkid
            )
            VALUES (b.id, b.jurisdiction_id, b.tax_description_id, b.reference_code,
       b.start_date, b.end_date, b.entered_by, b.entered_date, b.rid,
       b.nkid, b.next_rid, b.status, b.status_modified_date,
       b.description, b.revenue_purpose_id, b.jurisdiction_nkid
            );

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_IMPOSITIONS l_ct: '||l_ct);

    COMMIT;
END refresh_JURIS_TAX_IMPOSITIONS;

PROCEDURE refresh_TAX_ADMINISTRATORS
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_administrators;

    MERGE /*+ APPEND */
        INTO crapp_extract.TAX_ADMINISTRATORS a
             USING (SELECT * FROM TAX_ADMINISTRATORS
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAX_ADMINISTRATORS
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.rid=b.rid,
              a.juris_tax_imposition_id=b.juris_tax_imposition_id,
              a.juris_tax_imposition_nkid=b.juris_tax_imposition_nkid,
              a.administrator_id=b.administrator_id,
              a.administrator_nkid=b.administrator_nkid,
              a.location_id=b.location_id,
              a.start_date=b.start_date,
              a.end_date=b.end_date,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.nkid=b.nkid,
              a.next_rid=b.next_rid,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date,
              a.collector_id=b.collector_id
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.rid, a.juris_tax_imposition_id, a.juris_tax_imposition_nkid,a.administrator_id, a.administrator_nkid,
       a.location_id, a.start_date, a.end_date, a.entered_by,
       a.entered_date, a.nkid, a.next_rid, a.status,
       a.status_modified_date, a.collector_id
              )
              VALUES (b.id, b.rid, b.juris_tax_imposition_id, b.juris_tax_imposition_nkid,b.administrator_id, b.administrator_nkid,
       b.location_id, b.start_date, b.end_date, b.entered_by,
       b.entered_date, b.nkid, b.next_rid, b.status,
       b.status_modified_date, b.collector_id
              );

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_ADMINISTRATORS l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_ADMINISTRATORS;


PROCEDURE refresh_ADMINISTRATOR_CONTACTS
IS
BEGIN
    execute immediate 'Truncate Table crapp_extract.ADMINISTRATOR_CONTACTS drop storage';
    execute immediate 'Insert Into crapp_extract.ADMINISTRATOR_CONTACTS (select * from ADMINISTRATOR_CONTACTS where status=2)';
END refresh_ADMINISTRATOR_CONTACTS;


PROCEDURE refresh_TAX_REGISTRATIONS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_registrations;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAX_REGISTRATIONS a
           USING (SELECT * FROM TAX_REGISTRATIONS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAX_REGISTRATIONS
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.administrator_id=b.administrator_id,
            a.administrator_nkid=b.administrator_nkid,
            a.registration_mask=b.registration_mask,
            a.start_date=b.start_date,
            a.end_date=b.end_date,
            a.entered_by=b.entered_by,
            a.entered_date=b.entered_date,
            a.rid=b.rid,
            a.nkid=b.nkid,
            a.next_rid=b.next_rid,
            a.status=b.status,
            a.status_modified_date=b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.administrator_id, a.administrator_nkid,a.registration_mask, a.start_date, a.end_date,
             a.entered_by, a.entered_date, a.rid, a.nkid, a.next_rid, a.status, a.status_modified_date)
            VALUES (b.id, b.administrator_id, b.administrator_nkid, b.registration_mask, b.start_date, b.end_date,
            b.entered_by, b.entered_date, b.rid, b.nkid, b.next_rid, b.status, b.status_modified_date);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_REGISTRATIONS l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_REGISTRATIONS;


PROCEDURE refresh_TAX_ATTRIBUTES
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_attributes;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAX_ATTRIBUTES a
           USING (SELECT * FROM TAX_ATTRIBUTES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAX_ATTRIBUTES
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.rid=b.rid,
            a.juris_tax_imposition_id=b.juris_tax_imposition_id,
            a.juris_tax_imposition_nkid=b.juris_tax_imposition_nkid,
            a.start_date=b.start_date,
            a.end_date=b.end_date,
            a.entered_by=b.entered_by,
            a.entered_date=b.entered_date,
            a.attribute_id=b.attribute_id,
            a.value=b.value,
            a.nkid=b.nkid,
            a.next_rid=b.next_rid,
            a.status=b.status,
            a.status_modified_date=b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.rid, a.juris_tax_imposition_id, a.juris_tax_imposition_nkid,a.start_date, a.end_date,
             a.entered_by, a.entered_date, a.attribute_id, a.value, a.nkid,
             a.next_rid, a.status, a.status_modified_date)
            VALUES (b.id, b.rid, b.juris_tax_imposition_id, b.juris_tax_imposition_nkid,b.start_date, b.end_date,
            b.entered_by, b.entered_date, b.attribute_id, b.value, b.nkid,
            b.next_rid, b.status, b.status_modified_date);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_ATTRIBUTES l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_ATTRIBUTES;

PROCEDURE refresh_JURIS_TAX_APP_ATTS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_app_attributes;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.JURIS_TAX_APP_ATTRIBUTES a
           USING (SELECT * FROM JURIS_TAX_APP_ATTRIBUTES
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM JURIS_TAX_APP_ATTRIBUTES
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.rid=b.rid,
            a.juris_tax_applicability_id=b.juris_tax_applicability_id,
            a.juris_tax_applicability_nkid=b.juris_tax_applicability_nkid,
            a.start_date=b.start_date,
            a.end_date=b.end_date,
            a.entered_by=b.entered_by,
            a.entered_date=b.entered_date,
            a.attribute_id=b.attribute_id,
            a.value=b.value,
            a.nkid=b.nkid,
            a.next_rid=b.next_rid,
            a.status=b.status,
            a.status_modified_date=b.status_modified_date
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.rid, a.juris_tax_applicability_id, a.start_date, a.end_date,
             a.entered_by, a.entered_date, a.attribute_id, a.value, a.nkid,
             a.next_rid, a.status, a.status_modified_date, a.juris_tax_applicability_nkid)
            VALUES (b.id, b.rid, b.juris_tax_applicability_id, b.start_date, b.end_date,
            b.entered_by, b.entered_date, b.attribute_id, b.value, b.nkid,
            b.next_rid, b.status, b.status_modified_date, b.juris_tax_applicability_nkid);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_APP_ATTRIBUTES l_ct: '||l_ct);

    COMMIT;
END refresh_JURIS_TAX_APP_ATTS;

PROCEDURE refresh_REVENUE_PURPOSES
IS
BEGIN
-- stat
    execute immediate 'Truncate Table crapp_extract.REVENUE_PURPOSES drop storage';
    execute immediate 'Insert Into crapp_extract.REVENUE_PURPOSES (select * from REVENUE_PURPOSES where status=2)';
END refresh_REVENUE_PURPOSES;

PROCEDURE refresh_TAX_DEFINITIONS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_definitions;
    */

    MERGE /*+ APPEND */
      INTO crapp_extract.TAX_DEFINITIONS a
           USING (SELECT * FROM TAX_DEFINITIONS
                  WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM TAX_DEFINITIONS
                                                WHERE status = 2
                                                      -- crapp-3028, now pulling the past 60 days
                                                      AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                                               )
                 ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
              ON (a.id = b.id)
            WHEN MATCHED THEN UPDATE
            SET
            a.rid=b.rid,
            a.min_threshold=b.min_threshold,
            a.max_limit=b.max_limit,
            a.value_type=b.value_type,
            a.value=b.value,
            a.defer_to_juris_tax_id=b.defer_to_juris_tax_id,
             a.defer_to_juris_tax_nkid=b.defer_to_juris_tax_nkid,
            a.currency_id=b.currency_id,
            a.entered_by=b.entered_by,
            a.entered_date=b.entered_date,
            a.nkid=b.nkid,
            a.next_rid=b.next_rid,
            a.status=b.status,
            a.status_modified_date=b.status_modified_date,
            a.tax_outline_id=b.tax_outline_id,
            a.tax_outline_nkid=b.tax_outline_nkid
            WHEN NOT MATCHED THEN INSERT
            (a.id, a.rid, a.min_threshold, a.max_limit, a.value_type, a.value,
       a.defer_to_juris_tax_id, a.defer_to_juris_tax_nkid,a.currency_id, a.entered_by,
       a.entered_date, a.nkid, a.next_rid, a.status,
       a.status_modified_date, a.tax_outline_id, a.tax_outline_nkid)
            VALUES (b.id, b.rid, b.min_threshold, b.max_limit, b.value_type, b.value,
       b.defer_to_juris_tax_id, b.defer_to_juris_tax_nkid,b.currency_id, b.entered_by,
       b.entered_date, b.nkid, b.next_rid, b.status,
       b.status_modified_date, b.tax_outline_id, b.tax_outline_nkid);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_DEFINITIONS l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_DEFINITIONS;


PROCEDURE refresh_TAX_RELATIONSHIPS
IS
    --l_entdt TIMESTAMP(6);
    --l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    -- crapp-3028, removed - now pulling the past 60 days
    /*
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.tax_relationships;
    */

    MERGE /*+ APPEND */
        INTO crapp_extract.TAX_RELATIONSHIPS a
             USING (SELECT * FROM TAX_RELATIONSHIPS
                    WHERE status = 2
                          -- crapp-3028, now pulling the past 60 days
                          AND (entered_date > SYSDATE-60 OR status_modified_date > SYSDATE-60)
                   ) b
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
               --a.id                 = b.id,   -- 06/03/16 removed, cannot update columns referenced in ON clause
               a.jurisdiction_id    = b.jurisdiction_id,
               a.jurisdiction_nkid  = b.jurisdiction_nkid,
               a.jurisdiction_rid   = b.jurisdiction_rid,
               a.related_jurisdiction_id = b.related_jurisdiction_id,
               a.related_jurisdiction_nkid  = b.related_jurisdiction_nkid,
               a.relationship_type   = b.relationship_type,
               a.entered_by          = b.entered_by,
               a.entered_date        = b.entered_date,
               a.start_date          = b.start_date,
               a.end_date            = b.end_date,
               a.status              = b.status,
               a.status_modified_date = b.status_modified_date,
               a.basis_percent       = b.basis_percent
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.jurisdiction_id, a.jurisdiction_nkid, a.jurisdiction_rid,
       a.related_jurisdiction_id, a.related_jurisdiction_nkid,
       a.relationship_type, a.entered_by, a.entered_date, a.start_date,
       a.end_date, a.status, a.status_modified_date, a.basis_percent)
              VALUES (b.id, b.jurisdiction_id, b.jurisdiction_nkid, b.jurisdiction_rid,
       b.related_jurisdiction_id, b.related_jurisdiction_nkid,
       b.relationship_type,  b.entered_by, b.entered_date, b.start_date,
       b.end_date, b.status, b.status_modified_date, b.basis_percent);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('TAX_RELATIONSHIPS l_ct: '||l_ct);

    COMMIT;
END refresh_TAX_RELATIONSHIPS;


PROCEDURE refresh_administrators
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.administrators;

    MERGE /*+ APPEND */
        INTO crapp_extract.ADMINISTRATORS a
             USING (SELECT * FROM ADMINISTRATORS
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM ADMINISTRATORS
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                   ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.rid=b.rid,
              a.name=b.name,
              a.start_date=b.start_date,
              a.end_date=b.end_date,
              a.requires_registration=b.requires_registration,
              a.collects_tax=b.collects_tax,
              a.notes=b.notes,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.nkid=b.nkid,
              a.next_rid=b.next_rid,
              a.description=b.description,
              a.administrator_type_id=b.administrator_type_id,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.rid, a.name, a.start_date, a.end_date,
               a.requires_registration, a.collects_tax, a.notes, a.entered_by,
               a.entered_date, a.nkid, a.next_rid, a.description,
               a.administrator_type_id, a.status, a.status_modified_date)
              VALUES (b.id, b.rid, b.name, b.start_date, b.end_date,
              b.requires_registration, b.collects_tax, b.notes, b.entered_by,
              b.entered_date, b.nkid, b.next_rid, b.description,
              b.administrator_type_id, b.status, b.status_modified_date);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('ADMINISTRATORS l_ct: '||l_ct);

    COMMIT;
END refresh_administrators;

PROCEDURE refresh_admin_revisions
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.administrator_revisions;

    MERGE /*+ APPEND */
        INTO crapp_extract.administrator_revisions a
             USING (SELECT * FROM administrator_revisions
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM administrator_revisions
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                   ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.nkid=b.nkid,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date,
              a.next_rid=b.next_rid,
              a.summ_ass_status=b.summ_ass_status
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.nkid, a.entered_by, a.entered_date, a.status,
       a.status_modified_date, a.next_rid, a.summ_ass_status)
              VALUES (b.id, b.nkid, b.entered_by, b.entered_date, b.status,
       b.status_modified_date, b.next_rid, b.summ_ass_status);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('ADMINISTRATOR_REVISIONS l_ct: '||l_ct);

    COMMIT;
END refresh_admin_revisions;

PROCEDURE refresh_juris_revisions
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.jurisdiction_revisions;

    MERGE /*+ APPEND */
        INTO crapp_extract.jurisdiction_revisions a
             USING (SELECT * FROM jurisdiction_revisions
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM jurisdiction_revisions
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                   ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.nkid=b.nkid,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date,
              a.next_rid=b.next_rid,
              a.summ_ass_status=b.summ_ass_status
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.nkid, a.entered_by, a.entered_date, a.status,
       a.status_modified_date, a.next_rid, a.summ_ass_status)
              VALUES (b.id, b.nkid, b.entered_by, b.entered_date, b.status,
       b.status_modified_date, b.next_rid, b.summ_ass_status);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURISDICTION_REVISIONS l_ct: '||l_ct);

    COMMIT;
END refresh_juris_revisions;

PROCEDURE refresh_tax_revisions
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.jurisdiction_tax_revisions;

    MERGE /*+ APPEND */
        INTO crapp_extract.jurisdiction_tax_revisions a
             USING (SELECT * FROM jurisdiction_tax_revisions
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM jurisdiction_tax_revisions
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                   ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.nkid=b.nkid,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date,
              a.next_rid=b.next_rid,
              a.summ_ass_status=b.summ_ass_status
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.nkid, a.entered_by, a.entered_date, a.status,
       a.status_modified_date, a.next_rid, a.summ_ass_status)
              VALUES (b.id, b.nkid, b.entered_by, b.entered_date, b.status,
       b.status_modified_date, b.next_rid, b.summ_ass_status);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURISDICTION_TAX_REVISIONS l_ct: '||l_ct);

    COMMIT;
END refresh_tax_revisions;

PROCEDURE refresh_taxability_revisions
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.juris_tax_app_revisions;

    MERGE /*+ APPEND */
        INTO crapp_extract.juris_tax_app_revisions a
             USING (SELECT * FROM juris_tax_app_revisions
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM juris_tax_app_revisions
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                   ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.nkid=b.nkid,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date,
              a.next_rid=b.next_rid,
              a.summ_ass_status=b.summ_ass_status
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.nkid, a.entered_by, a.entered_date, a.status,
       a.status_modified_date, a.next_rid, a.summ_ass_status)
              VALUES (b.id, b.nkid, b.entered_by, b.entered_date, b.status,
       b.status_modified_date, b.next_rid, b.summ_ass_status);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('JURIS_TAX_APP_REVISIONS l_ct: '||l_ct);

    COMMIT;
END refresh_taxability_revisions;

PROCEDURE refresh_commodity_revisions
IS
    l_entdt TIMESTAMP(6);
    l_stdt  TIMESTAMP(6);
    l_ct    NUMBER := 0;
BEGIN
    SELECT MAX(entered_date) last_entered_dt, MAX(status_modified_date) last_status_dt
    INTO l_entdt, l_stdt
    FROM crapp_extract.commodity_revisions;

    MERGE /*+ APPEND */
        INTO crapp_extract.commodity_revisions a
             USING (SELECT * FROM commodity_revisions
                    WHERE status = 2 AND nkid IN (SELECT DISTINCT nkid FROM commodity_revisions
                                                  WHERE status = 2 AND (entered_date > l_entdt OR status_modified_date > l_stdt)
                                                 )
                   ) b   -- crapp-2679 filtering by Entered_Date or Status_Modified_Date
                ON (a.id = b.id)
              WHEN MATCHED THEN UPDATE
              SET
              a.nkid=b.nkid,
              a.entered_by=b.entered_by,
              a.entered_date=b.entered_date,
              a.status=b.status,
              a.status_modified_date=b.status_modified_date,
              a.next_rid=b.next_rid,
              a.summ_ass_status=b.summ_ass_status
              WHEN NOT MATCHED THEN INSERT
              (a.id, a.nkid, a.entered_by, a.entered_date, a.status,
       a.status_modified_date, a.next_rid, a.summ_ass_status)
              VALUES (b.id, b.nkid, b.entered_by, b.entered_date, b.status,
       b.status_modified_date, b.next_rid, b.summ_ass_status);

    l_ct := l_ct + (SQL%ROWCOUNT);
    dbms_output.put_line('COMMODITY_REVISIONS l_ct: '||l_ct);

    COMMIT;
END refresh_commodity_revisions;

PROCEDURE push_administrators
IS
BEGIN
    refresh_ADMIN_ATTRIBUTES;
    refresh_ADMINISTRATOR_CONTACTS;
    refresh_administrators;
    refresh_admin_revisions;
    refresh_ADMIN_TAGS;
    refresh_TAX_REGISTRATIONS;

    /*
    Plan-->
    UPDATE STATEMENT
    Cost: 6  Bytes: 17  Cardinality: 1  CPU Cost: 0  IO Cost: 0
    Partition #: 0
        4 UPDATE CRAPP_EXTRACT.ADMINISTRATOR_REVISIONS
        Cost: 0  Bytes: 0  Cardinality: 0  CPU Cost: 0  IO Cost: 0
        Partition #: 0
           3 NESTED LOOPS ANTI
           Cost: 6  Bytes: 17  Cardinality: 1  CPU Cost: 0  IO Cost: 0
           Partition #: 0
              1 TABLE ACCESS FULL CRAPP_EXTRACT.ADMINISTRATOR_REVISIONS [Analyzed]
              Cost: 6  Bytes: 13  Cardinality: 1  CPU Cost: 0  IO Cost: 0
              Partition #: 0
              2 INDEX UNIQUE SCAN CRAPP_EXTRACT.ADMINISTRATOR_REVISIONS_PK [Analyzed]
              Cost: 0  Bytes: 4  Cardinality: 1  CPU Cost: 0  IO Cost: 0
              Partition #: 0
    */
    update crapp_extract.administrator_revisions r2
    set next_rid = null
    where next_rid is not null
    and not exists (
        select 1
        from crapp_extract.administrator_revisions r
        where r.id = r2.next_rid
        );
    commit;
END push_administrators;

PROCEDURE push_jurisdictions
IS
BEGIN
    refresh_juris_ATTRIBUTES;
    refresh_juris_tax_descs;
    refresh_jurisdictions;
    refresh_juris_revisions;
    refresh_JURIS_TAGS;
    refresh_TAX_RELATIONSHIPS;    -- Now jurisdiction level process

    update crapp_extract.jurisdiction_revisions r2
    set next_rid = null
    where next_rid is not null
    and not exists (
        select 1
        from crapp_extract.jurisdiction_revisions r
        where r.id = r2.next_rid
        );
    commit;
END push_jurisdictions;

PROCEDURE push_taxes
IS
BEGIN
    refresh_tax_ATTRIBUTES;
    refresh_tax_definitions;
    refresh_tax_outlines;
    refresh_juris_tax_impositions;
    refresh_TAX_ADMINISTRATORS;
    refresh_tax_revisions;
    refresh_tax_tags;

    update crapp_extract.jurisdiction_tax_revisions r2
    set next_rid = null
    where next_rid is not null
    and not exists (
        select 1
        from crapp_extract.jurisdiction_tax_revisions r
        where r.id = r2.next_rid
        );
    commit;
END push_taxes;

PROCEDURE push_taxabilities
IS
BEGIN
    refresh_juris_tax_app_ATTS;
    refresh_juris_tax_apps;
    refresh_tax_app_taxes;
    --refresh_TAX_RELATIONSHIPS;    -- Now jurisdiction level process
    refresh_TAXABILITY_OUTPUTS;
    refresh_TRAN_TAX_QUALIFIERS;
    refresh_taxability_revisions;
    refresh_taxability_tags;

    update crapp_extract.juris_tax_app_revisions r2
    set next_rid = null
    where next_rid is not null
    and not exists (
        select 1
        from crapp_extract.juris_tax_app_revisions r
        where r.id = r2.next_rid
        );
    commit;
END push_taxabilities;

PROCEDURE push_commodities
IS
BEGIN
    refresh_commodities;
    refresh_commodity_revisions;
    refresh_commodity_tags;

    update crapp_extract.commodity_revisions r2
    set next_rid = null
    where next_rid is not null
    and not exists (
        select 1
        from crapp_extract.commodity_revisions r
        where r.id = r2.next_rid
        );
    commit;
END push_commodities;

PROCEDURE push_reference_groups
IS
BEGIN
    refresh_reference_groups;
    refresh_reference_items;
    refresh_ref_group_revisions;
    refresh_REF_GROUP_TAGS;

    update crapp_extract.ref_group_revisions r2
    set next_rid = null
    where next_rid is not null
    and not exists (
        select 1
        from crapp_extract.ref_group_revisions r
        where r.id = r2.next_rid
        );
    commit;
END push_reference_groups;

PROCEDURE push_tags
IS
BEGIN
    refresh_TAGS;
END push_tags;




PROCEDURE push_lookups
IS
BEGIN
    refresh_ADDITIONAL_ATTRIBUTES;
    refresh_ADMINISTRATOR_TYPES;
    refresh_AMOUNT_TYPES;
    refresh_APPLICABILITY_TYPES;
    refresh_ATTRIBUTE_CATEGORIES;
    refresh_ATTRIBUTE_LOOKUPS;
    refresh_CALCULATION_METHODS;
    refresh_CURRENCIES;
    refresh_HIERARCHY_DEFINITIONS;
    refresh_LANGUAGES;
    refresh_geo_area_categories;
    refresh_hierarchy_levels;
    refresh_LOGICAL_QUALIFIERS;
    refresh_PACKAGES;
    refresh_PRODUCT_TREES;
    refresh_RECORD_STATUSES;
    refresh_REFERENCE_GROUPS;
    refresh_REVENUE_PURPOSES;
    refresh_SPEC_APP_TYPES;
    refresh_TAG_TYPES;
    refresh_TAX_CALC_STRUCTURES;
    refresh_TAX_STRUCTURE_TYPES;
    refresh_TAXABILITY_ELEMENTS;
    refresh_TAXATION_TYPES;
    refresh_TRANSACTION_TYPES;
    refresh_tax_descriptions;
END push_lookups;


END post_publish;
/