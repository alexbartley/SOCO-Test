CREATE OR REPLACE PACKAGE BODY content_repo."DOCUMENTATION" 
IS
    PROCEDURE upd_document (document_id_i          IN     NUMBER,
                            eff_date_i             IN     DATE,
                            exp_date_i             IN     DATE,
                            acquired_date_i        IN     DATE,
                            posted_date_i          IN     DATE,
                            language_id_i          IN     NUMBER,
                            description_i          IN     VARCHAR2,
                            display_name_i         IN     VARCHAR2,
                            research_source_id_i   IN     NUMBER,
                            research_log_id_i      IN     NUMBER DEFAULT null,
                            success_o                 OUT NUMBER)
    IS
    BEGIN
        success_o := 0;

        IF (research_log_id_i IS NULL)
        THEN
            UPDATE attachments a
               SET effective_date = eff_date_i,
                   expiration_date = exp_date_i,
                   acquired_date = acquired_date_i,
                   posted_date = posted_date_i,
                   language_id = language_id_i,
                   description = description_i,
                   display_name = display_name_i,
                   research_source_id = research_source_id_i
             WHERE a.id = document_id_i;
        ELSE
            UPDATE attachments a
               SET effective_date = eff_date_i,
                   expiration_date = exp_date_i,
                   acquired_date = acquired_date_i,
                   posted_date = posted_date_i,
                   language_id = language_id_i,
                   description = description_i,
                   display_name = display_name_i,
                   research_source_id = research_source_id_i,
                   research_log_id = research_log_id_i
             WHERE a.id = document_id_i;
        END IF;

        success_o := 1;
    END upd_document;

    -- Delete Attachment
    Procedure del_attachment(pDocumentId in number, pEntered_by in number, rStatus out number) is
      l_attachment attachments.id%type:=pDocumentId;
      l_DeletedBy  delete_logs.deleted_by%type:=pEntered_by;
      /* there is one defined in err but
         en_cannot_delete_record CONSTANT NUMBER := -20001;
         cannot_delete_record EXCEPTION;
         PRAGMA EXCEPTION_INIT (cannot_delete_record, -20001);
      */
    Begin
     /* FOR xy IN (Select id
                 from citations
                 where attachment_id = l_attachment)
      LOOP*/
        -- no check delete
       /* Delete from citations
        where id=xy.id;*/
--        Update citations set status = -3 where id=xy.id;

        -- no check delete
        Delete from attachments
        where id=l_attachment and status<>2;

--        Update attachments set status = -3 where id=l_attachment;

        /*INSERT INTO delete_logs (table_name, primary_key, deleted_by)
        VALUES ('CITATIONS', xy.id, pEntered_by);*/
        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
        VALUES ('ATTACHMENTS', l_attachment, pEntered_by);

        rStatus := 1;
     /* END LOOP;*/
      EXCEPTION
      WHEN OTHERS
      THEN
        DBMS_OUTPUT.Put_Line( ' Error deleting citation/attachment.' );
        ROLLBACK;
        rStatus := 0;
        -- errlogger.report_and_stop (errnums.en_cannot_delete_record,'Citations/Attachments can''t be removed.');
        -- Expand if needed after THEN
        /*
        || error code information
        ||
        */
        /*  DECLARE
         error_code NUMBER := SQLCODE;
         error_msg  VARCHAR2 (300) := SQLERRM;
         error_info VARCHAR2 (30); -- Info extracted from error_msg.
         BEGIN
          IF error_code = -2292
          THEN
            -- Records found. Do something?
            -- DELETE FROM details

            -- Now delete parent
            -- DELETE FROM master

          ELSIF error_code = -2291
          THEN
            -- Key not found.
            DBMS_OUTPUT.PUTLINE
               (' Invalid ID: '||TO_CHAR (key));
          ELSE
            -- WHEN OTHERS
            DBMS_OUTPUT.PUTLINE
               (' Error deleting, error: '||error_msg);
          END IF;
         END; -- End of anonymous block.
        */
    end del_attachment;

    procedure del_attachment(pDocumentId in number, pEntered_by in number, rStatus out number, rList out CLOB) is
      l_attachment number :=pDocumentId;
      l_citation_id number;
      l_entered_by number:=pEntered_by;
      -- Step by step (we might send info back in JSON format showing what could not be removed?)
      any_valid numtabletype;
      xz number;
      success number:=0;

      -- (same log object is used for all the entities. type "should" be the same for all)
      TYPE t_obj_taxes IS TABLE OF juris_tax_chg_cits.id%TYPE;
      log_taxes  t_obj_taxes;

      /*
      || Timers
      ||
      */
      t1 number;
      t2 number;

    begin
      t1:=DBMS_UTILITY.GET_TIME;

      -- Get citation id list for the attachments
     FOR xy IN (Select id
                 from citations
                 where attachment_id = l_attachment)
     LOOP

      -- either an array or generate one
      -- opted for a new set per citation
--? 10/20/2015: TNN says; Huh?
      any_valid:=numtabletype();
      FOR y IN 1..11
      LOOP
      any_valid.extend;
      any_valid(any_valid.last) := 0;
      END LOOP;
    ---
      /*
      || Read any record from each entity that contain the citation
      || (could have used EXEC IMM with a dynamic statement)
      || Any_valid will have number of records as values (n,n,n,n,n,n...)
      */
      -- ADMINISTRATORS
      SELECT nvl(max(count(*)),0)
      INTO any_valid(1)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM juris_tax_chg_cits a
      JOIN juris_tax_chg_logs lg on (lg.id = a.juris_tax_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- JURISDICTIONS
      SELECT nvl(max(count(*)),0)
      INTO any_valid(2)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM juris_chg_cits a
      JOIN juris_chg_logs lg on (lg.id = a.juris_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- TAXES
      SELECT nvl(max(count(*)),0)
      INTO any_valid(3)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM juris_tax_chg_cits a
      JOIN juris_tax_chg_logs lg on (lg.id = a.juris_tax_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- TAXABILITY
      SELECT nvl(max(count(*)),0)
      INTO any_valid(4)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM juris_tax_app_chg_cits a
      JOIN juris_tax_app_chg_logs lg on (lg.id = a.juris_tax_app_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- COMMODITIES
      SELECT nvl(max(count(*)),0)
      INTO any_valid(5)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM comm_chg_cits a
      JOIN comm_chg_logs lg on (lg.id = a.comm_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

     /*
      -- COMMODITY_GROUPS
      SELECT nvl(max(count(*)),0)
      INTO any_valid(6)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM comm_grp_chg_cits a
      JOIN comm_grp_chg_logs lg on (lg.id = a.comm_grp_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

     */
      -- REFERENCE_GROUPS
      SELECT nvl(max(count(*)),0)
      INTO any_valid(8)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM ref_grp_chg_cits a
      JOIN ref_grp_chg_logs lg on (lg.id = a.ref_grp_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- BOUNDARIES
      SELECT nvl(max(count(*)),0)
      INTO any_valid(10)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM geo_poly_ref_chg_cits a
      JOIN geo_poly_ref_chg_logs lg on (lg.id = a.geo_poly_ref_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- UNIQUE_AREAS
      SELECT nvl(max(count(*)),0)
      INTO any_valid(11)
      -- a.citation_id id, decode(lg.status,0,1,1,0,2,0) rmv
      FROM geo_unique_area_chg_cits a
      JOIN geo_unique_area_chg_logs lg on (lg.id = a.geo_unique_area_chg_log_id)
      WHERE lg.status=2
      AND citation_id = xy.id
      group by a.id;

      -- Update the ones that can be
      --   * PERF TEST: Index range scan; cost 224

    -- ADMINISTRATORS
      UPDATE admin_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM admin_chg_cits a
        JOIN admin_chg_logs lg on (lg.id = a.admin_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

      -- LOG CITATION UPDATES FOR ADMINISTRATORS
      -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(1, sysdate, 'ADMIN_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

      -- JURISDICTIONS
      UPDATE juris_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM juris_chg_cits a
        JOIN juris_chg_logs lg on (lg.id = a.juris_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

      -- LOG CITATION UPDATES FOR JURISDICTIONS
      -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(2, sysdate, 'JURIS_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

      -- TAXES
      UPDATE juris_tax_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM juris_tax_chg_cits a
        JOIN juris_tax_chg_logs lg on (lg.id = a.juris_tax_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(3, sysdate, 'JURIS_TAX_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

      -- TAXABILITY
      UPDATE juris_tax_app_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM juris_tax_app_chg_cits a
        JOIN juris_tax_app_chg_logs lg on (lg.id = a.juris_tax_app_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(4, sysdate, 'JURIS_TAX_APP_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

    -- COMMODITIES
      UPDATE comm_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM comm_chg_cits a
        JOIN comm_chg_logs lg on (lg.id = a.comm_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(5, sysdate, 'COMM_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

    /*
    -- COMMODITY_GROUPS
      UPDATE comm_grp_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM comm_grp_chg_cits a
        JOIN comm_grp_chg_logs lg on (lg.id = a.comm_grp_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

    */

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(6, sysdate, 'COMM_GRP_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

    -- COMMODITY_GROUPS
      UPDATE ref_grp_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM ref_grp_chg_cits a
        JOIN ref_grp_chg_logs lg on (lg.id = a.ref_grp_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(9, sysdate, 'REF_GRP_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

    -- BOUNDARIES
      UPDATE GEO_POLY_REF_CHG_CITS
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM GEO_POLY_REF_CHG_CITS a
        JOIN geo_poly_ref_chg_logs lg on (lg.id = a.geo_poly_ref_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(10, sysdate, 'GEO_POLY_REF_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

    -- UNIQUE_AREAS
      UPDATE geo_unique_area_chg_cits
      SET STATUS = -3
      ,   entered_by = l_entered_by
      WHERE ID IN
      (
        SELECT a.id
        FROM geo_unique_area_chg_cits a
        JOIN geo_unique_area_chg_logs lg on (lg.id = a.geo_unique_area_chg_log_id)
        WHERE lg.status=0
        AND a.citation_id IN
      (Select cit.id
       from
       attachments att
       join citations cit on (cit.attachment_id = att.id)
       where att.id=l_attachment)
       )
       RETURNING id BULK COLLECT INTO log_taxes;

       -- LOG CITATION UPDATES FOR TAXES
       -- (Todo: 6/29/2015 create a generic procedure for this one)
       Forall i in log_taxes.first..log_taxes.last
       INSERT INTO attachments_update_log(entity, last_updated, table_name, entered_by, chg_cit_id, attachment_id)
       Values(11, sysdate, 'GEO_UNIQUE_AREA_CHG_CITS', l_entered_by, log_taxes(i), l_attachment);
       log_taxes := t_obj_taxes();

      -- Update the attachment ("remove" if not used)
      -- Update the citation ("remove" if not used)
      -- if > 0 no removal of citation
      -- (Might want to CAST the values to a varchar to display or pass back as JSON)
      SELECT SUM(column_value) into xz
      FROM TABLE ( any_valid  );

      IF xz = 0 then
        DBMS_OUTPUT.Put_Line( 'Can delete '|| l_attachment||' '|| xy.id );
        Update attachments
           set status = -3
            ,entered_by = l_entered_by
         where id = l_attachment and status = 0;

        Update citations
           set status = -3
            ,entered_by = l_entered_by
         where id = xy.id AND attachment_id = l_attachment and status = 0;

        t2 := DBMS_UTILITY.GET_TIME;
        DBMS_OUTPUT.Put_Line( (t2-t1)/100||' s' );

        success := 1;
      else
        t2 := DBMS_UTILITY.GET_TIME;
        DBMS_OUTPUT.Put_Line( (t2-t1)/100||' s' );
        success := 0;
        DBMS_OUTPUT.Put_Line( 'Citations is being used '||l_attachment||' '|| xy.id );
        -- SELECT column_value into xz FROM TABLE ( any_valid  )
        -- return; do you want to stop as soon as something has failed?
      end if;
     END LOOP;
    end del_attachment;

END documentation;
/