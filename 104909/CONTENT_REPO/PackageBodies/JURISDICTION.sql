CREATE OR REPLACE PACKAGE BODY content_repo."JURISDICTION"
IS

    /**************************************************************************/
    /* Jurisdiction Header XML
    /**************************************************************************/
    FUNCTION xml_jurisHeader(form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_juri_tt
        PIPELINED
    IS
        out_rec           xmlformjurisdiction;
        poxml             SYS.XMLTYPE;
        i                 BINARY_INTEGER := 1;
        l_form_xml        SYS.XMLTYPE := form_xml_i;
        l_end_date        SYS.XMLTYPE;
        l_start_date      SYS.XMLTYPE;
        l_description     SYS.XMLTYPE;
        l_deleted         SYS.XMLTYPE;
        l_id              SYS.XMLTYPE;
        l_rid             SYS.XMLTYPE;
        l_nkid            SYS.XMLTYPE;
        l_default_admin   SYS.XMLTYPE;
    BEGIN
        out_rec :=
            xmlformjurisdiction (NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL);

        LOOP
            poxml := l_form_xml.EXTRACT ('juris[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.official_name,
                   h.currency_id,
                   h.location_category_id,
                   h.entered_by,
                   h.modified,
                   h.id,
                   h.rid,
                   h.nkid,
                   h.deleted,
                   TO_DATE (h.start_date) start_date,
                   TO_DATE (h.end_date) end_date,
                   h.descr,
                   h.default_admin_id
              INTO out_rec.official_name,
                   out_rec.currency_id,
                   out_rec.location_category_id,
                   out_rec.entered_by,
                   out_rec.modified,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
                   out_rec.deleted,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.description,
                   out_rec.default_admin_id
              FROM XMLTABLE (
                   '/juris'
                   PASSING poxml
                   COLUMNS official_name VARCHAR2 (256) PATH 'officialName',
                           currency_id NUMBER PATH 'currencyId',
                           location_category_id NUMBER PATH 'locationCategoryId',
                           entered_by NUMBER PATH 'enteredBy',
                           modified NUMBER PATH 'modified',
                           id NUMBER PATH 'id',
                           rid NUMBER PATH 'rid',
                           nkid NUMBER PATH 'nkid',
                           deleted NUMBER PATH 'deleted',
                           start_date VARCHAR2 (12) PATH 'startDate',
                           end_date VARCHAR2 (12)   PATH 'endDate',
                           descr VARCHAR2 (1000)    PATH 'description',
                           default_admin_id NUMBER  PATH 'defaultAdminId') h;
            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END xml_jurisHeader;

    /**************************************************************************/
    /* Attributes
    /**************************************************************************/
    FUNCTION xml_jurisAttributes (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_attr_tt
        PIPELINED
    IS
        out_rec        xmlformjurisdictionattrib;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        -- init
        out_rec :=
            xmlformjurisdictionattrib (NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/attributes[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.uiuserid,
                   h.recid,
                   h.recrid,
                   h.recnkid,
                   h.avalue,
                   h.jvalue_id,
                   h.attribute_id,
                   --h.attribute_category_id,
                   TO_DATE (h.start_date) start_date,
                   TO_DATE (h.end_date) end_date,
                   h.amodified,
                   h.adeleted,
                   h.juris_id
              INTO out_rec.entered_by,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
                   out_rec.VALUE,
                   out_rec.value_id,
                   out_rec.attribute_id,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.modified,
                   out_rec.deleted,
                   out_rec.jurisdiction_id
              FROM XMLTABLE (
                       '/attributes'
                       PASSING poxml
                       COLUMNS uiuserid   NUMBER PATH 'enteredBy',
                               recid   NUMBER PATH 'id',
                               recrid   NUMBER PATH 'rid',
                               recnkid   NUMBER PATH 'nkid',
                               attribute_id   NUMBER PATH 'attributeId',
                               attribute_category_id   NUMBER PATH 'attributeCategoryId',
                               avalue   VARCHAR2 (128) PATH 'value',
                               jvalue_id   NUMBER PATH 'valueId',
                               start_date   VARCHAR2 (12) PATH 'startDate',
                               end_date   VARCHAR2 (12) PATH 'endDate',
                               amodified   NUMBER PATH 'modified',
                               adeleted   NUMBER PATH 'deleted',
                               juris_id   NUMBER PATH 'jurisdictionId') h;
            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xml_jurisAttributes;

    /**************************************************************************/
    /* Jurisdictions Contributions
    /**************************************************************************/
    FUNCTION xml_jurisContributions (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_contrib_tt
        PIPELINED
    IS
        out_rec        xmlform_contrib;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        out_rec :=
            xmlform_contrib (NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL);

        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/contributionsFrom[' || i || ']');
            EXIT WHEN poxml IS NULL;

            DBMS_OUTPUT.put_line ('XML contributionsFrom-->');

            SELECT h.recid,
                   h.recrelatedjurisid,
                   h.recrelatedjurisnkid,
                   TO_DATE (h.recstartdate) start_date,
                   TO_DATE (h.recenddate) end_date,
                   h.recmodified,
                   h.recdeleted
              INTO out_rec.id,
                   out_rec.related_juris_id,
                   out_rec.related_juris_nkid,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.modified,
                   out_rec.deleted
              FROM XMLTABLE (
                       '/contributionsFrom'
                       PASSING poxml
                       COLUMNS recid NUMBER PATH 'id',
                               recrelatedjurisid   NUMBER PATH 'relatedJurisdictionId',
                               recrelatedjurisnkid NUMBER PATH 'relatedJurisdictionNkid',
                               recstartdate   VARCHAR2 (20) PATH 'startDate',
                               recenddate   VARCHAR2 (20) PATH 'endDate',
                               recmodified   NUMBER PATH 'modified',
                               recdeleted   NUMBER PATH 'deleted') h;

            DBMS_OUTPUT.put_line ('ContributionsFrom id:' || out_rec.id);

            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xml_jurisContributions;

    /**************************************************************************/
    /* Tax Categories
    /**************************************************************************/
    FUNCTION xml_jurisTaxCategories(form_xml_i IN sys.XMLType)
    RETURN XMLForm_TaxDesc_TT
    PIPELINED
    IS
        out_rec        xmlformtaxdescription;                    -- 'My table'
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        -- init based on number of fields
        out_rec :=
            xmlformtaxdescription (NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL);


        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/taxCategorizations[' || i || ']');
            EXIT WHEN poxml IS NULL;

            DBMS_OUTPUT.put_line ('XML tax categories-->');

            SELECT
                   h.tid,
                   h.taxDescriptionId,
                   h.taxationTypeId,
                   h.specApplicabilityTypeId,
                   h.transactionTypeId,
                   u1.enteredBy,
                   h.tdeleted,
                   h.tmodified,
                   TO_DATE (h.tstartdate) start_date,
                   TO_DATE (h.tenddate) end_date
              INTO out_rec.id
            , out_rec.tax_description_id
            , out_rec.taxation_type_id
            , out_rec.spec_app_type_id
            , out_rec.tran_type_id
            , out_rec.entered_by
            , out_rec.deleted
            , out_rec.modified
            , out_rec.start_date
            , out_rec.end_date
            FROM
              XMLTABLE ('/taxCategorizations'
                       PASSING poxml
                       COLUMNS tid   NUMBER PATH 'id',
                               tnkid  NUMBER PATH 'nkid',
                               taxDescriptionId NUMBER PATH 'taxDescriptionId',
                               transactionTypeId NUMBER PATH 'transactionTypeId',
                               taxationTypeId NUMBER PATH 'taxationTypeId',
                               specApplicabilityTypeId NUMBER PATH 'specApplicabilityTypeId',
                               tstartdate   VARCHAR2 (20) PATH 'startDate',
                               tenddate   VARCHAR2 (20) PATH 'endDate',
                               tmodified   NUMBER PATH 'modified',
                               tdeleted   NUMBER PATH 'deleted') h,
              XMLTABLE ('/juris'
                       PASSING l_juris_xml
                       COLUMNS enteredBy NUMBER PATH 'enteredBy') u1;

DBMS_OUTPUT.Put_Line( 'Taxationtype:'||out_rec.taxation_type_id );

            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xml_jurisTaxCategories;

	/**************************************************************************/
    /* Options
    /**************************************************************************/
    FUNCTION xml_jurisoptions (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_option_tt
        PIPELINED
    IS
        out_rec        xmlformjurisdictionoptions;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        -- init
        out_rec :=
            xmlformjurisdictionoptions (NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/options[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.uiuserid,
                   h.recid,
                   h.recrid,
                   h.recnkid,
				   h.oname_id,
				   h.ovalue_id,
				   h.ocondition_id,
                   TO_DATE (h.start_date) start_date,
                   TO_DATE (h.end_date) end_date,
                   h.omodified,
                   h.odeleted,
                   h.juris_id
              INTO out_rec.entered_by,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
				   out_rec.name_id,
				   out_rec.value_id,
				   out_rec.condition_id,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.modified,
                   out_rec.deleted,
                   out_rec.jurisdiction_id
              FROM XMLTABLE (
                       '/options'
                       PASSING poxml
                       COLUMNS uiuserid   NUMBER PATH 'enteredBy',
                               recid   NUMBER PATH 'id',
                               recrid   NUMBER PATH 'rid',
                               recnkid   NUMBER PATH 'nkid',
							   oname_id   VARCHAR2 (100) PATH 'nameId',
							   ovalue_id   VARCHAR2 (100) PATH 'valueId',
							   ocondition_id   VARCHAR2 (100) PATH 'conditionId',
                               start_date   VARCHAR2 (12) PATH 'startDate',
                               end_date   VARCHAR2 (12) PATH 'endDate',
                               omodified   NUMBER PATH 'modified',
                               odeleted   NUMBER PATH 'deleted',
                               juris_id   NUMBER PATH 'jurisdictionId') h;
            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xml_jurisoptions;

	/**************************************************************************/
    /* Logic Mappings
    /**************************************************************************/
    FUNCTION xml_jurislogicmapng (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_logicmapng_tt
        PIPELINED
    IS
        out_rec        xmlformjurisdictionlogicmapng;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        -- init
        out_rec :=
            xmlformjurisdictionlogicmapng (NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/logicmapngs[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.uiuserid,
                   h.recid,
                   h.recrid,
                   h.recnkid,
				   h.ljuris_logic_group_id,
				   h.lprocess_order,
                   TO_DATE (h.start_date) start_date,
                   TO_DATE (h.end_date) end_date,
                   h.lmodified,
                   h.ldeleted,
                   h.juris_id
              INTO out_rec.entered_by,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
				   out_rec.juris_logic_group_id,
				   out_rec.process_order,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.modified,
                   out_rec.deleted,
                   out_rec.jurisdiction_id
              FROM XMLTABLE (
                       '/logicmapngs'
                       PASSING poxml
                       COLUMNS uiuserid   NUMBER PATH 'enteredBy',
                               recid   NUMBER PATH 'id',
                               recrid   NUMBER PATH 'rid',
                               recnkid   NUMBER PATH 'nkid',
							   ljuris_logic_group_id   NUMBER PATH 'jurisLogicGroupId',
							   lprocess_order   NUMBER PATH 'processOrder',
                               start_date   VARCHAR2 (12) PATH 'startDate',
                               end_date   VARCHAR2 (12) PATH 'endDate',
                               lmodified   NUMBER PATH 'modified',
                               ldeleted   NUMBER PATH 'deleted',
                               juris_id   NUMBER PATH 'jurisdictionId') h;
            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xml_jurislogicmapng;


    	/**************************************************************************/
    /* Juris Error Messages
    /**************************************************************************/
      FUNCTION xml_juriserrormessages (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_error_messages_tt
        PIPELINED
    IS
        out_rec        xmlformjuriserrormessages;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
          l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        -- init
        out_rec :=
            xmlformjuriserrormessages (NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/messages[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.uiuserid,
                   h.recid,
                   h.recrid,
                   h.recnkid,
				   h.mseverity_id,
				   h.merror_msg_id,

                   h.mdescription,
                   h.start_date,
                   h.end_date,

                   h.mmodified,
                   h.mdeleted,
                   h.juris_id
              INTO out_rec.entered_by,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
				   out_rec.severity_id,
				   out_rec.error_msg,

                   out_rec.description,

                   out_rec.start_date,
                   out_rec.end_date,

                   out_rec.modified,
                   out_rec.deleted,
                   out_rec.jurisdiction_id
              FROM XMLTABLE (
                       '/messages'
                       PASSING poxml
                       COLUMNS uiuserid     NUMBER PATH 'enteredBy',
                               recid        NUMBER PATH 'id',
                               recrid       NUMBER PATH 'rid',
                               recnkid      NUMBER PATH 'nkid',
                               mseverity_id NUMBER PATH 'severity_id',
                               merror_msg_id VARCHAR2(240) PATH 'error_msg',

                               mdescription VARCHAR2(2000) PATH  'description',
                                start_date   VARCHAR2 (12) PATH 'startDate',
                               end_date   VARCHAR2 (12) PATH 'endDate',

			                   mmodified    NUMBER PATH   'modified',
                               mdeleted     NUMBER PATH 'deleted',
                               juris_id     NUMBER PATH 'jurisdictionId') h;
            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xml_juriserrormessages ;

    /**************************************************************************/
    /* Process Jurisdiction Form
    /**************************************************************************/
    PROCEDURE process_form (sx              IN     CLOB,
                            update_success  OUT NUMBER,
                            nkid_o          OUT NUMBER,
                            rid_o           OUT NUMBER)
    IS
      form1           xmlform_juri_tt := xmlform_juri_tt ();
      att_list        xmlform_attr_tt := xmlform_attr_tt ();
      td_list         xmlform_taxdesc_tt := xmlform_taxdesc_tt ();
      tag_list        xmlform_tags_tt := xmlform_tags_tt ();
      contrib_list    xmlform_contrib_tt := xmlform_contrib_tt ();
	  option_list	  xmlform_option_tt :=  xmlform_option_tt ();
	  logicmapng_list	  xmlform_logicmapng_tt := xmlform_logicmapng_tt ();
      message_list    xmlform_error_messages_tt := xmlform_error_messages_tt ();

      clbtemp         CLOB;
      reccount        NUMBER := 0;
      l_upd_success   NUMBER := 0;
      l_rid           NUMBER;
    BEGIN

        FOR juris_row
            IN (SELECT *
                FROM TABLE (
                         CAST (
                             xml_jurisHeader(xmltype (sx)) AS xmlform_juri_tt)))
        LOOP
            l_rid := juris_row.rid;
            form1.EXTEND;
            form1 (form1.LAST) :=
                xmlformjurisdiction (juris_row.id,
                                     juris_row.rid,
                                     juris_row.official_name,
                                     juris_row.start_date,
                                     juris_row.end_date,
                                     juris_row.entered_by,
                                     juris_row.nkid,
                                     juris_row.description,
                                     juris_row.currency_id,
                                     juris_row.location_category_id,
                                     juris_row.modified,
                                     juris_row.deleted,
                                     juris_row.default_admin_id,
                                     juris_row.jurisdiction_type_id);

            DBMS_OUTPUT.put_line (form1 (form1.LAST).official_name);

            -- ---------------------------------------------------------------------------
            -- Additional Attributes
            -- ---------------------------------------------------------------------------
            FOR attr_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xml_jurisAttributes (xmltype (sx)) AS xmlform_attr_tt)))
            LOOP
               <<juris_attributes>>
                att_list.EXTEND;
                att_list (att_list.LAST) :=
                    xmlformjurisdictionattrib (attr_row.id,
                                               attr_row.rid,
                                               attr_row.jurisdiction_id,
                                               attr_row.attribute_id,
                                               attr_row.VALUE,
                                               attr_row.value_id,
                                               attr_row.start_date,
                                               attr_row.end_date,
                                               attr_row.entered_by,
                                               attr_row.nkid,
                                               attr_row.modified,
                                               attr_row.deleted);
            END LOOP juris_attributes;



            -- ---------------------------------------------------------------------------
            -- Tax Categorization
            -- ---------------------------------------------------------------------------
            DBMS_OUTPUT.Put_Line( 'Tax Categories' );
            FOR td_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xml_jurisTaxCategories(sys.xmltype.createxml (sx)) AS xmlform_taxdesc_tt)))
            LOOP
               <<tax_descriptions>>
                td_list.EXTEND;
                td_list (td_list.LAST) :=
                    xmlformtaxdescription (td_row.id,
                                           td_row.tax_description_id,
                                           td_row.taxation_type_id,
                                           td_row.spec_app_type_id,
                                           td_row.tran_type_id,
                                           td_row.entered_by,
                                           td_row.deleted,
                                           td_row.modified,
                                           td_row.start_date,
                                           td_row.end_date);
            END LOOP tax_descriptions;

            DBMS_OUTPUT.Put_Line( 'Contributions' );
            FOR contrib_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xml_jurisContributions(xmltype (sx)) AS xmlform_contrib_tt)))
            LOOP
               <<juris_contributes>>
                contrib_list.EXTEND;
                contrib_list (contrib_list.LAST) :=
                    xmlform_contrib (contrib_row.id,
                                        contrib_row.related_juris_id,
                                        contrib_row.related_juris_nkid,
                                        contrib_row.start_date,
                                        contrib_row.end_date,
                                        contrib_row.modified,
                                        contrib_row.deleted);
            END LOOP juris_contributes;

            -- ---------------------------------
            -- Tags
            -- ---------------------------------
            FOR itags
                IN (SELECT h.tag_id, h.deleted, h.status
                    FROM XMLTABLE (
                             '/juris/publicationTags'
                             PASSING xmltype (sx)
                             COLUMNS tag_id   NUMBER PATH 'tagId',
                                     deleted   NUMBER PATH 'deleted',
                                     status   NUMBER PATH 'status') h)
            LOOP
                tag_list.EXTEND;
                tag_list (tag_list.LAST) :=
                    xmlform_tags (2,
                                  form1 (form1.LAST).nkid,
                                  form1 (form1.LAST).entered_by,
                                  itags.tag_id,
                                  itags.deleted,
                                  0);
            END LOOP;

			-- ---------------------------------------------------------------------------
            -- Options
            -- ---------------------------------------------------------------------------
            FOR opt_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xml_jurisoptions (xmltype (sx)) AS xmlform_option_tt)))
            LOOP
               <<juris_options>>
                option_list.EXTEND;
                option_list (option_list.LAST) :=
                    xmlformjurisdictionoptions (opt_row.id,
                                               opt_row.rid,
                                               opt_row.jurisdiction_id,
											   opt_row.name_id,
											   opt_row.value_id,
											   opt_row.condition_id,
                                               opt_row.start_date,
                                               opt_row.end_date,
                                               opt_row.entered_by,
                                               opt_row.nkid,
                                               opt_row.modified,
                                               opt_row.deleted);
            END LOOP juris_options;

			-- ---------------------------------------------------------------------------
            -- Logic mapping
            -- ---------------------------------------------------------------------------
            FOR logicmapng_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xml_jurislogicmapng (xmltype (sx)) AS xmlform_logicmapng_tt)))
            LOOP
               <<juris_logicmapng>>
                logicmapng_list.EXTEND;
                logicmapng_list (logicmapng_list.LAST) :=
                    xmlformjurisdictionlogicmapng (logicmapng_row.id,
                                               logicmapng_row.rid,
                                               logicmapng_row.jurisdiction_id,
											   logicmapng_row.juris_logic_group_id,
											   logicmapng_row.process_order,
                                               logicmapng_row.start_date,
                                               logicmapng_row.end_date,
                                               logicmapng_row.entered_by,
                                               logicmapng_row.nkid,
                                               logicmapng_row.modified,
                                               logicmapng_row.deleted);
            END LOOP juris_logicmapng;

                         -- ---------------------------------------------------------------------------
            -- Messages
            -- ---------------------------------------------------------------------------

            FOR message_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xml_juriserrormessages (xmltype (sx)) AS xmlform_error_messages_tt)))
            LOOP
               <<juris_messages>>
                message_list.EXTEND;
                message_list (message_list.LAST) :=
                    XMLFORMJURISERRORMESSAGES (message_row.id,
                                               message_row.rid,
                                               message_row.jurisdiction_id,
                                               message_row.severity_id,
                                               message_row.error_msg,
                                               message_row.description,
                                               message_row.start_date,
                                               message_row.end_date,
                                               message_row.entered_by,
                                               message_row.nkid,
                                               message_row.modified,
                                               message_row.deleted);
            END LOOP juris_messages;

            jurisdiction.update_full (form1 (form1.LAST),
                                      att_list,
                                      contrib_list,
                                      td_list,
                                      tag_list,
									  option_list,
									  logicmapng_list,
                                      message_list,
                                      nkid_o,
                                      l_rid);
            rid_o := l_rid;
        END LOOP;



        l_upd_success := 1;
        update_success := l_upd_success;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            RAISE;
    END process_form;

    /**************************************************************************/


    FUNCTION xmlform_juris1 (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_juri_tt
        PIPELINED
    IS
        out_rec           xmlformjurisdiction;
        poxml             SYS.XMLTYPE;
        i                 BINARY_INTEGER := 1;
        l_form_xml        SYS.XMLTYPE := form_xml_i;
        l_end_date        SYS.XMLTYPE;
        l_start_date      SYS.XMLTYPE;
        l_description     SYS.XMLTYPE;
        l_deleted         SYS.XMLTYPE;
        l_id              SYS.XMLTYPE;
        l_rid             SYS.XMLTYPE;
        l_nkid            SYS.XMLTYPE;
        l_default_admin   SYS.XMLTYPE;
    BEGIN
        out_rec :=
            xmlformjurisdiction (NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL
                                 );

        LOOP
            poxml := l_form_xml.EXTRACT ('juris[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.official_name,
                   h.currency_id,
                   h.location_category_id,
                   h.entered_by,
                   h.modified,
                   h.id,
                   h.rid,
                   h.nkid,
                   h.deleted,
                   TO_DATE (h.start_date) start_date,
                   TO_DATE (h.end_date) end_date,
                   h.descr,
                   h.default_admin_id,
                   h.jurisdiction_type_id
              INTO out_rec.official_name,
                   out_rec.currency_id,
                   out_rec.location_category_id,
                   out_rec.entered_by,
                   out_rec.modified,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
                   out_rec.deleted,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.description,
                   out_rec.default_admin_id,
                   out_rec.jurisdiction_type_id
              FROM XMLTABLE (
                       '/juris'
                       PASSING poxml
                       COLUMNS official_name   VARCHAR2 (256)
                                                   PATH 'official_name',
                               currency_id   NUMBER PATH 'currency_id',
                               location_category_id   NUMBER
                                                          PATH 'location_category_id',
                               entered_by   NUMBER PATH 'entered_by',
                               modified   NUMBER PATH 'modified',
                               id    NUMBER PATH 'id',
                               rid   NUMBER PATH 'rid',
                               nkid   NUMBER PATH 'nkid',
                               deleted   NUMBER PATH 'deleted',
                               start_date   VARCHAR2 (12) PATH 'start_date',
                               end_date   VARCHAR2 (12) PATH 'end_date',
                               descr   VARCHAR2 (1000) PATH 'description',
                               default_admin_id   NUMBER
                                                      PATH 'default_admin_id',
                               jurisdiction_type_id   NUMBER
                                                      PATH 'juristypeid') h;

            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    EXCEPTION
        WHEN OTHERS
        THEN
            RAISE;
    END xmlform_juris1;

    FUNCTION xmlform_attr1 (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_attr_tt
        PIPELINED
    IS
        out_rec        xmlformjurisdictionattrib;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        out_rec :=
            xmlformjurisdictionattrib (NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/attribute[' || i || ']');
            EXIT WHEN poxml IS NULL;

            SELECT h.uiuserid,
                   h.recid,
                   h.recrid,
                   h.recnkid,
                   h.avalue,
                   h.jvalue_id,
                   h.attribute_id,
                   --h.attribute_category_id,
                   TO_DATE (h.start_date) start_date,
                   TO_DATE (h.end_date) end_date,
                   h.amodified,
                   h.adeleted,
                   h.juris_id
              INTO out_rec.entered_by,
                   out_rec.id,
                   out_rec.rid,
                   out_rec.nkid,
                   out_rec.VALUE,
                   out_rec.value_id,
                   out_rec.attribute_id,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.modified,
                   out_rec.deleted,
                   out_rec.jurisdiction_id
              FROM XMLTABLE (
                       '/attribute'
                       PASSING poxml
                       COLUMNS uiuserid   NUMBER PATH 'entered_by',
                               recid   NUMBER PATH 'id',
                               recrid   NUMBER PATH 'rid',
                               recnkid   NUMBER PATH 'nkid',
                               attribute_id   NUMBER PATH 'attribute_id',
                               attribute_category_id   NUMBER
                                                           PATH 'attribute_category_id',
                               avalue   VARCHAR2 (128) PATH 'value',
                               jvalue_id   NUMBER PATH 'value_id',
                               start_date   VARCHAR2 (12) PATH 'start_date',
                               end_date   VARCHAR2 (12) PATH 'end_date',
                               amodified   NUMBER PATH 'modified',
                               adeleted   NUMBER PATH 'deleted',
                               juris_id   NUMBER PATH 'jurisdiction_id') h;

            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xmlform_attr1;


    FUNCTION xmlform_taxdesc (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_taxdesc_tt
        PIPELINED
    IS
        out_rec        xmlformtaxdescription;                    -- 'My table'
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        out_rec :=
            xmlformtaxdescription (NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL);
        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml := l_form_xml.EXTRACT ('juris/tax_description[' || i || ']'); -- replaces a DTD/ELEMENT description
            EXIT WHEN poxml IS NULL;

            -- extract the fields
            IF poxml.EXISTSNODE ('tax_description/id') = 1
            THEN
                --uncommented check on attribute id existence 05/28 per Aron
                out_rec.id :=
                    NULLIF (
                        poxml.EXTRACT ('tax_description/id/text()').getnumberval (),
                        -1);
                out_rec.tax_description_id :=
                    NULLIF (
                        poxml.EXTRACT (
                            'tax_description/tax_description_id/text()').getnumberval (),
                        -1);

                IF out_rec.tax_description_id IS NULL
                THEN
                    --only if this is a new record get the Taxation Type ID, Spec Applicability Type ID, Transaction Type ID, PHP is not passing this value for updates
                    out_rec.taxation_type_id :=
                        poxml.EXTRACT (
                            'tax_description/taxation_type_id/text()').getnumberval ();
                    out_rec.spec_app_type_id :=
                        poxml.EXTRACT (
                            'tax_description/spec_applicability_type_id/text()').getnumberval ();
                    out_rec.tran_type_id :=
                        poxml.EXTRACT (
                            'tax_description/transaction_type_id/text()').getnumberval ();
                END IF;

                out_rec.entered_by :=
                    l_juris_xml.EXTRACT ('juris/entered_by/text()').getnumberval ();
                out_rec.deleted :=
                    poxml.EXTRACT ('tax_description/deleted/text()').getnumberval ();
                out_rec.modified :=
                    poxml.EXTRACT ('tax_description/modified/text()').getnumberval ();

                --handle the nullables
                l_end_date :=
                    poxml.EXTRACT ('tax_description/end_date/text()');

                IF (l_end_date IS NOT NULL)
                THEN
                    out_rec.end_date := l_end_date.getstringval ();
                ELSE
                    out_rec.end_date := NULL;
                END IF;

                l_start_date :=
                    poxml.EXTRACT ('tax_description/start_date/text()');

                IF (l_start_date IS NOT NULL)
                THEN
                    out_rec.start_date := l_start_date.getstringval ();
                ELSE
                    out_rec.start_date := NULL;
                END IF;
            END IF;

            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xmlform_taxdesc;

    FUNCTION xmlform_contribution (form_xml_i IN SYS.XMLTYPE)
        RETURN xmlform_contrib_tt
        PIPELINED
    IS
        out_rec        xmlform_contrib;
        poxml          SYS.XMLTYPE;
        l_form_xml     SYS.XMLTYPE := form_xml_i;
        l_juris_xml    SYS.XMLTYPE;
        i              BINARY_INTEGER := 1;
        l_end_date     SYS.XMLTYPE;
        l_start_date   SYS.XMLTYPE;
    BEGIN
        out_rec :=
            xmlform_contrib (NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL);

        l_juris_xml := l_form_xml.EXTRACT ('juris[' || i || ']');

        LOOP
            poxml :=
                l_form_xml.EXTRACT ('juris/contributes_from[' || i || ']');
            EXIT WHEN poxml IS NULL;

            DBMS_OUTPUT.put_line (
                'Entered into the process Insid ethe loop ');

            SELECT h.recid,
                   h.recrelatedjurisid,
                   h.recrelatedjurisnkid,
                   TO_DATE (h.recstartdate) start_date,
                   TO_DATE (h.recenddate) end_date,
                   h.recmodified,
                   h.recdeleted
              INTO out_rec.id,
                   out_rec.related_juris_id,
                   out_rec.related_juris_nkid,
                   out_rec.start_date,
                   out_rec.end_date,
                   out_rec.modified,
                   out_rec.deleted
              FROM XMLTABLE (
                       '/contributes_from'
                       PASSING poxml
                       COLUMNS recid   NUMBER PATH 'id',
                               recrelatedjurisid   NUMBER
                                                       PATH 'related_jurisdiction_id',
                               recrelatedjurisnkid   NUMBER
                                                         PATH 'related_jurisdiction_nkid',
                               recstartdate   VARCHAR2 (20) PATH 'start_date',
                               recenddate   VARCHAR2 (20) PATH 'end_date',
                               recmodified   NUMBER PATH 'modified',
                               recdeleted   NUMBER PATH 'deleted') h;

            DBMS_OUTPUT.put_line (
                'Inside xmlform contrib the id value is ' || out_rec.id);

            PIPE ROW (out_rec);
            i := i + 1;
        END LOOP;

        RETURN;
    END xmlform_contribution;


    PROCEDURE xmlprocess_form_juris1 (sx               IN     CLOB,
                                      update_success      OUT NUMBER,
                                      nkid_o              OUT NUMBER,
                                      rid_o               OUT NUMBER)
    IS
        form1           xmlform_juri_tt := xmlform_juri_tt ();
        att_list        xmlform_attr_tt := xmlform_attr_tt ();
        td_list         xmlform_taxdesc_tt := xmlform_taxdesc_tt ();
        tag_list        xmlform_tags_tt := xmlform_tags_tt ();
        contrib_list    xmlform_contrib_tt := xmlform_contrib_tt ();
		option_list	  xmlform_option_tt :=  xmlform_option_tt ();
		logicmapng_list	  xmlform_logicmapng_tt := xmlform_logicmapng_tt ();
         message_list    xmlform_error_messages_tt := xmlform_error_messages_tt ();

        clbtemp         CLOB;
        reccount        NUMBER := 0;
        l_upd_success   NUMBER := 0;
        l_rid           NUMBER;
    BEGIN

        FOR juris_row
            IN (SELECT *
                FROM TABLE (
                         CAST (
                             xmlform_juris1 (xmltype (sx)) AS xmlform_juri_tt)))
        LOOP
            l_rid := juris_row.rid;
            form1.EXTEND;
            form1 (form1.LAST) :=
                xmlformjurisdiction (juris_row.id,
                                     juris_row.rid,
                                     juris_row.official_name,
                                     juris_row.start_date,
                                     juris_row.end_date,
                                     juris_row.entered_by,
                                     juris_row.nkid,
                                     juris_row.description,
                                     juris_row.currency_id,
                                     juris_row.location_category_id,
                                     juris_row.modified,
                                     juris_row.deleted,
                                     juris_row.default_admin_id,
                                     juris_row.jurisdiction_type_id);

            DBMS_OUTPUT.put_line (form1 (form1.LAST).official_name);
            DBMS_OUTPUT.put_line (form1 (form1.LAST).jurisdiction_type_id);

            -- ---------------------------------------------------------------------------
            -- Additional Attributes
            -- ---------------------------------------------------------------------------
            FOR attr_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xmlform_attr1 (xmltype (sx)) AS xmlform_attr_tt)))
            LOOP
               <<juris_attributes>>
                att_list.EXTEND;
                att_list (att_list.LAST) :=
                    xmlformjurisdictionattrib (attr_row.id,
                                               attr_row.rid,
                                               attr_row.jurisdiction_id,
                                               attr_row.attribute_id,
                                               attr_row.VALUE,
                                               attr_row.value_id,
                                               attr_row.start_date,
                                               attr_row.end_date,
                                               attr_row.entered_by,
                                               attr_row.nkid,
                                               attr_row.modified,
                                               attr_row.deleted);
            END LOOP juris_attributes;

            -- ---------------------------------------------------------------------------
            -- Tax Categorization
            -- ---------------------------------------------------------------------------
            FOR td_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xmlform_taxdesc (sys.xmltype.createxml (sx)) AS xmlform_taxdesc_tt)))
            LOOP
               <<tax_descriptions>>
                td_list.EXTEND;
                td_list (td_list.LAST) :=
                    xmlformtaxdescription (td_row.id,
                                           td_row.tax_description_id,
                                           td_row.taxation_type_id,
                                           td_row.spec_app_type_id,
                                           td_row.tran_type_id,
                                           td_row.entered_by,
                                           td_row.deleted,
                                           td_row.modified,
                                           td_row.start_date,
                                           td_row.end_date);
            END LOOP tax_descriptions;

            FOR contrib_row
                IN (SELECT *
                    FROM TABLE (
                             CAST (
                                 xmlform_contribution (xmltype (sx)) AS xmlform_contrib_tt)))
            LOOP
               <<juris_contributes>>
                contrib_list.EXTEND;
                contrib_list (contrib_list.LAST) :=
                    xmlform_contrib (contrib_row.id,
                                        contrib_row.related_juris_id,
                                        contrib_row.related_juris_nkid,
                                        contrib_row.start_date,
                                        contrib_row.end_date,
                                        contrib_row.modified,
                                        contrib_row.deleted);
            END LOOP juris_contributes;

            -- Tags
            FOR itags
                IN (SELECT h.tag_id, h.deleted, h.status
                    FROM XMLTABLE (
                             '/juris/tag'
                             PASSING xmltype (sx)
                             COLUMNS tag_id   NUMBER PATH 'tag_id',
                                     deleted   NUMBER PATH 'deleted',
                                     status   NUMBER PATH 'status') h)
            LOOP
                tag_list.EXTEND;
                tag_list (tag_list.LAST) :=
                    xmlform_tags (2,
                                  form1 (form1.LAST).nkid,
                                  form1 (form1.LAST).entered_by,
                                  itags.tag_id,
                                  itags.deleted,
                                  0);
            END LOOP;

           jurisdiction.update_full (form1 (form1.LAST),
                                      att_list,
                                      contrib_list,
                                      td_list,
                                      tag_list,
									  option_list,
									  logicmapng_list,
                                       message_list,
                                      nkid_o,
                                      l_rid);
            rid_o := l_rid;
        END LOOP;

        l_upd_success := 1;
        update_success := l_upd_success;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            RAISE;
    END xmlprocess_form_juris1;


    PROCEDURE remove_contribution (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    )
    IS
        l_tax_relationship_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_id NUMBER;
        l_tax_desc_id NUMBER;
        l_rid NUMBER;
        l_id NUMBER;
        l_status number := 0;

    BEGIN

        INSERT INTO tmp_delete(table_name, primary_key) VALUES ('TAX_RELATIONSHIPS',id_i);

        SELECT status
          INTO l_status
          FROM tax_relationships
         WHERE id = id_i;

        if l_status = 0
        then

            DELETE FROM tax_relationships ta
            WHERE ta.id = l_tax_relationship_id
            RETURNING jurisdiction_rid, id INTO l_rid, l_id;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
                SELECT table_name, primary_key, l_deleted_by
                FROM tmp_delete
            );
        else
            raise errnums.cannot_update_record;
        end if;

        EXCEPTION
            WHEN errnums.cannot_update_record
            THEN
                ROLLBACK;
                errlogger.report_and_stop (
                    errnums.en_cannot_update_record,
                    'Record could not be updated because it does not match the pending record :)');
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
    END remove_contribution;


    PROCEDURE update_contribution (id_io                  IN OUT NUMBER,
                                   jurisdiction_id_i      IN     NUMBER,
                                   jurisdiction_rid_i     IN     NUMBER,
                                   jurisdiction_nkid_i    IN     NUMBER,
                                   related_juris_id_i            NUMBER,
                                   related_juris_nkid_i          NUMBER,
                                   start_date_i           IN     DATE,
                                   end_date_i             IN     DATE,
                                   entered_by_i           IN     NUMBER,
                                   modified_i             IN     NUMBER,
                                   deleted_i              IN     NUMBER)
    IS
        l_juris_contrib_pk   NUMBER := id_io;
        l_entered_by         NUMBER := entered_by_i;
        l_nkid               NUMBER;
        l_rid                NUMBER;
        l_status             NUMBER := -1;
        l_current_pending    NUMBER;
        l_juris_rid          NUMBER;
        l_rel_juris_id       NUMBER;
        l_juris_id           NUMBER;
        l_juris_nkid         NUMBER;

    BEGIN

    if related_juris_id_i is not null
    then

        IF (l_juris_contrib_pk IS NOT NULL)
        THEN

            UPDATE tax_relationships ja
               SET ja.start_date = start_date_i,
                   ja.end_date = end_date_i
             WHERE ja.id = id_io
             returning id, jurisdiction_rid, jurisdiction_id
                  into l_juris_contrib_pk, l_juris_rid, l_juris_id;

        ELSE

            INSERT INTO tax_relationships (jurisdiction_id,
                                               jurisdiction_nkid,
                                               jurisdiction_rid,
                                               related_jurisdiction_id,
                                               related_jurisdiction_nkid,
                                               relationship_type,
                                               start_date,
                                               end_date,
                                               entered_by)
            VALUES (jurisdiction_id_i,
                    jurisdiction_nkid_i,
                    jurisdiction_rid_i,
                    related_juris_id_i,
                    related_juris_nkid_i,
                    'CONTRIBUTIONS FROM',
                    start_date_i,
                    end_date_i,
                    entered_by_i)
            RETURNING id, jurisdiction_id, jurisdiction_nkid, jurisdiction_rid
              INTO l_juris_contrib_pk, l_juris_id, l_juris_nkid, l_juris_rid ;

        END IF;

        id_io := l_juris_contrib_pk;
    else
        raise errnums.missing_req_val;
    end if;

    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_io);
    END update_contribution;


    PROCEDURE update_full (details_i        IN     xmlformjurisdiction,
                           att_list_i       IN     xmlform_attr_tt,
                           contrib_list_i   IN     xmlform_contrib_tt,
                           td_list_i        IN     xmlform_taxdesc_tt,
                           tag_list         IN     xmlform_tags_tt,
						   option_list_i      IN     xmlform_option_tt,
						   logicmapng_list_i  IN     xmlform_logicmapng_tt,
                           message_list_i     IN     xmlform_error_messages_tt,
                           nkid_o           OUT NUMBER,
                           rid_o            OUT NUMBER)
    IS
      l_juris_pk     NUMBER := details_i.id;
      l_att_pk       NUMBER;
      l_contrib_pk   NUMBER;
      l_td_pk        NUMBER;
      l_nkid_o       NUMBER;
      l_rid_o        NUMBER;
      pdelete        NUMBER;
	  l_opt_pk       NUMBER;
	  l_logic_pk     NUMBER;
        l_message_pk   NUMBER;

    BEGIN

    -- Value of details_i.modified must exist
    DBMS_OUTPUT.Put_Line( 'Modified:'||details_i.modified );
    if NVL(details_i.modified, -1) = -1 then
      raise errnums.missing_req_val;
    end if;

        IF (NVL (details_i.modified, 0) = 1)
        THEN
           jurisdiction.UPDATE_RECORD (
                id_io               => l_juris_pk,
                official_name_i     => details_i.official_name,
                description_i       => details_i.description,
                start_date_i        => details_i.start_date,
                end_date_i          => details_i.end_date,
                currency_id_i       => details_i.currency_id,
                loc_category_id_i   => details_i.location_category_id,
                entered_by_i        => details_i.entered_by,
                nkid_o              => l_nkid_o,
                rid_o               => rid_o,
                default_admin_i     => details_i.default_admin_id,
                deleted_header      => details_i.deleted,
                juristypeid_i => details_i.jurisdiction_type_id);
        --If a new jurisdiction is created we need to set the l_juris_pk with the new ID. -Nick V
        --set l_juris_pk to the newly created jurisdiction_id from the above procedure call
        END IF;

        IF (nkid_o IS NULL)
        THEN
            SELECT nkid
              INTO nkid_o
              FROM jurisdictions
             WHERE id = l_juris_pk;
        END IF;

        FOR att IN 1 .. att_list_i.COUNT
        LOOP
            l_att_pk := att_list_i (att).id;

            IF (NVL (att_list_i (att).deleted, 0) = 1)
            THEN
                remove_attribute (id_i           => l_att_pk,
                                  deleted_by_i   => details_i.entered_by);
            ELSIF (NVL (att_list_i (att).modified, 0) = 1)
            THEN
                -- CRAPP-1884: Multiple types of attributes; ID or pure text
                IF (att_list_i (att).attribute_id <> fnjurisattribadmin (1))
                THEN
                    update_attribute (
                        id_io               => l_att_pk,
                        jurisdiction_id_i   => l_juris_pk,
                        attribute_id_i      => att_list_i (att).attribute_id,
                        value_i             => att_list_i (att).VALUE,
                        start_date_i        => att_list_i (att).start_date,
                        end_date_i          => att_list_i (att).end_date,
                        entered_by_i        => details_i.entered_by);
                ELSE
                    DBMS_OUTPUT.put_line (TO_CHAR (att_list_i (att).value_id));

                    update_attribute (
                        id_io               => l_att_pk,
                        jurisdiction_id_i   => l_juris_pk,
                        attribute_id_i      => att_list_i (att).attribute_id,
                        value_i             => TO_CHAR (att_list_i (att).value_id),
                        start_date_i        => att_list_i (att).start_date,
                        end_date_i          => att_list_i (att).end_date,
                        entered_by_i        => details_i.entered_by);
                END IF;
            END IF;
        END LOOP;


        FOR contrib IN 1 .. contrib_list_i.COUNT
        LOOP
            l_contrib_pk := contrib_list_i (contrib).id;
            IF (NVL (contrib_list_i (contrib).deleted, 0) = 1)
            THEN
                remove_contribution(id_i => l_contrib_pk,deleted_by_i => details_i.entered_By);
            ELSIF (NVL (contrib_list_i (contrib).modified, 0) = 1)
            THEN
                DBMS_OUTPUT.put_line ('calling update_contribution');
                update_contribution (
                    l_contrib_pk,
                    l_juris_pk,
                    rid_o,
                    nkid_o,
                    contrib_list_i (contrib).related_juris_id,
                    contrib_list_i (contrib).related_juris_nkid,
                    contrib_list_i (contrib).start_date,
                    contrib_list_i (contrib).end_date,
                    details_i.entered_by,
                    contrib_list_i (contrib).modified,
                    contrib_list_i (contrib).deleted);
            END IF;
        END LOOP;

        DBMS_OUTPUT.Put_Line( 'Tax Categories Process Rows: '||td_list_i.COUNT );
        FOR td IN 1 .. td_list_i.COUNT
        LOOP
            l_td_pk := td_list_i (td).id;
            IF (NVL (td_list_i (td).deleted, 0) = 1)
            THEN
                remove_tax_description (
                    id_i                => l_td_pk,
                    deleted_by_i        => details_i.entered_by,
                    jurisdiction_id_i   => l_juris_pk,
                    pdelete             => pdelete);
            ELSIF (NVL (td_list_i (td).modified, 0) = 1)
            THEN
                DBMS_OUTPUT.Put_Line( 'Tax descr Id:'||td_list_i (td).tax_description_id );
                update_tax_description (
                    id_io                  => l_td_pk,
                    jurisdiction_id_i      => l_juris_pk,
                    tax_description_id_i   => td_list_i (td).tax_description_id,
                    tran_type_id_i         => td_list_i (td).tran_type_id,
                    tax_type_id_i          => td_list_i (td).taxation_type_id,
                    spec_app_type_id_i     => td_list_i (td).spec_app_type_id,
                    start_date_i           => td_list_i (td).start_date,
                    end_date_i             => td_list_i (td).end_date,
                    entered_by_i           => details_i.entered_by);
            END IF;

            IF pdelete = 0
            THEN
                RAISE errnums.child_exists;
            END IF;
        END LOOP;

        -- Tags
        tags_registry.tags_entry (tag_list, l_nkid_o);

		-- Included below two for loops (Options  mapping) as part of CRAPP-3627
		--Options
		FOR opt IN 1 .. option_list_i.COUNT
        LOOP
            l_opt_pk := option_list_i (opt).id;

            IF (NVL (option_list_i (opt).deleted, 0) = 1)
            THEN
                remove_jurisoptions (id_i           => l_opt_pk,
                                     deleted_by_i   => details_i.entered_by);
            ELSIF (NVL (option_list_i (opt).modified, 0) = 1)
            THEN
                    update_jurisoptions (
                        id_io               => l_opt_pk,
                        jurisdiction_id_i   => l_juris_pk,
                        name_id_i      => option_list_i (opt).name_id,
						value_id_i      => option_list_i (opt).value_id,
						condition_id_i      => option_list_i (opt).condition_id,
                        start_date_i        => option_list_i (opt).start_date,
                        end_date_i          => option_list_i (opt).end_date,
                        entered_by_i        => details_i.entered_by);
            END IF;
        END LOOP;

		--Logic mapping
		FOR logic IN 1 .. logicmapng_list_i.COUNT
        LOOP
            l_logic_pk := logicmapng_list_i (logic).id;

            IF (NVL (logicmapng_list_i (logic).deleted, 0) = 1)
            THEN
                remove_jurislogicmapng (id_i           => l_logic_pk,
                                        deleted_by_i   => details_i.entered_by);
            ELSIF (NVL (logicmapng_list_i (logic).modified, 0) = 1)
            THEN
                    update_jurislogicmapng (
                        id_io               => l_logic_pk,
                        jurisdiction_id_i   => l_juris_pk,
                        juris_logic_group_id_i      => logicmapng_list_i (logic).juris_logic_group_id,
						process_order_i      => logicmapng_list_i (logic).process_order,
                        start_date_i        => logicmapng_list_i (logic).start_date,
                        end_date_i          => logicmapng_list_i (logic).end_date,
                        entered_by_i        => details_i.entered_by);
            END IF;
        END LOOP;

    --Juris Messages
        FOR message IN 1 .. message_list_i.COUNT
        LOOP
            l_message_pk := message_list_i (message).id;

            IF (NVL (message_list_i (message).deleted, 0) = 1)
            THEN
                remove_juris_error_messages (id_i           => l_message_pk,
                                        deleted_by_i   => details_i.entered_by);
            ELSIF (NVL (message_list_i (message).modified, 0) = 1)
            THEN
                    update_juris_error_messages (
                        id_io               => l_message_pk,
                        jurisdiction_id_i   => l_juris_pk,
                        severity_id_i       => message_list_i (message).severity_id,
                        error_msg_i         => message_list_i (message).error_msg,

                        description_id_i       => message_list_i (message).description,
                        start_date_i          => message_list_i (message).start_date,
                        end_date_i          => message_list_i (message).end_date,

                        entered_by_i        => details_i.entered_by);
            END IF;
        END LOOP;

        -- Get revision to pass this back to the UI
        rid_o := get_current_revision (p_nkid => nkid_o);

    EXCEPTION
        WHEN errnums.child_exists
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                SQLCODE,
                'Requested delete but child records exist.');
        WHEN errnums.missing_req_val THEN
            ROLLBACK;
            errlogger.report_and_stop (
                SQLCODE,
                'Missing data caused an issue.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            RAISE;
    END update_full;


    PROCEDURE UPDATE_RECORD (id_io               IN OUT NUMBER,
                             official_name_i     IN     VARCHAR2,
                             description_i       IN     VARCHAR2,
                             start_date_i        IN     DATE,
                             end_date_i          IN     DATE,
                             currency_id_i       IN     NUMBER,
                             loc_category_id_i   IN     NUMBER,
                             entered_by_i        IN     NUMBER,
                             nkid_o                 OUT NUMBER,
                             rid_o                  OUT NUMBER,
                             default_admin_i     IN     NUMBER,
                             deleted_header      IN     NUMBER,
                             juristypeid_i       IN     NUMBER)
    IS
        l_juris_pk          NUMBER := id_io;
        l_official_name     jurisdictions.official_name%TYPE := official_name_i;
        l_description       jurisdictions.description%TYPE := description_i;
        l_start_date        jurisdictions.start_date%TYPE := start_date_i;
        l_end_date          jurisdictions.end_date%TYPE := end_date_i;
        l_currency_id       NUMBER := currency_id_i;
        l_loc_category_id   NUMBER := loc_category_id_i;
        l_entered_by        NUMBER := entered_by_i;
        l_status            NUMBER := -1;
        l_current_pending   NUMBER;
        l_rid               NUMBER;
        l_success           NUMBER := 0;
    BEGIN
        IF (l_juris_pk IS NOT NULL)
        THEN

DBMS_OUTPUT.Put_Line( 'New Description:'||l_description );
DBMS_OUTPUT.Put_Line( 'Juris ID:'||l_juris_pk );

            UPDATE jurisdictions ji
               SET ji.official_name = l_official_name,
                   ji.description = l_description,
                   ji.start_date = l_start_date,
                   ji.end_date = l_end_date,
                   ji.entered_by = l_entered_by,
                   ji.currency_id = l_currency_id,
                   ji.geo_area_category_id = l_loc_category_id,
                   ji.default_admin_id = default_admin_i,
                   ji.jurisdiction_type_id = juristypeid_i
             WHERE ji.id = l_juris_pk
            RETURNING rid, nkid
              INTO l_rid, nkid_o;

            rid_o := l_rid;
        ELSE

            INSERT INTO jurisdictions (official_name,
                                       description,
                                       start_date,
                                       end_date,
                                       entered_by,
                                       geo_area_category_id,
                                       currency_id,
                                       default_admin_id,
                                       jurisdiction_type_id)
            VALUES (l_official_name,
                    l_description,
                    l_start_date,
                    l_end_date,
                    l_entered_by,
                    l_loc_category_id,
                    l_currency_id,
                    default_admin_i,
                    juristypeid_i)
            RETURNING rid, id, nkid
              INTO rid_o, l_juris_pk, nkid_o;

        END IF;

        -- CRAPP-1729 Allow removal of header (revert)
        IF (deleted_header = 1)
        THEN
            remove_juris_header (pnkid             => nkid_o,
                                 pdeletedby        => l_entered_by,
                                 pjurisdictionid   => l_juris_pk,
                                 success_o         => l_success);
        END IF;

        id_io := l_juris_pk;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN NO_DATA_FOUND
        THEN
            ROLLBACK;
            errlogger.report_and_go (
                SQLCODE,
                'Record could not be updated or removed.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            RAISE;
    END UPDATE_RECORD;


    PROCEDURE update_tax_description (id_io                  IN OUT NUMBER,
                                      jurisdiction_id_i      IN     NUMBER,
                                      tax_description_id_i   IN     NUMBER,
                                      tran_type_id_i         IN     NUMBER,
                                      tax_type_id_i          IN     NUMBER,
                                      spec_app_type_id_i     IN     NUMBER,
                                      start_date_i           IN     DATE,
                                      end_date_i             IN     DATE,
                                      entered_by_i           IN     NUMBER)
    IS
        l_juris_td_pk       NUMBER := id_io;
        l_juris_pk          NUMBER := jurisdiction_id_i;
        l_tax_desc_id       NUMBER := tax_description_id_i;
        l_start_date        jurisdiction_attributes.start_date%TYPE
                                := start_date_i;
        l_end_date          jurisdiction_attributes.end_date%TYPE := end_date_i;
        l_entered_by        NUMBER := entered_by_i;
        l_nkid              NUMBER;
        l_rid               NUMBER;
        l_status            NUMBER := -1;
        l_current_pending   NUMBER;
    BEGIN
      DBMS_OUTPUT.Put_Line( 'Update Tax Descr' );

        IF (l_juris_pk IS NULL)
        THEN
            RAISE errnums.missing_req_val;
        END IF;

        IF (l_juris_td_pk IS NOT NULL)
        THEN
            UPDATE juris_tax_descriptions ja
               SET ja.start_date = NVL (l_start_date, ja.start_date),
                   ja.end_date = l_end_date,
                   ja.entered_by = l_entered_by
             WHERE ja.id = l_juris_td_pk;
        ELSE
            IF (l_tax_desc_id IS NULL)
            THEN
                l_tax_desc_id :=
                    add_tax_description (tran_type_id_i,
                                         tax_type_id_i,
                                         spec_app_type_id_i,
                                         entered_by_i);
            END IF;

            INSERT INTO juris_tax_descriptions (jurisdiction_id,
                                                tax_description_id,
                                                start_date,
                                                end_date,
                                                entered_by,
                                                rid)
            VALUES (l_juris_pk,
                    l_tax_desc_id,
                    l_start_date,
                    l_end_date,
                    l_entered_by,
                    l_rid)
            RETURNING id
              INTO l_juris_td_pk;
        END IF;

        id_io := l_juris_td_pk;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_io);
    END update_tax_description;


    PROCEDURE COPY (sx IN OUT CLOB)
    IS
        l_copy_attributes      NUMBER := 1;
        l_copy_tx_descr        NUMBER := 1;
        rid_list               CLOB := EMPTY_CLOB ();
        return_rids            CLOB := EMPTY_CLOB ();
        l_rid                  NUMBER;                           -- := rid_io;
        l_new_juris_pk         NUMBER;
        l_new_juris_att_pk     NUMBER;
        l_new_name             jurisdictions.official_name%TYPE; -- now a clob := new_official_name_i;
        l_entered_by           NUMBER;                           -- entered_by_i;

        l_new_juris            jurisdictions%ROWTYPE;
        l_new_juris_att        jurisdiction_attributes%ROWTYPE;

        l_new_message_pk juris_error_messages.id%type;
        l_new_messages juris_error_messages%ROWTYPE;

        l_new_juris_desc_pk    NUMBER;

        -- Copy taxes associated with Jurisdiction to new Jurisdiction
        TYPE tt_tax_items IS TABLE OF juris_tax_impositions%ROWTYPE;
        tds_tax_items          tt_tax_items := tt_tax_items ();

        -- Contributions
        Type tt_contribution is table of tax_relationships%ROWTYPE;
        ds_contribution tt_contribution:=tt_contribution();

        -- Tags
        TYPE tt_juris_tags IS TABLE OF jurisdiction_tags%ROWTYPE;
        ds_juris_tags          tt_juris_tags := tt_juris_tags ();
        ds_new_juris_tags      xmlform_tags_tt := xmlform_tags_tt ();

        -- Taxability
        TYPE tt_taxability_items IS TABLE OF juris_tax_applicabilities%ROWTYPE;
        tds_taxability_items   tt_taxability_items := tt_taxability_items ();

        s_new_juris_id         VARCHAR2 (16);
        n_copied               NUMBER;
        n_taxab_copied         NUMBER;
        n_new_juris_id         NUMBER;

        rid_io                 NUMBER;
        nkid_o                 NUMBER := 0;
        ptax                   NUMBER := 0;
        ptaxability            NUMBER := 0;
        pcurrent               NUMBER := 0;
        entered_by_i           NUMBER;

        contrib_id_io number:=NULL;  -- Return value for contribution id

    BEGIN
        DBMS_LOB.createtemporary (rid_list, TRUE);
        DBMS_LOB.createtemporary (return_rids, TRUE);

        -- Parse copy xml
        IF DBMS_LOB.getlength (lob_loc => sx) > 0
        THEN
            FOR copyto
                IN (SELECT h.rid_io,
                           h.nkid_o,
                           h.newname,
                           h.ptax,
                           h.ptaxability,
                           h.pcurrent,
                           h.entered_by_i
                    FROM XMLTABLE (
                             '/copy_juris'
                             PASSING xmltype (sx)
                             COLUMNS rid_io NUMBER PATH 'jurisdiction_rid',
                             nkid_o NUMBER PATH 'nkid_o',
                             ptax NUMBER PATH 'copy_tax',
                             ptaxability NUMBER PATH 'copy_taxability',
                             pcurrent NUMBER PATH 'current_only',
                             entered_by_i NUMBER PATH 'entered_by',
                             newname VARCHAR2 (256) PATH 'official_name') h)
            LOOP
                l_rid := copyto.rid_io;
                nkid_o := copyto.nkid_o;
                ptax := NVL (copyto.ptax, 0);
                ptaxability := NVL (copyto.ptaxability, 0);
                pcurrent := NVL (copyto.pcurrent, 0);
                entered_by_i := copyto.entered_by_i;
                l_new_name := copyto.newname;

                SELECT *
                  INTO l_new_juris
                  FROM jurisdictions j2
                 WHERE id =
                           (SELECT MAX (j.id)
                              FROM jurisdiction_revisions r
                                   JOIN jurisdictions j ON (j.nkid = r.nkid)
                             WHERE r.id = l_rid AND j.rid <= r.id);

                IF (lower(l_new_juris.official_name) = TRIM (lower(l_new_name)) )
                THEN
                    RAISE errnums.duplicate_key;
                END IF;

                -- Add new jurisdiction , return rid and nkid
                UPDATE_RECORD (l_new_juris_pk,
                                            l_new_name,
                                            l_new_juris.description,
                                            l_new_juris.start_date,
                                            l_new_juris.end_date,
                                            l_new_juris.currency_id,
                                            l_new_juris.geo_area_category_id,
                                            entered_by_i,
                                            nkid_o,
                                            rid_io,
                                            l_new_juris.default_admin_id,
                                            0,
                                            l_new_juris.jurisdiction_type_id);

                -- CRAPP-3264
                -- Build code to make the test pass
                IF pcurrent = 0
                THEN
                    FOR r
                        IN (SELECT DISTINCT
                                   ja.attribute_id,
                                   ja.VALUE,
                                   nvl(ja.start_date,j.start_date) start_date, -- set attribute start date to Jurisdiction start date if empty
                                   ja.end_date
                            FROM jurisdiction_attributes ja
                            JOIN jurisdictions j
                                 ON (j.id = ja.jurisdiction_id)
                            WHERE j.nkid = l_new_juris.nkid
                                  AND j.start_date is not null
                                  AND ja.next_rid is null )
                    LOOP
                        update_attribute (l_new_juris_att_pk,
                                                       l_new_juris_pk,
                                                       r.attribute_id,
                                                       r.VALUE,
                                                       r.start_date,
                                                       r.end_date,
                                                       entered_by_i);
                        l_new_juris_att_pk := NULL;
                    END LOOP;

                ELSE

                  -- CRAPP-3264
                  -- COPY CURRENT ONLY IS BASED ON END_DATE.
                  -- Older revisions are not involved even if the old code had that functionality
                    FOR r
                        IN (SELECT ja.attribute_id,
                                   ja.VALUE,
                                   ja.start_date,
                                   ja.end_date
                            FROM jurisdiction_attributes ja
                                 JOIN jurisdictions j
                                     ON (j.id = ja.jurisdiction_id)
                            WHERE     j.nkid = l_new_juris.nkid
                                  AND j.start_date is not null
                                  AND ja.next_rid is null
                                  AND ja.end_date is null
                                  )
                    LOOP
                        update_attribute (l_new_juris_att_pk,
                                                       l_new_juris_pk,
                                                       r.attribute_id,
                                                       r.VALUE,
                                                       r.start_date,
                                                       r.end_date,
                                                       entered_by_i);
                        l_new_juris_att_pk := NULL;
                    END LOOP;
                END IF;

                IF pcurrent = 0
                THEN

                    --(j.id = txd.jurisdiction_id)
                    FOR r
                        IN (SELECT txd.tax_description_id,
                                   txd.start_date,
                                   txd.end_date,
                                   vtxd.*
                            FROM juris_tax_descriptions txd
                                 JOIN jurisdictions j
                                     ON (j.nkid = txd.jurisdiction_nkid)
                                 JOIN vtax_descriptions vtxd
                                     ON (vtxd.id = txd.tax_description_id)
                            WHERE
                            j.id =
                                     (SELECT MAX (j.id)
                              FROM jurisdiction_revisions r
                                   JOIN jurisdictions j ON (j.nkid = r.nkid)
                             WHERE r.id = l_rid  AND j.rid <= r.id)
                             )
                    LOOP
                        update_tax_description (
                            id_io                  => l_new_juris_desc_pk,
                            jurisdiction_id_i      => l_new_juris_pk,
                            tax_description_id_i   => r.tax_description_id,
                            tran_type_id_i         => r.transaction_type_id,
                            tax_type_id_i          => r.taxation_type_id,
                            spec_app_type_id_i     => r.spec_applicability_type_id,
                            start_date_i           => r.start_date,
                            end_date_i             => r.end_date,
                            entered_by_i           => entered_by_i);
                        l_new_juris_desc_pk := NULL;
                    END LOOP;
                ELSE
                    -- expr could have been in a decode but lets play it safe here
                    -- TODO: (should really specify the individual columns from vtxd)
                    --(j.id = txd.jurisdiction_id)

                    FOR r
                        IN (SELECT txd.tax_description_id,
                                   txd.start_date,
                                   txd.end_date,
                                   vtxd.*
                            FROM juris_tax_descriptions txd
                                 JOIN jurisdictions j
                                     ON (j.nkid = txd.jurisdiction_nkid)
                                 JOIN vtax_descriptions vtxd
                                     ON (vtxd.id = txd.tax_description_id)
                            WHERE
                             j.id =
                                    (SELECT MAX (j.id)
                              FROM jurisdiction_revisions r
                                   JOIN jurisdictions j ON (j.nkid = r.nkid)
                             WHERE r.id = l_rid  AND j.rid <= r.id)
                             AND (txd.end_date IS NULL or txd.end_date > sysdate))
                    LOOP

-- Taxes to copy
DBMS_OUTPUT.Put_Line( r.tax_description_id||' '||r.taxation_type||' '||r.start_date||' '||r.end_date );

                        update_tax_description (
                            id_io                  => l_new_juris_desc_pk,
                            jurisdiction_id_i      => l_new_juris_pk,
                            tax_description_id_i   => r.tax_description_id,
                            tran_type_id_i         => r.transaction_type_id,
                            tax_type_id_i          => r.taxation_type_id,
                            spec_app_type_id_i     => r.spec_applicability_type_id,
                            start_date_i           => r.start_date,
                            end_date_i             => r.end_date,
                            entered_by_i           => entered_by_i);
                        l_new_juris_desc_pk := NULL;
                    END LOOP;
                END IF;

                -- Taxes for current Jurisdiction
                --   a/ # of tax items - if any
                --   b/ copy each tax to new jurisdiction
                --
                -- CRAPP-399: include options for current, historical and all
                IF ptax = 1
                THEN
                    DBMS_OUTPUT.put_line ('Copy Taxes Section -->');

                    IF pcurrent = 0
                    THEN
                        SELECT *
                          BULK COLLECT INTO tds_tax_items
                          FROM juris_tax_impositions imp
                         WHERE imp.jurisdiction_nkid =
                                   (SELECT MAX (j.nkid) mxi
                                      FROM jurisdiction_revisions r
                                           JOIN jurisdictions j
                                               ON (j.nkid = r.nkid)
                                     WHERE r.id = l_rid AND j.rid <= r.id);
                    ELSE
                        SELECT *
                          BULK COLLECT INTO tds_tax_items
                          FROM juris_tax_impositions imp
                         WHERE     imp.jurisdiction_nkid =
                                       (SELECT MAX (j.nkid) mxi
                                          FROM jurisdiction_revisions r
                                               JOIN jurisdictions j
                                                   ON (j.nkid = r.nkid)
                                         WHERE r.id = l_rid AND j.rid <= r.id)
                               AND imp.end_date IS NULL;
                    END IF;
                    s_new_juris_id := TO_CHAR (l_new_juris_pk);

DBMS_OUTPUT.put_line ('New JurisId' || s_new_juris_id);
DBMS_OUTPUT.put_line ('# of taxes to copy:'||tds_tax_items.COUNT);

                    IF (tds_tax_items.COUNT > 0)
                    THEN
                        FOR lp IN tds_tax_items.FIRST .. tds_tax_items.LAST
                        LOOP
                            DBMS_OUTPUT.put_line (
                                lp || ' ' || tds_tax_items (lp).id);
                            taxlaw_taxes.copy_juris_tax_imp (
                                pjuris_tax_id   => tds_tax_items (lp).id,
                                pstrset         => s_new_juris_id,
                                pentered_by     => entered_by_i,
                                rtncopied       => n_copied);
                        END LOOP;
                    END IF;
                END IF;

            -- Contributions
            IF pcurrent = 0 THEN
                FOR r
                IN (SELECT txr.jurisdiction_id, txr.jurisdiction_nkid, txr.jurisdiction_rid,
                txr.related_jurisdiction_id, txr.related_jurisdiction_nkid, txr.relationship_type,
                txr.start_date, txr.end_date, txr.status, txr.basis_percent
                FROM tax_relationships txr
                JOIN jurisdictions j ON (j.nkid = txr.jurisdiction_nkid)
                WHERE j.nkid = l_new_juris.nkid)
                LOOP
                update_contribution(id_io=>contrib_id_io,
                                   jurisdiction_id_i=> l_new_juris_pk,
                                   jurisdiction_rid_i=> rid_io,
                                   jurisdiction_nkid_i=> nkid_o,
                                   related_juris_id_i=> r.related_jurisdiction_id,
                                   related_juris_nkid_i=> r.related_jurisdiction_nkid,
                                   start_date_i=> r.start_date,
                                   end_date_i=> r.end_date,
                                   entered_by_i=> entered_by_i,
                                   modified_i=>1,
                                   deleted_i=>0);
                DBMS_OUTPUT.Put_Line( 'New contrib_id_io:'||contrib_id_io);
                contrib_id_io := NULL;
                END LOOP;

            ELSE
                FOR r
                IN (SELECT txr.jurisdiction_id, txr.jurisdiction_nkid, txr.jurisdiction_rid,
                txr.related_jurisdiction_id, txr.related_jurisdiction_nkid, txr.relationship_type,
                txr.start_date, txr.end_date, txr.status, txr.basis_percent
                FROM tax_relationships txr
                JOIN jurisdictions j ON (j.nkid = txr.jurisdiction_nkid)
                WHERE j.nkid = l_new_juris.nkid AND (txr.end_date is null or txr.end_date > sysdate))
                LOOP
                    update_contribution(id_io=>contrib_id_io,
                                   jurisdiction_id_i=> l_new_juris_pk,
                                   jurisdiction_rid_i=> rid_io,
                                   jurisdiction_nkid_i=> nkid_o,
                                   related_juris_id_i=> r.related_jurisdiction_id,
                                   related_juris_nkid_i=> r.related_jurisdiction_nkid,
                                   start_date_i=> r.start_date,
                                   end_date_i=> r.end_date,
                                   entered_by_i=> entered_by_i,
                                   modified_i=>1,
                                   deleted_i=>0);
                    DBMS_OUTPUT.Put_Line( 'New contrib_id_io:'||contrib_id_io);
                    contrib_id_io := NULL;
                  END LOOP;
                END IF;

                -- Copy tags
                -- TODO: ASK; do we need a parameter in the UI in the future to include tags?
                SELECT *
                  BULK COLLECT INTO ds_juris_tags
                  FROM jurisdiction_tags tg
                 WHERE tg.ref_nkid =
                           (SELECT MAX (j.nkid) mxi
                              FROM jurisdiction_revisions r
                                   JOIN jurisdictions j ON (j.nkid = r.nkid)
                             WHERE r.id = l_rid AND j.rid <= r.id);

                IF (ds_juris_tags.COUNT > 0)
                THEN
                    FOR lp IN ds_juris_tags.FIRST .. ds_juris_tags.LAST
                    LOOP
                        DBMS_OUTPUT.put_line (
                               'Rec:'
                            || lp
                            || ' Tag Id:'
                            || ds_juris_tags (lp).tag_id
                            || ' Nkid:'
                            || nkid_o);
                        ds_new_juris_tags.EXTEND;
                        ds_new_juris_tags (ds_new_juris_tags.LAST) :=
                            xmlform_tags (2,
                                          ds_juris_tags (lp).ref_nkid,
                                          entered_by_i,
                                          ds_juris_tags (lp).tag_id,
                                          0,
                                          0);
                    END LOOP;
                    tags_registry.tags_entry (ds_new_juris_tags, nkid_o);
                END IF;

                --> Taxability
                -- OLD so this will not work. UI does not have the ptaxability flag anymore
                -- Parameter added for copy taxability
                IF ptaxability = 1
                THEN
                    DBMS_OUTPUT.put_line ('Copy Taxability Section -->');
                    DBMS_OUTPUT.put_line ('Juris RID:' || l_rid);

                    IF pcurrent = 0
                    THEN
                        SELECT *
                          BULK COLLECT INTO tds_taxability_items
                          FROM juris_tax_applicabilities tap
                         WHERE tap.jurisdiction_nkid =
                                   (SELECT MAX (j.nkid) mxi
                                      FROM jurisdiction_revisions r
                                           JOIN jurisdictions j
                                               ON (j.nkid = r.nkid)
                                     WHERE r.id = l_rid AND j.rid <= r.id);
                    ELSE
                        SELECT *
                          BULK COLLECT INTO tds_taxability_items
                          FROM juris_tax_applicabilities tap
                         WHERE     tap.jurisdiction_nkid =
                                       (SELECT MAX (j.nkid) mxi
                                          FROM jurisdiction_revisions r
                                               JOIN jurisdictions j
                                                   ON (j.nkid = r.nkid)
                                         WHERE r.id = l_rid AND j.rid <= r.id)
                               AND ( tap.end_date IS NULL or tap.end_date >= sysdate );
                    END IF;

                    IF (tds_taxability_items.COUNT > 0)
                    THEN
                        n_new_juris_id := TO_NUMBER (s_new_juris_id); -- changed to one
                        DBMS_OUTPUT.put_line (
                               'Juris id for the applicability:'
                            || n_new_juris_id);

                        FOR lp IN tds_taxability_items.FIRST ..
                                  tds_taxability_items.LAST
                        LOOP
                            DBMS_OUTPUT.put_line (
                                lp || ' ' || tds_taxability_items (lp).id);
                            TAXABILITY.generate_xml(jta_id_i=> tds_taxability_items (lp).id, juris_nkid=>nkid_o, entered_by_i=> entered_by_i,
                                start_date_i=> tds_taxability_items (lp).start_date,
                                end_date_i => nvl(tds_taxability_items (lp).end_date, '')

                                );
                        END LOOP;
                    END IF;
                END IF;


                -- CRAPP-3898 Copy messages
                IF pcurrent = 0
                THEN
                    FOR r
                        IN (SELECT DISTINCT
                           ja.severity_id
                          ,ja.error_msg
                          ,ja.description
                          ,nvl(ja.start_date,j.start_date) start_date
                          ,ja.end_date
                           FROM juris_error_messages ja
                           JOIN jurisdictions j
                                ON (j.id = ja.jurisdiction_id)
                           WHERE j.nkid = l_new_juris.nkid
                                AND j.start_date is not null
                                AND ja.next_rid is null )
                    LOOP
                        update_juris_error_messages(l_new_message_pk,
                                          l_new_juris_pk,
                                          r.severity_id,
                                          r.error_msg,
                                          r.description
                                         ,r.start_date
                                         ,r.end_date
                                         ,entered_by_i);
                        l_new_message_pk := NULL;
                    END LOOP;

                ELSE

                    FOR r
                        IN (SELECT DISTINCT
                           ja.severity_id
                          ,ja.error_msg
                          ,ja.description
                          ,nvl(ja.start_date,j.start_date) start_date
                          ,ja.end_date
                           FROM juris_error_messages ja
                           JOIN jurisdictions j
                                ON (j.id = ja.jurisdiction_id)
                           WHERE j.nkid = l_new_juris.nkid
                                AND j.start_date is not null
                                  AND ja.next_rid is null
                                  AND ja.end_date is null
                                  )
                    LOOP
                        update_juris_error_messages(l_new_message_pk,
                                          l_new_juris_pk,
                                          r.severity_id,
                                          r.error_msg,
                                          r.description,
                                          r.start_date,
                                          r.end_date,
                                          entered_by_i);
                        l_new_message_pk := NULL;
                    END LOOP;
                END IF;


                -- Revision handling
                rid_io :=
                    get_revision (
                        entity_id_io    => l_new_juris_pk,
                        entity_nkid_i   => NULL,
                        entered_by_i    => entered_by_i);
                DBMS_LOB.append (dest_lob   => rid_list,
                                 src_lob    => TO_CHAR (rid_io) || ',');
                l_new_juris_pk := NULL;
            END LOOP;
            DBMS_LOB.COPY (dest_lob   => return_rids,
                           src_lob    => rid_list,
                           amount     => DBMS_LOB.getlength (rid_list) - 1);
            sx := return_rids;
            DBMS_LOB.freetemporary (lob_loc => return_rids);
            DBMS_LOB.freetemporary (lob_loc => rid_list);
        END IF;
    EXCEPTION
        WHEN errnums.duplicate_key
        THEN
            errlogger.report_and_stop (
                errnums.en_duplicate_key,
                'Unable to create copy because the new name is the same as the old name.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
    END COPY;


    PROCEDURE delete_revision (revision_id_i   IN     NUMBER,
                               deleted_by_i    IN     NUMBER,
                               success_o          OUT NUMBER)
    IS
        l_rid          NUMBER := revision_id_i;
        l_deleted_by   NUMBER := deleted_by_i;
        l_juris_pk     NUMBER;
        l_status       NUMBER;
    --l_submit_id NUMBER := submit_delete_id.nextval;
    BEGIN
        success_o := 0;

        --Get status to validate that it's a deleteable record
        --Get revision ID to delete all depedent records by
        SELECT status
          INTO l_status
          FROM jurisdiction_revisions
         WHERE id = l_rid;

        IF (l_status = 0)
        THEN
            --Remove dependent Attributes
            --Reset prior revisions to current
            UPDATE jurisdiction_attributes ja
               SET ja.next_rid = NULL
             WHERE ja.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key)
                (SELECT 'JURISDICTION_ATTRIBUTES', ja.id
                   FROM jurisdiction_attributes ja
                  WHERE ja.rid = l_rid);

            DELETE FROM jurisdiction_attributes ja
             WHERE ja.rid = l_rid;

            --Remove dependent Tax_Descriptions
            --Reset prior revisions to current
            UPDATE juris_tax_descriptions td
               SET td.next_rid = NULL
             WHERE td.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key)
                (SELECT 'JURIS_TAX_DESCRIPTIONS', td.id
                   FROM juris_tax_descriptions td
                  WHERE td.rid = l_rid);

            DELETE FROM juris_tax_descriptions td
             WHERE td.rid = l_rid;

            UPDATE jurisdictions ji
               SET ji.next_rid = NULL
             WHERE ji.next_rid = l_rid;

            UPDATE jurisdiction_revisions ji
               SET ji.next_rid = NULL
             WHERE ji.next_rid = l_rid;

            INSERT INTO tmp_delete (table_name, primary_key)
                (SELECT 'JURISDICTIONS', ja.id
                   FROM jurisdictions ja
                  WHERE ja.rid = l_rid);

            DELETE FROM jurisdictions ji
             WHERE ji.rid = l_rid;

            --Remove Revision record
            INSERT INTO tmp_delete (table_name, primary_key)
            VALUES ('JURISDICTION_REVISIONS', l_rid);

            DELETE FROM juris_chg_logs jc
             WHERE jc.rid = l_rid;

            DELETE FROM jurisdiction_revisions jr
             WHERE jr.id = l_rid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by)
                (SELECT table_name, primary_key, l_deleted_by
                   FROM tmp_delete);

            COMMIT;
            success_o := 1;
        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;
    EXCEPTION
        WHEN errnums.cannot_delete_record
        THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go (
                errnums.en_cannot_delete_record,
                'Record could not be deleted because it has already been published.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
    END delete_revision;

    /*
    || prc: delete_revision
    || Overloaded
    || Reset status, remove revision, remove documentations
    */
    PROCEDURE delete_revision (resetall        IN     NUMBER,
                               revision_id_i   IN     NUMBER,
                               deleted_by_i    IN     NUMBER,
                               success_o          OUT NUMBER)
    IS
        l_rid          NUMBER := revision_id_i;
        l_deleted_by   NUMBER := deleted_by_i;
        l_juris_pk     NUMBER;
        l_status       NUMBER;
        l_cit_count    NUMBER;
        --l_submit_id NUMBER := submit_delete_id.nextval;

        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
        success_o := 0;

        IF resetall = 1 THEN
          SELECT COUNT(status)
          INTO l_stat_cnt
          FROM jurisdiction_revisions
          WHERE id = l_rid;

          IF l_stat_cnt > 0 THEN -- crapp-2749
                SELECT status
                INTO l_status
                FROM jurisdiction_revisions
                WHERE id = l_rid;

                IF (l_status = 1) THEN
                    reset_status (revision_id_i   => revision_id_i,
                                  reset_by_i      => deleted_by_i,
                                  success_o       => success_o);
                -- {{Any option if failed?}}
                END IF; -- status

                DELETE FROM juris_chg_vlds
                WHERE juris_chg_log_id IN (SELECT id
                                              FROM juris_chg_logs
                                             WHERE rid = l_rid);

                IF SQL%NOTFOUND THEN
                    DBMS_OUTPUT.put_line ('No validations to remove');
                END IF;
            END IF; -- l_stat_cnt
        END IF; -- resetAll

        -- {Get status to validate that it's a deleteable record
        --  Get revision ID to delete all depedent records by }
        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM jurisdiction_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM jurisdiction_revisions
            WHERE id = l_rid;

            IF (l_status = 0) THEN
                --Remove dependent attributes and reset prior revisions to current
                UPDATE jurisdiction_attributes ja
                   SET ja.next_rid = NULL
                 WHERE ja.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key)
                    (SELECT 'JURISDICTION_ATTRIBUTES', ja.id
                     FROM jurisdiction_attributes ja
                     WHERE ja.rid = l_rid);

                DELETE FROM jurisdiction_attributes ja
                WHERE ja.rid = l_rid;

                --Remove dependent Tax_Descriptions
                --Reset prior revisions to current
                UPDATE juris_tax_descriptions td
                   SET td.next_rid = NULL
                WHERE td.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key)
                    (SELECT 'JURIS_TAX_DESCRIPTIONS', td.id
                     FROM juris_tax_descriptions td
                     WHERE td.rid = l_rid);

                DBMS_OUTPUT.put_line ('Del juris_tax_descriptions');

                DELETE FROM juris_tax_descriptions td
                 WHERE td.rid = l_rid;

                UPDATE jurisdictions ji
                   SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                UPDATE jurisdiction_revisions ji
                   SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key)
                    (SELECT 'JURISDICTIONS', ja.id
                     FROM jurisdictions ja
                     WHERE ja.rid = l_rid);

                DELETE FROM jurisdictions ji
                WHERE ji.rid = l_rid;

                IF resetall = 1 THEN
                    -- Check juris_chg_cits
                    -- Simple count instead of Exception
                    SELECT COUNT (*)
                    INTO l_cit_count
                    FROM juris_chg_cits cit
                    WHERE cit.juris_chg_log_id IN (SELECT id
                                                   FROM juris_chg_logs jc
                                                   WHERE jc.rid = l_rid);

                    IF l_cit_count > 0 THEN
                        DELETE FROM juris_chg_cits cit
                        WHERE cit.juris_chg_log_id IN (SELECT id
                                                       FROM juris_chg_logs jc
                                                       WHERE jc.rid = l_rid);
                    END IF;
                END IF;

                --Remove Revision record
                INSERT INTO tmp_delete (table_name, primary_key)
                VALUES ('JURISDICTION_REVISIONS', l_rid);

                DELETE FROM juris_chg_logs jc
                 WHERE jc.rid = l_rid;

                DELETE FROM jurisdiction_revisions jr
                 WHERE jr.id = l_rid;

                INSERT INTO delete_logs (table_name, primary_key, deleted_by)
                    (SELECT table_name, primary_key, l_deleted_by
                       FROM tmp_delete);

                COMMIT;
                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        ELSE
            success_o := 1;  -- returning success since there was nothing to remove
        END IF; -- l_stat_cnt


    EXCEPTION
        WHEN errnums.cannot_delete_record
        THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go (
                errnums.en_cannot_delete_record,
                'Record could not be deleted because it has already been published.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
    END delete_revision;                                       -- Overloaded 1


    PROCEDURE update_attribute (id_io               IN OUT NUMBER,
                                jurisdiction_id_i   IN     NUMBER,
                                attribute_id_i      IN     NUMBER,
                                value_i             IN     VARCHAR2,
                                start_date_i        IN     DATE,
                                end_date_i          IN     DATE,
                                entered_by_i        IN     NUMBER)
    IS
        l_juris_att_pk      NUMBER := id_io;
        l_juris_pk          NUMBER := jurisdiction_id_i;
        l_attribute_id      NUMBER := attribute_id_i;
        l_value             jurisdiction_attributes.VALUE%TYPE := value_i;
        l_start_date        jurisdiction_attributes.start_date%TYPE
                                := start_date_i;
        l_end_date          jurisdiction_attributes.end_date%TYPE := end_date_i;
        l_entered_by        NUMBER := entered_by_i;
        l_nkid              NUMBER;
        l_rid               NUMBER;
        l_status            NUMBER := -1;
        l_current_pending   NUMBER;
        lcnt                NUMBER := 0;
        l_juris_nkid        NUMBER;
    BEGIN

-- Investigation 8/24/2016
-- Genesa and I put in the test for 'value must exist' in this long time ago.
-- We allowed to publish data with null values with the attributes which now is failing
-- since all attributes are copied.
-- Accept null value? That's one option.
-- Copy only things that has values and start dates forces users to verify that all key information is available.
-- Problem here is that ALL (in any entity) was published at the backend with no validation.
-- (And how could we validate empty values and start dates? Guessing?)
  IF (l_juris_pk IS NULL)
  THEN
    RAISE errnums.missing_req_val;
  END IF;

        IF (l_juris_att_pk IS NOT NULL)
        THEN
            UPDATE jurisdiction_attributes ja
               SET ja.VALUE = case when ja.attribute_id = 25 then ja.value else l_value end,
                   ja.start_date = l_start_date,
                   ja.end_date = l_end_date,
                   ja.entered_by = l_entered_by
             WHERE ja.id = l_juris_att_pk;
        ELSE

            select distinct nkid into l_juris_nkid from jurisdictions where id = l_juris_pk;
            select count(1) into lcnt from jurisdiction_attributes where jurisdiction_nkid = l_juris_nkid;

            if l_attribute_id = 25 and l_juris_nkid >= 1
            then
                null;
            else
            INSERT INTO jurisdiction_attributes (jurisdiction_id,
                                                 attribute_id,
                                                 VALUE,
                                                 start_date,
                                                 end_date,
                                                 entered_by,
                                                 rid)
            VALUES (l_juris_pk,
                    l_attribute_id,
                    l_value,
                    l_start_date,
                    l_end_date,
                    l_entered_by,
                    l_rid)
            RETURNING id
              INTO l_juris_att_pk;
            END IF;
        END IF;

        id_io := l_juris_att_pk;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_io);
    END update_attribute;


    FUNCTION add_tax_description (tran_type_id_i       IN NUMBER,
                                  tax_type_id_i        IN NUMBER,
                                  spec_app_type_id_i   IN NUMBER,
                                  entered_by_i         IN NUMBER)
        RETURN NUMBER
    IS
        l_tran_type_id         NUMBER := tran_type_id_i;
        l_tax_type_id          NUMBER := tax_type_id_i;
        l_spec_app_type_id     NUMBER := spec_app_type_id_i;
        l_entered_by           NUMBER := entered_by_i;
        l_tax_description_id   NUMBER;
        l_rid                  NUMBER;
        l_nkid                 NUMBER;
    BEGIN
        l_tax_description_id :=
            tax_description.find (l_tran_type_id,
                                  l_tax_type_id,
                                  l_spec_app_type_id);

        IF (l_tax_description_id IS NULL)
        THEN
            tax_description.CREATE_RECORD (l_tax_description_id,
                                           l_tran_type_id,
                                           l_tax_type_id,
                                           l_spec_app_type_id,
                                           l_entered_by);
        END IF;

        RETURN l_tax_description_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
    END add_tax_description;


    FUNCTION get_revision (rid_i IN NUMBER, entered_by_i IN NUMBER)
        RETURN NUMBER
    IS
        l_new_rid    NUMBER;
        l_curr_rid   NUMBER;
        l_juris_id   NUMBER;
        l_nkid       NUMBER;
        l_nrid       NUMBER;
        l_status     NUMBER := -1;
        retval       NUMBER := 0;
        return       NUMBER;
    BEGIN
        IF (rid_i IS NOT NULL)
        THEN
            --just looking for the current revision
            SELECT jr.id, jr.status, jr.nkid
              INTO l_curr_rid, l_status, l_nkid
              FROM jurisdiction_revisions jr
             WHERE     EXISTS
                           (SELECT 1
                              FROM jurisdiction_revisions jr2
                             WHERE jr.nkid = jr2.nkid AND jr2.id = rid_i)
                   AND jr.next_rid IS NULL;
        END IF;

        IF l_status IN (0, 1)
        THEN
            --This record is already in a pending state.
            --Return its current RID
            retval := l_curr_rid;
        ELSE
            --The current version has been published, create a new one.
            --First, expire the previous version
            INSERT INTO jurisdiction_revisions (nkid, entered_by)
            VALUES (l_nkid, entered_by_i)
            RETURNING id
              INTO l_new_rid;

            UPDATE jurisdiction_revisions
               SET next_rid = l_new_rid
             WHERE id = l_curr_rid;

            retval := l_new_rid;
        END IF;

        RETURN retval;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            NULL; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
            RETURN retval;
    END get_revision;


    FUNCTION get_revision (entity_id_io    IN OUT NUMBER,
                           entity_nkid_i   IN     NUMBER,
                           entered_by_i    IN     NUMBER)
        RETURN NUMBER
    IS
        l_new_rid    NUMBER;
        l_juris_id   NUMBER := entity_id_io;
        l_nkid       NUMBER := entity_nkid_i;
        l_status     NUMBER;
        l_curr_rid   NUMBER;
        retval       NUMBER := -1;
        return       NUMBER;
    BEGIN
        --check for an existing revision
        IF (l_juris_id IS NOT NULL AND l_nkid IS NOT NULL)
        THEN
            -- this is just a new Jurisdiction
            INSERT INTO jurisdiction_revisions (nkid, entered_by)
            VALUES (l_nkid, entered_by_i)
            RETURNING id
              INTO l_new_rid;

            retval := l_new_rid;
        ELSE
            --this is a child record, need to get entity nkid
            SELECT j.nkid
              INTO l_nkid
              FROM jurisdictions j
             WHERE j.id = entity_id_io;

            --now get the current revision
            SELECT jr.id, jr.status, jr.nkid
              INTO l_curr_rid, l_status, l_nkid
              FROM jurisdiction_revisions jr
             WHERE jr.nkid = l_nkid AND jr.next_rid IS NULL;

            IF l_status IN (0, 1)
            THEN
                l_new_rid := l_curr_rid;
            ELSE
                INSERT INTO jurisdiction_revisions (nkid, entered_by)
                VALUES (l_nkid, entered_by_i)
                RETURNING id
                  INTO l_new_rid;

                UPDATE jurisdiction_revisions
                   SET next_rid = l_new_rid
                 WHERE id = l_curr_rid;
            END IF;
        END IF;

        entity_id_io := l_juris_id;
        retval := l_new_rid;
        RETURN retval;
    END get_revision;


    PROCEDURE remove_tax_description (id_i                IN     NUMBER,
                                      deleted_by_i        IN     NUMBER,
                                      jurisdiction_id_i   IN     NUMBER,
                                      pdelete                OUT NUMBER)
    IS
        l_juris_tax_desc_id   NUMBER := id_i;
        l_deleted_by          NUMBER := deleted_by_i;
        l_juris_id            NUMBER := jurisdiction_id_i;
        l_tax_desc_id         NUMBER;
        l_rid                 NUMBER;
        l_nkid                NUMBER;
        l_rec_count           NUMBER;
    BEGIN
        pdelete := 0;

        SELECT tax_description_id
          INTO l_tax_desc_id
          FROM juris_tax_descriptions
         WHERE id = l_juris_tax_desc_id;

        SELECT COUNT (*)
          INTO l_rec_count
          FROM jurisdictions jr
         WHERE     EXISTS
                       (SELECT 1
                          FROM juris_tax_impositions jti
                         WHERE     jti.tax_description_id = l_tax_desc_id
                               AND jti.jurisdiction_id = jr.id)
               AND jr.id = l_juris_id;

        -- no taxes yet linked to this juris/tax descr combination
        IF l_rec_count = 0
        THEN
            INSERT INTO tmp_delete (table_name, primary_key)
            VALUES ('JURIS_TAX_DESCRIPTIONS', l_juris_tax_desc_id);

            DELETE FROM juris_tax_descriptions jtd
             WHERE jtd.id = l_juris_tax_desc_id
            RETURNING rid, nkid
              INTO l_rid, l_nkid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by)
                VALUES (
                           'JURIS_TAX_DESCRIPTIONS',
                           l_juris_tax_desc_id,
                           l_deleted_by);

            UPDATE juris_tax_descriptions jtd
               SET next_rid = NULL
             WHERE jtd.next_rid = l_rid AND jtd.nkid = l_nkid;

            pdelete := 1; -- ToDo: need to come up with a good log for these. UI needs to read or get message.
        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;
    EXCEPTION
        WHEN errnums.cannot_delete_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_delete_record,
                'Tax category could not be removed. Tax for current category already exists.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_i);
    END remove_tax_description;


    PROCEDURE remove_attribute (id_i IN NUMBER, deleted_by_i IN NUMBER)
    IS
        l_juris_att_id   NUMBER := id_i;
        l_deleted_by     NUMBER := deleted_by_i;
        l_juris_id       NUMBER;
        l_tax_desc_id    NUMBER;
        l_rid            NUMBER;
        l_nkid           NUMBER;
    BEGIN
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('JURISDICTION_ATTRIBUTES', l_juris_att_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM jurisdiction_attributes ja
         WHERE ja.id = l_juris_att_id
           AND ja.attribute_id != 25
        RETURNING rid, nkid
          INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, l_deleted_by
               FROM tmp_delete);

        UPDATE jurisdiction_attributes jta
           SET next_rid = NULL
         WHERE jta.next_rid = l_rid AND jta.nkid = l_nkid;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_i);
    END remove_attribute;

    /*
    *  Reset Status
    */
    PROCEDURE reset_status (revision_id_i   IN     NUMBER,
                            reset_by_i      IN     NUMBER,
                            success_o          OUT NUMBER)
    IS
        l_rid        NUMBER := revision_id_i;
        l_reset_by   NUMBER := reset_by_i;
        l_juris_pk   NUMBER;
        l_status     NUMBER;

        -- (should probably be in the database as a lookup)
        table_list   VARCHAR2 (256)
                         := 'jurisdiction_attributes,juris_tax_descriptions,
        jurisdictions,jurisdiction_revisions';
        setval       NUMBER := 0;

        l_stat_cnt NUMBER := 0;  -- crapp-2749
    BEGIN
        success_o := 0;

        --Get status to validate that it's a record that can be reset
        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM jurisdiction_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
              INTO l_status
              FROM jurisdiction_revisions
             WHERE id = l_rid;

            IF (l_status = 1) THEN
                --genResetStatus(table_list,l_rid,l_reset_by);
                --Reset status
                UPDATE jurisdiction_attributes ja
                   SET status = setval, ja.entered_by = l_reset_by
                 WHERE ja.rid = l_rid;

                --Reset status
                UPDATE juris_tax_descriptions td
                   SET td.next_rid = setval, td.entered_by = l_reset_by
                 WHERE td.rid = l_rid;

                --Reset status
                UPDATE jurisdictions ji
                   SET status = setval, ji.entered_by = l_reset_by
                 WHERE ji.rid = l_rid;

                --Reset status
                UPDATE jurisdiction_revisions ji
                   SET ji.status = setval, ji.entered_by = l_reset_by
                 WHERE ji.id = l_rid;

				--Reset status
                UPDATE jurisdiction_options ja
                   SET status = setval, ja.entered_by = l_reset_by
                 WHERE ja.rid = l_rid;

				--Reset status
                UPDATE juris_logic_group_map ja
                   SET status = setval, ja.entered_by = l_reset_by
                 WHERE ja.rid = l_rid;

                --Reset status
                UPDATE juris_error_messages jm
                   SET status = setval, jm.entered_by = l_reset_by
                 WHERE jm.rid = l_rid;

                COMMIT;
                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_delete_record,
                'Record status could not be changed because it has already been published.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM);
    END reset_status;


    FUNCTION get_current_revision (p_nkid IN NUMBER)
        RETURN NUMBER
    IS
        l_curr_rid   NUMBER;
        l_juris_id   NUMBER;
        l_nkid       NUMBER;
        l_nrid       NUMBER;
        l_status     NUMBER := -1;
        retval       NUMBER := -1;
        return       NUMBER;
    BEGIN

    dbms_output.put_line('p_nkid value is '||p_nkid);
        IF (p_nkid IS NOT NULL)
        THEN
            SELECT distinct jr.id, jr.status, jr.nkid
              INTO l_curr_rid, l_status, l_nkid
              FROM jurisdiction_revisions jr
             WHERE     EXISTS
                           (SELECT 1
                              FROM jurisdiction_revisions jr2
                             WHERE jr.nkid = jr2.nkid AND jr2.nkid = p_nkid)
                   AND jr.next_rid IS NULL;

            retval := l_curr_rid;
        END IF;

        RETURN retval;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN 0; --ignore error and return no RID, this means that the last change in revision was deleted an so the revision no longer exists
    END get_current_revision;

    PROCEDURE unique_check (name_i IN VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count   NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM jurisdictions
         WHERE     official_name = name_i
               AND nkid != NVL (nkid_i, 0)
               AND ABS (status) != 3;

        IF (l_count > 0)
        THEN
            raise_application_error (
                errnums.en_duplicate_key,
                'Duplicate error: Name provided already exists for another Jurisdiction');
        END IF;
    END unique_check;


    PROCEDURE remove_juris_header (pnkid             IN     NUMBER,
                                   pdeletedby        IN     NUMBER,
                                   pjurisdictionid   IN     NUMBER,
                                   success_o            OUT NUMBER)
    IS
        l_rid      NUMBER;
        l_nkid     NUMBER;
        l_status   NUMBER;
    BEGIN
        -- Current jurisdiction ID (passed in the XML)
        SELECT nkid, rid
          INTO l_nkid, l_rid
          FROM jurisdictions jr
         WHERE id = pjurisdictionid AND next_rid IS NULL AND status = 0;

        -- the regular remove revision is checking for status = 0 of the revision
        -- (Might be able to expand this to include removal of validations - if needed)
        SELECT status
          INTO l_status
          FROM jurisdiction_revisions
         WHERE id = l_rid;

        IF (l_status = 0)
        THEN
            -- no taxes yet linked to this juris/tax descr combination
            IF l_nkid IS NOT NULL
            THEN
                INSERT INTO tmp_delete (table_name, primary_key)
                VALUES ('JURISDICTIONS', pjurisdictionid);

                UPDATE jurisdictions ji
                   SET ji.next_rid = NULL
                 WHERE ji.next_rid = l_rid;

                UPDATE jurisdiction_revisions ji
                   SET ji.next_rid = NULL
                 WHERE ji.next_rid = l_rid;

                DELETE FROM jurisdictions ji
                 WHERE ji.rid = l_rid AND status <> 2;

                --Remove Revision record
                INSERT INTO tmp_delete (table_name, primary_key)
                VALUES ('JURISDICTION_REVISIONS', l_rid);

                /*
                Delete From juris_chg_vlds
                Where juris_chg_log_id=
                (Select id From
                 juris_chg_logs Where rid=l_rid And entity_id=pJurisdictionId);*/

                DELETE FROM juris_chg_logs jc
                 WHERE jc.rid = l_rid;

                DELETE FROM jurisdiction_revisions jr
                 WHERE jr.id = l_rid;

                INSERT INTO delete_logs (table_name, primary_key, deleted_by)
                    (SELECT table_name, primary_key, pdeletedby
                       FROM tmp_delete);

                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        END IF;
    EXCEPTION
        WHEN errnums.cannot_delete_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_delete_record,
                'Jurisdiction revision could not be removed.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,
                                       SQLERRM || ': ' || pjurisdictionid);
    END remove_juris_header;

	PROCEDURE update_jurisoptions (id_io               	IN OUT NUMBER,
                                jurisdiction_id_i   IN     NUMBER,
								name_id_i 				IN VARCHAR2,
								value_id_i 				IN VARCHAR2,
								condition_id_i 		IN VARCHAR2,
                                start_date_i        IN     DATE,
                                end_date_i          IN     DATE,
                                entered_by_i        IN     NUMBER)
    IS
		l_juris_opt_pk      NUMBER := id_io;
        l_juris_pk          NUMBER := jurisdiction_id_i;
		l_name_id				jurisdiction_options.name_id%TYPE  := name_id_i;
		l_value_id				jurisdiction_options.value_id%TYPE  := value_id_i;
		l_condition_id				jurisdiction_options.condition_id%TYPE  := condition_id_i;
        l_start_date        jurisdiction_options.start_date%TYPE
                                := start_date_i;
        l_end_date          jurisdiction_options.end_date%TYPE := end_date_i;
        l_entered_by        NUMBER := entered_by_i;
        l_nkid              NUMBER;
        l_rid               NUMBER;
        l_status            NUMBER := -1;
        l_current_pending   NUMBER;
    BEGIN

-- Created this procedure as part of CRAPP-3627 (DB: Datamodel changes to store Jurisdiction Advanced)
  IF (l_juris_pk IS NULL)
  THEN
    RAISE errnums.missing_req_val;
  END IF;

        IF (l_juris_opt_pk IS NOT NULL)
        THEN
            UPDATE jurisdiction_options jo
               SET jo.value_id = l_value_id,
				   jo.condition_id = l_condition_id,
                   jo.start_date = l_start_date,
                   jo.end_date = l_end_date,
                   jo.entered_by = l_entered_by
             WHERE jo.id = l_juris_opt_pk;
        ELSE
            INSERT INTO jurisdiction_options(jurisdiction_id,
                                                 name_id,
												 condition_id,
                                                 value_id,
                                                 start_date,
                                                 end_date,
                                                 entered_by,
                                                 rid)
            VALUES (l_juris_pk,
                    l_name_id,
					l_condition_id,
                    l_value_id,
                    l_start_date,
                    l_end_date,
                    l_entered_by,
                    l_rid)
            RETURNING id
              INTO l_juris_opt_pk;
        END IF;

        id_io := l_juris_opt_pk;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_io);
    END update_jurisoptions;

	PROCEDURE update_jurislogicmapng (id_io             IN OUT NUMBER,
                                jurisdiction_id_i   IN     NUMBER,
								juris_logic_group_id_i 	IN 	   NUMBER,
								process_order_i 	IN 	   NUMBER,
                                start_date_i        IN     DATE,
                                end_date_i          IN     DATE,
                                entered_by_i        IN     NUMBER)
    IS
		l_juris_logic_pk      NUMBER := id_io;
        l_juris_pk          NUMBER := jurisdiction_id_i;
		l_juris_logic_group_id	juris_logic_group_map.juris_logic_group_id%TYPE  := juris_logic_group_id_i;
		l_process_order				juris_logic_group_map.process_order%TYPE  := process_order_i;
        l_start_date        juris_logic_group_map.start_date%TYPE
                                := start_date_i;
        l_end_date          juris_logic_group_map.end_date%TYPE := end_date_i;
        l_entered_by        NUMBER := entered_by_i;
        l_nkid              NUMBER;
        l_rid               NUMBER;
        l_status            NUMBER := -1;
        l_current_pending   NUMBER;
    BEGIN

 -- Created this procedure as part of CRAPP-3627 (DB: Datamodel changes to store Jurisdiction Advanced)
  IF (l_juris_pk IS NULL)
  THEN
    RAISE errnums.missing_req_val;
  END IF;

        IF (l_juris_logic_pk IS NOT NULL)
        THEN
            UPDATE juris_logic_group_map jlgm
               SET jlgm.process_order = l_process_order,
                   jlgm.start_date = l_start_date,
                   jlgm.end_date = l_end_date,
                   jlgm.entered_by = l_entered_by
             WHERE jlgm.id = l_juris_logic_pk;
        ELSE
            INSERT INTO juris_logic_group_map(jurisdiction_id,
                                                 juris_logic_group_id,
												 process_order,
                                                 start_date,
                                                 end_date,
                                                 entered_by,
                                                 rid)
            VALUES (l_juris_pk,
                    l_juris_logic_group_id,
					l_process_order,
                    l_start_date,
                    l_end_date,
                    l_entered_by,
                    l_rid)
            RETURNING id
              INTO l_juris_logic_pk;
        END IF;

        id_io := l_juris_logic_pk;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_io);
    END update_jurislogicmapng;

    PROCEDURE update_juris_error_messages ( id_io               	IN OUT NUMBER,
                                        jurisdiction_id_i       IN     NUMBER,
                                        severity_id_i 			IN NUMBER,
                                        error_msg_i				IN VARCHAR2,

                                        description_id_i 		IN VARCHAR2,
                                         start_date_i            IN DATE,
                                        end_date_i              IN DATE,

                                        entered_by_i            IN NUMBER)
    IS
		l_juris_message_pk          NUMBER := id_io;
        l_juris_pk          	    NUMBER := jurisdiction_id_i;
		l_severity_id				juris_error_messages.severity_id%TYPE  := severity_id_i;
		l_error_id				    juris_error_messages.error_msg%TYPE  := error_msg_i;

		l_description_id 			juris_error_messages.description%TYPE  := description_id_i;
        	l_start_date                juris_error_messages.start_date%TYPE   := start_date_i;
        l_end_date                juris_error_messages.end_date%TYPE   := end_date_i;

        l_entered_by        NUMBER := entered_by_i;
        l_nkid              NUMBER;
        l_rid               NUMBER;
        l_status            NUMBER := -1;
        l_current_pending   NUMBER;
    BEGIN

-- Created this procedure as part of CRAPP-3689 (DB: Data model for Jurisdiction Messages)
  IF (l_juris_pk IS NULL)
  THEN
    RAISE errnums.missing_req_val;
  END IF;

        IF (l_juris_message_pk IS NOT NULL)
        THEN
            UPDATE juris_error_messages jm
               SET jm.severity_id = l_severity_id,
	               jm.error_msg = l_error_id,

                   jm.description = l_description_id,

                   jm.entered_by = l_entered_by
             WHERE jm.id = l_juris_message_pk;
        ELSE
            INSERT INTO juris_error_messages(jurisdiction_id,
                                                 severity_id,
                                                 error_msg,

                                                 description,
                                                  start_date,
                                                 end_date,

                                                 entered_by,
                                                 rid)
            VALUES (l_juris_pk,
                    l_severity_id,
                    l_error_id,

                    l_description_id,
                       l_start_date,
                    l_end_date,

                    l_entered_by,
                    l_rid)
            RETURNING id
              INTO l_juris_message_pk;
        END IF;

        id_io := l_juris_message_pk;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.report_and_stop (errnums.en_missing_req_val,
                                       'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN

            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_io);
    END update_juris_error_messages;

	PROCEDURE remove_jurisoptions (id_i IN NUMBER, deleted_by_i IN NUMBER)
    IS
		l_juris_opt_id   NUMBER := id_i;
        l_deleted_by     NUMBER := deleted_by_i;
        l_juris_id       NUMBER;
        l_rid            NUMBER;
        l_nkid           NUMBER;
    BEGIN
	 -- Created this procedure as part of CRAPP-3627 (DB: Datamodel changes to store Jurisdiction Advanced)
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('JURISDICTION_OPTIONS', l_juris_opt_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM jurisdiction_options ja
         WHERE ja.id = l_juris_opt_id
        RETURNING rid, nkid
          INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, l_deleted_by
               FROM tmp_delete);

        UPDATE jurisdiction_options jo
           SET next_rid = NULL
         WHERE jo.next_rid = l_rid AND jo.nkid = l_nkid;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_i);
    END remove_jurisoptions;

	PROCEDURE remove_jurislogicmapng (id_i IN NUMBER, deleted_by_i IN NUMBER)
    IS
		l_juris_logic_id   NUMBER := id_i;
        l_deleted_by     NUMBER := deleted_by_i;
        l_juris_id       NUMBER;
        l_rid            NUMBER;
        l_nkid           NUMBER;
    BEGIN
	 -- Created this procedure as part of CRAPP-3627 (DB: Datamodel changes to store Jurisdiction Advanced)
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('JURIS_LOGIC_GROUP_MAP', l_juris_logic_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM juris_logic_group_map ja
         WHERE ja.id = l_juris_logic_id
        RETURNING rid, nkid
          INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, l_deleted_by
               FROM tmp_delete);

        UPDATE juris_logic_group_map jo
           SET next_rid = NULL
         WHERE jo.next_rid = l_rid AND jo.nkid = l_nkid;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_i);
    END remove_jurislogicmapng;


        --Jira 3689 start

    PROCEDURE remove_juris_error_messages (id_i IN NUMBER, deleted_by_i IN NUMBER)
    IS
		l_juris_message_id   NUMBER := id_i;
        l_deleted_by     NUMBER := deleted_by_i;
        l_juris_id       NUMBER;
        l_rid            NUMBER;
        l_nkid           NUMBER;
    BEGIN
	 -- Created this procedure as part of CRAPP-3689 (DB: Data model for Jurisdiction Messages)
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('JURIS_ERROR_MESSAGES', l_juris_message_id);

        --rely on RLS policy to prevent locked records from being deleted
        --rely on FK constraint to prevent delete if there are dependent records
        DELETE FROM juris_error_messages ja
         WHERE ja.id = l_juris_message_id
        RETURNING rid, nkid
          INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, l_deleted_by
               FROM tmp_delete);

        UPDATE juris_error_messages jo
           SET next_rid = NULL
         WHERE jo.next_rid = l_rid AND jo.nkid = l_nkid;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || id_i);
    END remove_juris_error_messages;

    --Jira 3689 end

END JURISDICTION;
/