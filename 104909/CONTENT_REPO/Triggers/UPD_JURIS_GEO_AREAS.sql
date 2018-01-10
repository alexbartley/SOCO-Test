CREATE OR REPLACE TRIGGER content_repo."UPD_JURIS_GEO_AREAS"
FOR UPDATE
 ON content_repo.juris_geo_areas
REFERENCING NEW AS NEW OLD AS OLD
COMPOUND TRIGGER

    TYPE mod_records IS TABLE OF juris_geo_areas%ROWTYPE;
    pending_changes mod_records := mod_records(); --collection of record updates in this transaction

    BEFORE EACH ROW IS
        l_new juris_geo_areas%ROWTYPE;
        l_changed BOOLEAN := FALSE;
    BEGIN
        --check the entity fields for modification:
        --if a field was not modified, preserve the original value in the new record
        --Also, use flag to indicate whether or not this entity is being modified.
        /*IF updating('JURISDICTION_ID') AND :new.jurisdiction_id != :old.jurisdiction_id THEN
            l_new.jurisdiction_id := :new.jurisdiction_id;
            l_changed := TRUE;
        ELSE
            l_new.jurisdiction_id := :old.jurisdiction_id;
        END IF;

        IF updating('GEO_POLYGON_ID') AND :new.geo_polygon_id != :old.geo_polygon_id THEN
            l_new.geo_polygon_id := :new.geo_polygon_id;
            l_changed := TRUE;
        ELSE
            l_new.geo_polygon_id := :old.geo_polygon_id;
        END IF;*/

        IF updating('START_DATE') AND NVL(:new.start_date, '31-Dec-9999') !=  NVL(:old.start_date, '31-Dec-9999')  THEN
            l_new.start_date := :new.start_date;
            l_changed := TRUE;
        ELSE
            l_new.start_date := :old.start_date;
        END IF;

        IF updating('END_DATE') AND NVL(:new.end_date, '31-Dec-9999') !=  NVL(:old.end_date, '31-Dec-9999') THEN
            l_new.end_date := :new.end_date;
            l_changed := TRUE;
        ELSE
            l_new.end_date := :old.end_date;
        END IF;

        IF updating('REQUIRES_ESTABLISHMENT') AND :new.requires_establishment != :old.requires_establishment THEN
            l_new.requires_establishment := :new.requires_establishment;
            l_changed := TRUE;
        ELSE
            l_new.requires_establishment := :old.requires_establishment;
        END IF;

        l_new.geo_polygon_id := :old.geo_polygon_id;
        l_new.jurisdiction_id := :old.jurisdiction_id;
        l_new.geo_polygon_nkid := :old.geo_polygon_nkid;
        l_new.jurisdiction_nkid := :old.jurisdiction_nkid;
        l_new.nkid := :old.nkid;
        l_new.entered_by := :new.entered_by;

        IF NOT l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --do nothing, let changes occur on Status (and potentially ID, NKID, RID, NEXT_RID, Entered_By be changed)
            :new.status_modified_date := SYSTIMESTAMP;
        ELSIF l_changed AND (UPDATING('STATUS') OR UPDATING('NEXT_RID')) THEN
            --if it has changed and the status has also changed, raise error, record and status cannot be modified at the same time
            RAISE errnums.cannot_update_record;
        ELSIF l_changed THEN
            IF (:new.jurisdiction_id != :old.jurisdiction_id OR :new.geo_polygon_id != :old.geo_polygon_id) THEN
                RAISE errnums.cannot_update_record;
            END IF;
            --get current pending revision
            l_new.rid := gis.get_revision(rid_i => :old.rid, entered_by_i => l_new.entered_by); --assign to new or current revision id

            --regardless of updating or inserting, record gets a new timestamp
            :new.entered_date := SYSTIMESTAMP;

            --If a new revision id was created,
            --abort the update but preserve the new values to be inserted as a new record
            IF (l_new.rid != :old.rid) THEN
                --add the new values to pending_changes
                l_new.id := pk_juris_geo_areas.nextval; --new ID
                l_new.next_rid := NULL; --not assigned for new records
                l_new.status := NULL; --let insert trigger or default handle status
                pending_changes.extend;
                pending_changes(pending_changes.last) := l_new;

                --reset the values, except next_rid
                :new.id := :old.id;
                :new.jurisdiction_id := :old.jurisdiction_id;
                :new.jurisdiction_nkid := :old.jurisdiction_nkid;
                :new.geo_polygon_id := :old.geo_polygon_id;
                :new.geo_polygon_nkid := :old.geo_polygon_nkid;
                :new.start_date := :old.start_date;
                :new.end_date := :old.end_date;
                :new.requires_establishment := :old.requires_establishment;
                :new.rid := :old.rid;
                :new.nkid := :old.nkid;
                :new.next_rid := l_new.rid; --point the next_rid to the new revision
                :new.status := :old.status;
                :new.entered_by := :old.entered_by;
                :new.entered_date := :old.entered_date;
                :new.status_modified_date := :old.status_modified_date;
            ELSE
                UPDATE geo_poly_ref_chg_logs
                SET entered_by = :new.entered_by,
                    entered_date = :new.entered_date
                WHERE table_name = 'JURIS_GEO_AREAS'
                      AND primary_key = :old.id;
                UPDATE GEO_POLY_REF_QR
                SET qr = (select official_name from jurisdictions where nkid = :new.jurisdiction_nkid and next_Rid is null), entered_by = :new.entered_by, entered_date = :new.entered_Date
                WHERE table_name = 'JURIS_GEO_AREAS'
                AND ref_id = :old.id;
            END IF;
        END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        l_pcc NUMBER := pending_changes.COUNT;
    BEGIN
        IF l_pcc > 0 THEN
        FORALL r in 1 .. l_pcc
            INSERT INTO juris_geo_areas (
                jurisdiction_id,
                geo_polygon_id,
                jurisdiction_nkid,
                geo_polygon_nkid,
                start_date,
                end_date,
                requires_establishment,
                rid,
                nkid,
                id,
                entered_by
                )
            VALUES (
                pending_changes(r).jurisdiction_id,
                pending_changes(r).geo_polygon_id,
                pending_changes(r).jurisdiction_nkid,
                pending_changes(r).geo_polygon_nkid,
                pending_changes(r).start_date,
                pending_changes(r).end_date,
                pending_changes(r).requires_establishment,
                pending_changes(r).rid,
                pending_changes(r).nkid,
                pending_changes(r).id,
                pending_changes(r).entered_by
                );
            END IF;
    EXCEPTION
        WHEN others THEN RAISE;
    END AFTER STATEMENT;

END upd_juris_geo_areas;
/