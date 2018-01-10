CREATE OR REPLACE PACKAGE BODY content_repo."CONTACT"
IS
    PROCEDURE XMLProcess_Form_UpdContact(
        sx IN CLOB,
        update_success OUT NUMBER,
        res_id_o OUT number
        )
    IS
    l_reviewed_by NUMBER;
    l_source_id NUMBER;
    l_name research_sources.description%type;
    l_owner research_sources.owner%type;
    l_next_contact_date research_sources.next_contact_date%type;
    l_frequency research_sources.frequency%type;
    l_cont_use_type_id NUMBER;
    l_start_date DATE;
    l_end_Date DATE;
    l_entered_by NUMBER;
    l_contact_methods XMLForm_Contact_tt := XMLForm_Contact_tt();
    l_admin xmlformadministrator;
    l_admin_nkids xmlform_admi_tt := xmlform_admi_tt();
    CLBTemp    CLOB := TO_CHAR(sx);
    l_upd_success NUMBER := 0;
    iStatus number;
    BEGIN
        update_success := 0;
        res_id_o := -1;

    --Get name, reason, start, end
    SELECT
        extractvalue(column_value, '/contact/id') id,
        extractvalue(column_value, '/contact/name') ndt,
        extractvalue(column_value, '/contact/frequency') freq,
        extractvalue(column_value, '/contact/next_contact_date') nextd,
        extractvalue(column_value, '/contact/owner') owner,
        extractvalue(column_value, '/contact/contact_reason') cuti, --contact_usage_type_id
        extractvalue(column_value, '/contact/start_date') dt_start,
        extractvalue(column_value, '/contact/end_date') dt_end,
        extractvalue(column_value, '/contact/entered_by') eb
    INTO
        l_source_id, l_name, l_frequency, l_next_contact_date, l_owner, l_cont_use_type_id, l_start_date, l_end_Date, l_entered_by
    FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/contact'))) t;

    --Get Administrator Nkids to apply the above to
    FOR a IN (
    SELECT
        extractvalue(column_value, 'associated_entities/id') nkid,
        extractvalue(column_value, 'associated_entities/deleted') del
    FROM TABLE(XMLSequence(XMLTYPE(CLBTemp).extract('/contact/associated_entities'))) t
    ) LOOP
        IF (a.nkid IS NOT NULL) THEN
            l_admin_nkids.EXTEND;
            l_admin_nkids(l_admin_nkids.last) :=
            xmlformadministrator(
                NULL,NULL,NULL,NULL,NULL,NULL,
                a.nkid,
                NULL,NULL,NULL,NULL,NULL,0,
                a.del
                );
         END IF;
    END LOOP;

    --Get the Contact_Methods
        FOR contact IN (
            SELECT
                extractvalue(column_value, '/contact_methods/id') id,
                extractvalue(column_value, '/contact_methods/usage_order') ord,
                extractvalue(column_value, '/contact_methods/contact_usage_id') cui,
                extractvalue(column_value, '/contact_methods/contact_usage_type_id') cuti,
                extractvalue(column_value, '/contact_methods/contact_method_id') cti, --contact_type_id
                extractvalue(column_value, '/contact_methods/contact_details') cd,
                extractvalue(column_value, '/contact_methods/contact_language_id') li, --language_id
                extractvalue(column_value, '/contact_methods/contact_notes') cn,
                extractvalue(column_value, '/contact_methods/modified') modif,
                extractvalue(column_value, '/contact_methods/deleted') dl,
                extractvalue(column_value, '/contact_methods/status') sta,
                extractvalue(column_value, '/contact_methods/start_date') cm_start_date,
                extractvalue(column_value, '/contact_methods/end_date') cm_end_date
            FROM TABLE( XMLSequence(XMLTYPE(CLBTemp).extract('/contact/contact_methods'))) t
        ) LOOP
            l_contact_methods.EXTEND;
            l_contact_methods(l_contact_methods.last) :=
            XMLForm_Contact(
                contact.id,
                contact.ord,
                contact.cui,
                contact.cuti,
                contact.cti,
                contact.cd,
                contact.cn,
                contact.li,
                contact.dl,
                contact.modif,
                contact.sta,
                contact.cm_start_date,
                contact.cm_end_date
                );
        END LOOP;
        CONTACT.upd_contacts(l_source_id, l_name, l_frequency, l_next_contact_date, l_owner, l_cont_use_type_id, l_start_date, l_end_Date, l_entered_by, l_contact_methods, l_admin_nkids, iStatus, res_id_o);
        update_success := 1;

     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        update_success := 0;
     WHEN OTHERS THEN -- Caution: Handles all exceptions
        update_success := 0;

    END XMLProcess_Form_UpdContact;

    PROCEDURE delete_all_sources
    AS
    BEGIN
    /* remove all research log information
        delete from juris_chg_cits
        where citation_id in(
        select c.id from citations c, attachments a
        where a.research_log_id is not null
        and c.attachment_id = a.id)

        delete from citations
        where attachment_id in(
        select id from attachments where research_log_id is not null)

        delete from attachments
        where research_log_id is not null;

        delete from research_logs;
    */

      for c in (SELECT ID FROM RESEARCH_SOURCES)
      loop
        contact.delete_source(c.id);
      end loop;
    END delete_all_sources;


    PROCEDURE delete_source
       (
       source_id_i IN NUMBER
       )
       IS
        l_id NUMBER := source_id_i;
        l_associated_contacts NUMBER := 0;

    BEGIN
        --If any of the methods of a source have been used for contact don't delete it
        SELECT count(1)
        INTO l_associated_contacts
        FROM RESEARCH_LOGS WHERE SOURCE_CONTACT_ID IN
        (SELECT ID FROM RESEARCH_SOURCE_CONTACTS WHERE RESEARCH_SOURCE_ID = l_id);

        IF (l_associated_contacts = 0) THEN
          --find all depedent record
          --Remove research_source_tags
          DELETE FROM RESEARCH_SOURCE_TAGS
          WHERE RESEARCH_SOURCE_ID = l_id;
          --Remove contact_usages
          DELETE FROM CONTACT_USAGES
          WHERE RESEARCH_SOURCE_CONTACT_ID IN(
            SELECT ID FROM RESEARCH_SOURCE_CONTACTS WHERE RESEARCH_SOURCE_ID = l_id);
          --Remove research_source_contacts
          DELETE FROM RESEARCH_SOURCE_CONTACTS
          WHERE RESEARCH_SOURCE_ID = l_id;
          --Remove research_sources
          DELETE FROM RESEARCH_SOURCES
          WHERE ID = l_id;

        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record could not be deleted because a contact method has been used to contact/source information.');
        WHEN others THEN
            ROLLBACK;
            dbms_output.put_line(l_id);
            errlogger.report_and_stop(SQLCODE,SQLERRM||'Error because of ID:'||l_id);
    END delete_source;

    PROCEDURE delete_source_contact
       (
       source_contact_id_i IN NUMBER
       )
       IS
        l_id NUMBER := source_contact_id_i;
        l_associated_contacts NUMBER := 0;

    BEGIN
        --If any of the methods of a source have been used for contact don't delete it
        SELECT count(1)
        INTO l_associated_contacts
        FROM RESEARCH_LOGS WHERE SOURCE_CONTACT_ID = l_id;

        IF (l_associated_contacts = 0) THEN
          --find all depedent record
          --Remove contact_usages
          DELETE FROM CONTACT_USAGES
          WHERE RESEARCH_SOURCE_CONTACT_ID = l_id;
          --Remove research_source_contacts
          DELETE FROM RESEARCH_SOURCE_CONTACTS
          WHERE RESEARCH_SOURCE_ID = l_id;

        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;
     EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record could not be deleted because a contact method has been used to contact/source information.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_source_contact;

    PROCEDURE upd_contacts(
        source_id_i IN NUMBER,
        name_i IN VARCHAR2,
        frequency_i IN VARCHAR2,
        next_contact_date_i IN DATE,
        owner_i IN NUMBER,
        contact_usage_type_id_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        entered_by_i IN NUMBER,
        contact_methods_i IN XMLForm_Contact_tt,
        administrators_i IN xmlform_admi_tt,
        status_i in number,
        resSourceId out number
        )
     IS
        l_source_contact_id NUMBER;
        l_source_id NUMBER := source_id_i;
        l_contact_admin_id NUMBEr;
        l_exadminid NUMBER;
     BEGIn
          IF source_id_i IS NULL THEN
            --create new
            IF contact_methods_i.COUNT < 1 THEN
                --RAISE missing required value;
                NULL;
            END If;

            INSERT INTO research_sources (description, frequency, next_contact_date, owner, entered_by, start_date, end_date)
            VALUES (name_i, frequency_i, next_contact_date_i, owner_i, entered_by_i, start_date_i, end_date_i)
            RETURNING id INTO l_source_id;
            resSourceId := l_source_id;

            FOR cm IN 1..contact_methods_i.COUNT LOOP
                INSERT INTO research_source_contacts (
                    research_source_id ,
                    contact_type_id,
                    contact_details,
                    contact_notes,
                    language_id,
                    entered_by,
                    start_date,
                    end_date
                    )
                VALUES (
                    l_source_id,
                    contact_methods_i(cm).contact_type_id,
                    contact_methods_i(cm).contact_details,
                    contact_methods_i(cm).contact_notes,
                    contact_methods_i(cm).language_id,
                    entered_by_i,
                    contact_methods_i(cm).start_date,
                    contact_methods_i(cm).end_date
                    )
                    RETURNING id INTO l_source_contact_id;

                INSERT INTO contact_usages (
                    research_source_contact_id,
                    contact_usage_type_id,
                    start_date,
                    end_date,
                    usage_order,
                    entered_by
                    )
                VALUES (
                    l_source_contact_id,
                    contact_methods_i(cm).contact_usage_type_id,
                    contact_methods_i(cm).start_date,
                    contact_methods_i(cm).end_date,
                    contact_methods_i(cm).usage_order,
                    entered_by_i
                    );
            END LOOP;
            FOR adm IN 1..administrators_i.COUNT LOOP
                    INSERT INTO administrator_contacts(administrator_id, source_id, entered_by)
                    VALUES(administrators_i(adm).nkid, l_source_id,entered_by_i);
            END LOOP;

        ELSE
            UPDATE research_sources rs
            SET description = name_i,
                frequency = frequency_i,
                next_contact_date = next_contact_date_i,
                owner = owner_i,
                start_date = start_date_i,
                end_date = end_date_i
            WHERE rs.id = source_id_i;

            --insert, update, or remove contact_method
            FOR cm IN 1..contact_methods_i.COUNT LOOP

                IF (contact_methods_i(cm).id IS NULL) THEN
                    INSERT INTO research_source_contacts(
                        research_source_id,
                        contact_type_id,
                        contact_details,
                        contact_notes,
                        language_id,
                        entered_by,
                        start_date,
                        end_date
                    ) VALUES (
                        source_id_i,
                        contact_methods_i(cm).contact_type_id,
                        contact_methods_i(cm).contact_details,
                        contact_methods_i(cm).contact_notes,
                        contact_methods_i(cm).language_id,
                        entered_by_i,
                        --contact_methods_i(cm).frequency,
                        --contact_methods_i(cm).next_contact_date
                        contact_methods_i(cm).start_date,
                        contact_methods_i(cm).end_date
                        ) RETURNING id INTO l_source_contact_id;

                    INSERT INTO contact_usages (
                        research_source_contact_id,
                        contact_usage_type_id,
                        usage_order,
                        entered_by,
                        start_date,
                        end_date
                        )
                    VALUES (
                        l_source_contact_id,
                        contact_methods_i(cm).contact_usage_type_id,
                        contact_methods_i(cm).usage_order,
                        entered_by_i,
                        contact_methods_i(cm).start_date,
                        contact_methods_i(cm).end_date
                        );
                ELSE
                    IF contact_methods_i(cm).deleted = 1 THEN
                        DELETE FROM contact_usages WHERE research_source_contact_id = contact_methods_i(cm).id;
                        DELETE FROM research_source_contacts WHERE id = contact_methods_i(cm).id;
                    ELSIF contact_methods_i(cm).modified = 1 THEN
                        UPDATE research_source_contacts
                        SET language_id = contact_methods_i(cm).language_id,
                            contact_details = contact_methods_i(cm).contact_details,
                            contact_notes = contact_methods_i(cm).contact_notes,
                            contact_type_id = contact_methods_i(cm).contact_type_id,
                            status = contact_methods_i(cm).status,
                            start_date = contact_methods_i(cm).start_date,
                            end_date = contact_methods_i(cm).end_date
                        WHERE id = contact_methods_i(cm).id;

                      UPDATE contact_usages
                        SET contact_usage_type_id = contact_methods_i(cm).contact_usage_type_id,
                        usage_order = contact_methods_i(cm).usage_order,
                        start_date = contact_methods_i(cm).start_date,
                        end_date = contact_methods_i(cm).end_date
                        WHERE id = contact_methods_i(cm).contact_usage_id;

                    END IF;
                END IF;
            END LOOP;
            --insert or delete administrators
            FOR adm IN 1..administrators_i.COUNT LOOP
                l_exadminid := NULL;
                IF (administrators_i(adm).deleted = 1) THEN
                    DELETE FROM administrator_contacts
                    WHERE source_id = l_source_id
                    AND administrator_id = administrators_i(adm).nkid
                    RETURNING id INTO l_contact_admin_id;
                    INSERT INTO delete_logs (table_name, primary_key, deleted_by)
                    VALUES ('ADMINISTRATOR_CONTACTS',l_contact_admin_id,entered_by_i);
                ELSE
                    SELECT MAX(id)
                    INTO l_exadminid
                    FROM administrator_contacts
                    WHERE source_id = l_source_id
                    AND administrator_id = administrators_i(adm).nkid;
                    IF (l_exadminid IS nULL) THEN
                        INSERT INTO administrator_contacts(administrator_id, source_id, entered_by)
                        VALUES(administrators_i(adm).nkid, l_source_id,entered_by_i);
                    END IF;
                END IF;
            END LOOP;
        END IF;


    END upd_contacts;

    PROCEDURE contact_log(
        source_contact_id IN NUMBER,
        contact_method_id_c IN CLOB,
        note_i IN VARCHAR2,
        entered_by_i IN NUMBER,
        inext_contact_date IN VARCHAR2,
        contact_log_id_o OUT NUMBER,
        success_o OUT NUMBER)
    IS
        cmids_tt numTableType;
BEGIN
     cmids_tt:=str2tbl( contact_method_id_c ) ;
     FOR i IN 1 .. cmids_tt.count LOOP
        success_o := 0;
        INSERT INTO research_logs(note, source_contact_id, entered_by)
        VALUES (note_i,  cmids_tt(i), entered_by_i) RETURNING id INTO contact_log_id_o;
        DBMS_OUTPUT.put_line(i || ' : ' ||  cmids_tt(i));
     END LOOP;

     -- No date = don't do this
     IF (inext_contact_date IS NOT NULL) THEN
        UPDATE research_sources SET next_contact_date = TO_DATE(inext_contact_date,'DD-MON-YYYY')
        WHERE id = source_contact_id;
     END IF;

     success_o := 1;

     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        success_o := 0;
     WHEN OTHERS THEN -- Caution: Handles all exceptions
        success_o := 0;

    END contact_log;

    PROCEDURE upd_owners(
        research_source_id_c IN CLOB, --list of contact method_id's
        owner_id_i IN NUMBER,
        success_o OUT NUMBER
        )
    IS
      rsids_tt numTableType;
    BEGIN
       rsids_tt:=str2tbl( research_source_id_c ) ;
       FOR i IN 1 .. rsids_tt.count LOOP
          success_o := 0;
          UPDATE RESEARCH_SOURCES
          SET owner = owner_id_i
          where id = rsids_tt(i);
          --DBMS_OUTPUT.put_line(i || ' : ' ||  rsids_tt(i));
       END LOOP;

       success_o := 1;

       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          success_o := 0;
       WHEN OTHERS THEN -- Caution: Handles all exceptions
          success_o := 0;

    END upd_owners;

    PROCEDURE setContactStatus(iStatus IN NUMBER DEFAULT -2,
                               iSource_contact_id IN NUMBER,
                               sNext_contact_date IN VARCHAR2 DEFAULT NULL,
                               success_o OUT NUMBER) is
    begin
     null;
    end;
END contact;
/