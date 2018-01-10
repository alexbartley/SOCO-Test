CREATE OR REPLACE PACKAGE BODY content_repo.taxability
IS


/*
--
-- TDR Taxabilities
--
-- MODIFICATION HISTORY
-- Person      Date     Comments
-- ---------   ------   -----------------------------------------------------------
-- ***         **2016   TDR 2.0
-- nnt         20170420 CRAPP-3518, cleanup
-- nnt         20170912 reapplied Add_verification (prototype procedure) CRAPP-3918
-- pmr         20171026 CRAPP-2800 Added bulk verification process for taxability review process.
                        Added log_action_log_error procedure and removed internal commits during exception

*/




    -- Variables for copy taxability action log message
    lcopy_err_message clob;
    lcopy_link varchar2(200);
    /** FN: build AND with IN criteria variable contaiupdate_attr
    ns more than one item.
     *
     */

     PROCEDURE log_action_log_error (referrer varchar2, entered_by number, err_message varchar2, process_id_i number default null)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        lprocess_id number := process_id_i;
    BEGIN
        if lprocess_id is null
        then
            lprocess_id := crapp_admin.pk_action_log_process_id.nextval;
        end if;

        insert into crapp_admin.action_log ( process_id, status, referrer, entered_by, parameters )
        values ( lprocess_id, -1, ''||referrer, entered_by, err_message);
        commit;
    END;

    FUNCTION fnandis (searchvar IN VARCHAR2, datacol IN VARCHAR2)
        RETURN VARCHAR2
    IS
        srchi   VARCHAR2 (64);
    /**
     *  Build AND / IN, NULL set for a list of values and a specified column
     *  Example: SELECT dev_BuildQryAndIs(SEARCHVAR=>'3,4,5,6,7,10'
                                         ,DATACOL=>'tbl.myColumn') FROM dual;
     *  Function was first used for list of numbers and would build a col = null when
     *  value is less than 0 or = when a single number is used.
     *  (could be expanded with a parameter for what operator should be used eq. lt. etc)
     *  '' would be a blank and no AND statement would be built
     */
    BEGIN
        IF LENGTH (searchvar) > 0
        THEN
            IF REGEXP_COUNT (searchvar, ',', 1, 'i') > 0
            THEN
                srchi := ' AND ' || datacol || ' IN(' || searchvar || ')';
            ELSE
                -- cluge
                IF TO_NUMBER (searchvar) > 0
                THEN
                    srchi := ' AND ' || datacol || ' = ' || searchvar;
                ELSE
                    srchi := ' AND ' || datacol || ' is null ';
                END IF;
            END IF;
        ELSE
            srchi := ' ';
        END IF;
        RETURN srchi;
    END fnandis;


    /** MAIN SEARCH
     *  Search taxability within a jurisdiction
     *  jurisdiction_id required
     */
    FUNCTION searchtaxability (pjurisdiction_id     IN NUMBER,
                               ptaxabilityrefcode   IN VARCHAR2 DEFAULT NULL,
                               ptaxability          IN VARCHAR2 DEFAULT NULL,
                               ptaxsystem           IN VARCHAR2 DEFAULT NULL,
                               pspecapplic          IN VARCHAR2 DEFAULT NULL,
                               ptransapplic         IN VARCHAR2 DEFAULT NULL,
                               pcalcmethod          IN VARCHAR2 DEFAULT NULL,
                               ptags                IN VARCHAR2 DEFAULT NULL,
                               peffective           IN VARCHAR2 DEFAULT NULL,
                               prevision            IN VARCHAR2 DEFAULT NULL)
        RETURN outtable
        PIPELINED
    IS
        datarecord   outset;
        cursor_tx    SYS_REFCURSOR;
        bchkvalid    BOOLEAN;
    BEGIN
        -- check mandatory parameter
        bchkvalid := (pjurisdiction_id > 0);
        IF bchkvalid
        THEN
            gettaxability (pjurisdiction_id     => pjurisdiction_id,
                           ptaxabilityrefcode   => ptaxabilityrefcode,
                           ptaxability          => ptaxability,
                           ptaxsystem           => ptaxsystem,
                           pspecapplic          => pspecapplic,
                           ptransapplic         => ptransapplic,
                           pcalcmethod          => pcalcmethod,
                           ptags                => ptags,
                           peffective           => peffective,
                           prevision            => prevision,
                           p_ref                => cursor_tx);
            IF cursor_tx%ISOPEN
            THEN
                LOOP
                    FETCH cursor_tx INTO datarecord;
                    EXIT WHEN cursor_tx%NOTFOUND;
                    PIPE ROW (datarecord);
                END LOOP;
                CLOSE cursor_tx;
            END IF;

            RETURN;
        ELSE
            RAISE errnums.missing_req_val;
        END IF;
    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            errlogger.
             report_and_stop (errnums.en_missing_req_val,
                              'Missing Jurisdiction Id');
        WHEN OTHERS
        THEN
            errlogger.report_and_stop (SQLCODE, SQLERRM);
            RAISE;
    END;


    /** Taxability Form: Header (1)
     *
     */
    FUNCTION fndisplayheader (applicability_rid IN NUMBER)
        RETURN outheadertable PIPELINED
    IS
        datarecord   outheaderds;
        cursor_hdr   SYS_REFCURSOR;
    BEGIN
        taxability_header (applicability_rid, cursor_hdr);
        IF cursor_hdr%ISOPEN
        THEN
            LOOP
                FETCH cursor_hdr INTO datarecord;
                EXIT WHEN cursor_hdr%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_hdr;
        END IF;
        RETURN;
    END;


    /** Taxability applicability types
     *  tax_applicability_sets
     */
    FUNCTION fndisplaygroups (applicability_rid IN NUMBER)
        RETURN outgrouptable
        PIPELINED
    IS
        datarecord   outgroupds;
        cursor_grp   SYS_REFCURSOR;
    BEGIN
        taxability_groups (applicability_rid, cursor_grp);
        IF cursor_grp%ISOPEN
        THEN
            LOOP
                FETCH cursor_grp INTO datarecord;
                EXIT WHEN cursor_grp%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_grp;
        END IF;
        RETURN;
    END;


    /** Taxability applicability taxes
     *  tax_applicability_taxes
     */
    FUNCTION fndisplaytaxes (applicability_rid IN NUMBER)
        RETURN outappltaxes
        PIPELINED
    IS
        datarecord   outappltaxesds;
        cursor_tax   SYS_REFCURSOR;
    BEGIN
        taxability_applic (applicability_rid, cursor_tax);
        IF cursor_tax%ISOPEN
        THEN
          LOOP
              FETCH cursor_tax INTO datarecord;
              EXIT WHEN cursor_tax%NOTFOUND;
              PIPE ROW (datarecord);
            END LOOP;
          CLOSE cursor_tax;
        END IF;
        RETURN;
    END;


    /** Lookup Imposition Reference Codes
     *
     */
    FUNCTION fnlookuprefcode (jurisdiction_nkid IN NUMBER)
        RETURN outlkprefcode
        PIPELINED
    IS
        datarecord   outlookupds;
        cursor_lkp   SYS_REFCURSOR;
    BEGIN
        lookup_imp_refcode(jurisdiction_nkid, cursor_lkp);
        IF cursor_lkp%ISOPEN
        THEN
            LOOP
                FETCH cursor_lkp INTO datarecord;

                EXIT WHEN cursor_lkp%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_lkp;
        END IF;
        RETURN;
    END;


    /** Taxability additional attributes
     *
     */
    FUNCTION fndisplayadditional (applicability_rid IN NUMBER)
        RETURN outaddattrib
        PIPELINED
    IS
        datarecord   outadditionalds;
        cursor_ad    SYS_REFCURSOR;
    BEGIN
        taxability_additional(applicability_rid, cursor_ad);
        IF cursor_ad%ISOPEN
        THEN
            LOOP
                FETCH cursor_ad INTO datarecord;
                EXIT WHEN cursor_ad%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_ad;
        END IF;
    END;

    FUNCTION fnDisplayConditions(applicability_rid IN NUMBER)
        RETURN outConditions
        PIPELINED
    IS
        datarecord outConditionsDS;
        cursor_cd sys_refcursor;
    BEGIN
        taxability_conditions(applicability_rid, cursor_cd);
        IF cursor_cd%ISOPEN
        THEN
            LOOP
                FETCH cursor_cd INTO datarecord;
                EXIT WHEN cursor_cd%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_cd;
        END IF;
    END;

    /** Return list of calculation structure id
     *
     */
    FUNCTION retcalculation_structure_id
        RETURN VARCHAR2
    IS
        retcalcstrid   VARCHAR2 (64);
    BEGIN
        SELECT listagg (id, ',') WITHIN GROUP (ORDER BY id) AS idlist
          INTO retcalcstrid
          FROM calculation_methods;
        RETURN retcalcstrid;
    END;


    /** Return list of Taxability Type names
     *
     */
    FUNCTION rettaxabilitytype_id
        RETURN VARCHAR2
    IS
        rettaxtype   VARCHAR2 (128);
    BEGIN
        SELECT listagg (name, ',') WITHIN GROUP (ORDER BY id) AS txtypeid
          INTO rettaxtype
          FROM applicability_types;
        RETURN rettaxtype;
    END;


    /** DEV: Taxability - Additional
     *  OUT Additional Attributes
     */
    FUNCTION fadditional (juristaxid   IN NUMBER DEFAULT NULL,
                          applictype   IN NUMBER DEFAULT 1)
        RETURN tbladditional
        PIPELINED
    IS
        datarecord   dsadditional;
        cursor_ad    SYS_REFCURSOR;
    BEGIN
    null;
        /*pxadditional (juristaxid, applictype, cursor_ad);
        IF cursor_ad%ISOPEN
        THEN
            LOOP
                FETCH cursor_ad INTO datarecord;
                EXIT WHEN cursor_ad%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_ad;
        END IF;*/
    END;


    /** Return unique list of tags
     *  Dev: Generic
     */
    FUNCTION returnuniquetags
        RETURN outdstbl
        PIPELINED
    IS
        datarecord    outdsrec;
        cursor_tags   SYS_REFCURSOR;
    BEGIN
        lkpgettags (cursor_tags);
        IF cursor_tags%ISOPEN
        THEN
            LOOP
                FETCH cursor_tags INTO datarecord;
                EXIT WHEN cursor_tags%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_tags;
        END IF;
    END returnuniquetags;


    /** Return list of Calculation Methods
     *
     */
    FUNCTION returncalculationmethod
        RETURN outdstbl
        PIPELINED
    IS
        datarecord   outdsrec;
        cursor_cm    SYS_REFCURSOR;
    BEGIN
        lkpcalculationmethod (cursor_cm);
        IF cursor_cm%ISOPEN
        THEN
            LOOP
                FETCH cursor_cm INTO datarecord;
                EXIT WHEN cursor_cm%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_cm;
        END IF;
    END returncalculationmethod;


    /** Create Taxability Output Id
     *  PENDING: not verified
     */
    FUNCTION fcreatetaxabilityoutput (
        applicability_id          IN NUMBER,
        tax_app_tax_id_i          IN NUMBER,
        shorttxt                  IN VARCHAR2,
        juris_tax_imposition_id_i IN NUMBER,
        start_date_i              IN DATE,
        end_date_i                IN DATE,
        appl_type_id_i            IN NUMBER,
        entered_by_i              IN NUMBER)
        RETURN NUMBER
    IS

        l_taxability_output_id   NUMBER;
        l_start_date  date;
        l_end_date    date;
        l_short_text  varchar2(250);
        vcnt          number;
        vreference_code varchar2(20);
        v_applicability varchar2(20);
        -- Changes for CRAPP-2682. This should be changed for future jira CRAPP-2688
        l_jta_nkid number;
        l_tat_nkid number;
    BEGIN

    l_short_text := shorttxt;

    select name into v_applicability from applicability_types where id = appl_type_id_i;

    -- Changes for CRAPP-2682. This should be changed for future jira CRAPP-2688
    select nkid into l_jta_nkid from juris_tax_applicabilities where id = applicability_id;

    if tax_app_tax_id_i is not null then
        select nkid into  l_tat_nkid from tax_applicability_taxes where id = tax_app_tax_id_i;
    end if;


    if l_short_text is NULL then

        if v_applicability = 'Exempt'
        then
                l_short_text :=  'Exempt';
        elsif v_applicability = 'No Tax'
        then
                l_short_text :=  'No Tax';
        else

           select reference_code into vreference_code from juris_tax_impositions where id = juris_tax_imposition_id_i;

            SELECT CASE
                   WHEN (vreference_code = 'CU') THEN 'Consumer''s Use Tax'
                   WHEN (vreference_code = 'SU') THEN 'Seller''s Use Tax'
                   WHEN (vreference_code = 'ST') THEN 'Sales Tax'
                   WHEN (vreference_code LIKE 'AP%') THEN 'Apparel - Partial Exemption'
                   WHEN (vreference_code LIKE 'GR%') THEN 'Food Rate' ELSE vreference_code END
            INTO l_short_text
            FROM dual;

        end if;

    end if;

    dbms_output.put_line('l_short_text value after validation is '||l_short_text);
    dbms_output.put_line('entered_by value is: '||entered_by_i);
    begin

        -- Changes for CRAPP-2682. This should be changed for future jira CRAPP-2688
        select id into l_taxability_output_id from taxability_outputs
         where juris_tax_applicability_nkid = l_jta_nkid
           and nvl(tax_applicability_tax_nkid, -999) = nvl(l_tat_nkid, -999)
           and next_rid is null;

        dbms_output.put_line('l_taxability_output_id value is '||l_taxability_output_id);

        update taxability_outputs
           SET short_text = l_short_text,
               full_text = l_short_text,
               end_date = end_date_i,
               entered_by = entered_by_i
        where id = l_taxability_output_id
        returning id into l_taxability_output_id;

    exception
    when no_data_found
    then

            dbms_output.put_line('About to create the new invoice statement');

            INSERT INTO taxability_outputs (juris_tax_applicability_id, short_text, full_text,
                                                entered_by, start_date, end_date, status,
                                                tax_applicability_tax_id
                                                )
                VALUES (applicability_id, l_short_text, l_short_text, entered_by_i, start_date_i, end_date_i, 0, tax_app_tax_id_i
                        )
                RETURNING id INTO l_taxability_output_id;
    end;

        RETURN l_taxability_output_id;
    END;


    /** Create 'transaction_taxabilities' id  if not known
     *  nApplicability_id - known applicability id
     *  pnTransaction_Tax_Id - null or existing transaction_tx id
     *  nApplicability_Type_id - known 'Applicability_Types' id
     *  sTrans_Name - name [transaction_taxabilities.name]
     *  dStart_Date - [transaction_taxabilities.start_date]
     *  dEnd_Date - [transaction_taxabilities.end_date]
     *  nEntered_by - UI user id
     *  p_rid_o OUT transaction_taxabilities.rid
     *  p_nkid_o OUT transaction_taxabilities.nkid
     */
    PROCEDURE gencreatetransactiontaxid (
        napplicability_id        IN     NUMBER,
        pntransaction_tax_id     IN OUT NUMBER,
        napplicability_type_id   IN     NUMBER,
        strans_name              IN     VARCHAR2,
        dstart_date              IN     DATE,
        dend_date                IN     DATE,
        nentered_by              IN     NUMBER,
        p_rid_o                     OUT NUMBER,
        p_nkid_o                    OUT NUMBER)
    IS
        bexisting   BOOLEAN := FALSE;
        p_ref       SYS_REFCURSOR;
    BEGIN

-- TNN: replaced after database changes
null;
/*        IF pntransaction_tax_id IS NULL
        THEN
            INSERT INTO transaction_taxabilities (juris_tax_applicability_id,
                                                  applicability_type_id,
                                                  reference_code,
                                                  start_date,
                                                  end_date,
                                                  entered_by)
            VALUES (napplicability_id,
                    napplicability_type_id,
                    strans_name,
                    dstart_date,
                    dend_date,
                    nentered_by)
            RETURNING id, rid, nkid
              INTO pntransaction_tax_id, p_rid_o, p_nkid_o;
        END IF;*/
    END;

    /** Taxability Form Header Dataset
     *
     */
    FUNCTION taxab_header_lookup (jurisdiction_id              IN NUMBER,
                                  code                         IN VARCHAR2,
                                  taxation_type_id             IN NUMBER,
                                  transaction_type_id          IN NUMBER,
                                  spec_applicability_type_id   IN NUMBER,
                                  tax_description_id           IN NUMBER,
                                  calculation_method_id        IN NUMBER)
        RETURN tbltaxabilityhdr
        PIPELINED
    IS
        datarecord   outtaxabhdr_ds;
        cursor_cm    SYS_REFCURSOR;
    BEGIN
        vselectformheader (jurisdiction_id,
                           code,
                           taxation_type_id,
                           transaction_type_id,
                           spec_applicability_type_id,
                           tax_description_id,
                           calculation_method_id,
                           cursor_cm);

        IF cursor_cm%ISOPEN
        THEN
            LOOP
                FETCH cursor_cm INTO datarecord;
                EXIT WHEN cursor_cm%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;
            CLOSE cursor_cm;
        END IF;
    END taxab_header_lookup;

    /** XML for commoditites
     *
     */
    PROCEDURE xmlbuild_commoditylist (sx         IN     CLOB,
                                      success       OUT NUMBER,
                                      recgrpid      OUT NUMBER)
    IS
    /* 10/11/2013 change:
        -- success - flag
        -- recGrpId - stored juris_taxable_descriptions id
       10/14/2013: not in use. It is now in its own package
    */
        rec_count   NUMBER NOT NULL DEFAULT 0;
    BEGIN
        success := 0;
        recgrpid := 1;
    END;

    /** Get tags
     *  NOT IN USE
     */
    PROCEDURE lkpgettags (refcurs OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN refcurs FOR
            'SELECT to_char(jtgs.ref_nkid) NKID, jtgs.tag_id
                        FROM juris_tax_app_tags jtgs';
    -- JOIN tags tgs
    -- 'WHERE --- = :---'
    -- USING ---;
    END lkpgettags;

    /** Get Calculation Methods
     *  test Lookup Calculation Methods
     */
    PROCEDURE lkpcalculationmethod (refcurs OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN refcurs FOR 'SELECT description, id FROM calculation_methods
                        ORDER BY description';
    -- 'WHERE --- = :---'
    -- USING ---;
    END;

    /** Example Lookup Combobox style procedure
     *  Pipe records back to requestor
     *  Available:
     *  showdescriptions - list description and id
     *  showimprefcodes  - imposition reference codes
     */
    FUNCTION taxab_section_lookup (sectionname IN VARCHAR2)
        RETURN outdstbl
        PIPELINED
    IS
        datarecord    outdsrec;
        cursor_cmbx   SYS_REFCURSOR;
    BEGIN
        lookup_cmbx (sectionname, cursor_cmbx);

        IF cursor_cmbx%ISOPEN
        THEN
            LOOP
                FETCH cursor_cmbx INTO datarecord;

                EXIT WHEN cursor_cmbx%NOTFOUND;
                PIPE ROW (datarecord);
            END LOOP;

            CLOSE cursor_cmbx;
        END IF;
    END taxab_section_lookup;

    /** Dev only: Combo box generic test procedure
     *
     */
    PROCEDURE lookup_cmbx (cmbx_name IN VARCHAR2, p_ref OUT SYS_REFCURSOR)
    IS
    BEGIN
        CASE cmbx_name
            WHEN 'showdescriptions'
            THEN
                OPEN p_ref FOR
                    SELECT DISTINCT description, id
                      FROM tax_descriptions
                    ORDER BY description;
            WHEN 'showimprefcodes'
            THEN
                OPEN p_ref FOR
                    SELECT DISTINCT reference_code, id
                      FROM juris_tax_impositions
                    ORDER BY reference_code;
        END CASE;
    END lookup_cmbx;

    /** Dev Lookup help procedure
     *  Applicability Types
     */
    PROCEDURE uiapplicability_types (fstatus   IN     NUMBER,
                                     p_ref        OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR 'SELECT ID, NAME
      FROM applicability_types
      WHERE status = :fStatus
      ORDER BY id' USING fstatus;
    END uiapplicability_types;

    /** Dev Lookup Help procedure
     *  Tax Descriptions
     */
    PROCEDURE uitax_descriptions (fstatus    IN     NUMBER,
                                  ftr_type   IN     NUMBER,
                                  ftx_type   IN     NUMBER,
                                  fsp_type   IN     NUMBER,
                                  p_ref         OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR 'SELECT * FROM tax_descriptions
      WHERE status = :fStatus
      and transaction_type_id = :fTr_type
      and taxation_type_id = :fTx_type
      and spec_applicability_type_id = :fSp_type
      ORDER BY id'
            USING fstatus,
                  ftr_type,
                  ftx_type,
                  fsp_type;
    END uitax_descriptions;

    /** Dev Lookup Help procedure
     *  Calculation Method description and ID
     */
    PROCEDURE uicalculation_methods (fstatus   IN     NUMBER,
                                     p_ref        OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR 'SELECT id, description FROM calculation_methods
     where status = :fStatus'
            USING fstatus;
    END;

    /** Dev: removed
     *
     */
    PROCEDURE slproduct_list (jurisdiction_id      IN NUMBER,
                              tax_description_id   IN NUMBER,
                              ref_code             IN VARCHAR2,
                              calc_method_id       IN NUMBER,
                              dstartdate           IN DATE DEFAULT NULL,
                              denddate             IN DATE DEFAULT NULL)
    IS
        tmp_jurisdiction_id   jurisdictions.id%TYPE;
        cr_enddate            DATE;
    BEGIN
        cr_enddate := SYSDATE;
    END slproduct_list;

    /** Dev Taxability Edit Form Header - used for PL/SQL test only
     *
     **/
    PROCEDURE vselectformheader (
        jurisdiction_id              IN     NUMBER,
        code                         IN     VARCHAR2,
        taxation_type_id             IN     NUMBER,
        transaction_type_id          IN     NUMBER,
        spec_applicability_type_id   IN     NUMBER,
        tax_description_id           IN     NUMBER,
        calculation_method_id        IN     NUMBER,
        p_ref                           OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR
        'SELECT
       jurisdiction_id,
       start_date,
       end_date,
       tax_categorization,
       taxability_reference,
       code,
       basis_percent,
       calculation_method,
       juris_tax_imposition_id,
       tax_applicability_id,
       tax_description_id,
       calculation_method_id,
       attribute_value,
       attribute_id,
       description_id,
       taxation_type_id,
       transaction_type_id,
       spec_applicability_type_id
       FROM
         taxability_form_header_set_v
       WHERE
       jurisdiction_id = :jurisdiction_id
       AND code = :code
       AND taxation_type_id = :taxation_type_id
       AND transaction_type_id = :transaction_type_id
       AND spec_applicability_type_id = :spec_applicability_type_id
       AND tax_description_id = :tax_description_id
       AND calculation_method_id = :calculation_method_id
       '
            USING jurisdiction_id,
                  code,
                  taxation_type_id,
                  transaction_type_id,
                  spec_applicability_type_id,
                  tax_description_id,
                  calculation_method_id;
    -- ToDo add on calculation_method_id, taxability_reference
    /* Aug: Selection change: use Main FN searchTaxability for search dataset output.*/
    END vselectformheader;


procedure parse_applTaxes ( sx clob, rec out xmlform_appltaxes_ty )
IS
    -- crxmlappltaxarr taxability.xmlform_appltaxes;

    crxmlappltaxarr xmlform_appltaxes_ty := xmlform_appltaxes_ty();

    BEGIN
        dbms_output.put_line('Taxes Parsing Start -->');
        SELECT
              h.id
              --,h.rid
              -- ,h.nkid
              -- ,h.nextRid
              ,jurisTaxImpositionId
              ,jurisTaxApplicabilityId
              ,ref_rule_order
              ,taxType
              ,taxTypeId
              ,to_date(startDate,'dd-mon-yy') start_date
              ,to_date(enddate,'dd-mon-yy') end_date
              , deleted
              , replace(invoice_statement, chr(39),'''')
        BULK COLLECT INTO crxmlappltaxarr
        from XMLTable('for $i in /taxability/applicableTaxes return $i'
              passing
              xmltype(sx)
              columns
              id number path 'id',
              jurisTaxImpositionId number path 'jurisTaxImpositionId',
              jurisTaxApplicabilityId number path 'jurisTaxApplicabilityId',
              ref_rule_order number path 'refRuleOrder',
              taxType varchar2(5 char) path 'taxType',
              taxTypeId number path 'taxTypeId',
              startDate varchar2(50) path 'startDate',
              endDate varchar2(50) path 'endDate',
              deleted varchar2(1 char) path 'deleted',
              invoice_statement varchar2(250 char) PATH 'invoiceStatement'
              ) h;

        dbms_output.put_line('Taxes Parsing End   -->');

        rec := crxmlappltaxarr;

    END parse_applTaxes;


procedure parse_applAttr ( sx clob, rec out xmlform_applattr_ty, flag number default 0 )
IS
        -- crxmlappltaxarr taxability.xmlform_appltaxes;

        crxmlapplattrarr xmlform_applattr_ty := xmlform_applattr_ty();

    BEGIN

        SELECT
            ID
            --,NKID
            ,JURIS_TAX_APPLICABILITY_ID
            --,JURIS_TAX_APPLICABILITY_NKID
            ,ATTRIBUTE_ID
            ,START_DATE
            ,END_DATE
         --   ,ENTERED_BY
           -- ,ENTERED_DATE
            ,VALUE
            ,DELETED
        BULK COLLECT INTO crxmlapplattrarr
        from XMLTable('for $i in /taxability/attributes return $i'
              passing
              xmltype(sx)
              columns
                ID                           NUMBER PATH 'id',
                JURIS_TAX_APPLICABILITY_ID   NUMBER PATH 'jurisTaxApplicabilityId',
                ATTRIBUTE_ID                 NUMBER PATH 'attributeId',
                START_DATE           VARCHAR2(50)   PATH 'startDate',
                END_DATE             VARCHAR2(50)   PATH 'endDate',
                VALUE                        CLOB   PATH 'value',
                DELETED                VARCHAR2(1)     PATH 'deleted'
              ) h;

      rec := crxmlapplattrarr;

    END parse_applAttr;


procedure parse_applConditions ( sx clob, rec out xmlform_applcond_ty, flag number default 0 )
IS
        -- crxmlappltaxarr taxability.xmlform_appltaxes;

        xmlapplcondarr xmlform_applcond_ty := xmlform_applcond_ty();

    BEGIN

        dbms_output.put_line('Inside xmlform_applConditions procedure ');
        SELECT
                ID
                -- ,NKID
                --,JURIS_TAX_APPLICABILITY_NKID
                ,JURIS_TAX_APPLICABILITY_ID
                --,JURISDICTION_NKID
                ,JURISDICTION_ID
                ,REFERENCE_GROUP_ID
                ,TAXABILITY_ELEMENT_ID
                ,LOGICAL_QUALIFIER
                ,VALUE
                ,ELEMENT_QUAL_GROUP
                ,START_DATE
                ,END_DATE
                --,ENTERED_BY
                --,ENTERED_DATE
                --,STATUS
                ,QUALIFIER_TYPE
                ,DELETED
        BULK COLLECT INTO xmlapplcondarr
        from XMLTable('for $i in /taxability/applicableConditions return $i'
              passing
              xmltype(sx)
              columns
                ID                              NUMBER path 'id',
                --NKID                            NUMBER path 'nkid',
                --JURIS_TAX_APPLICABILITY_NKID      NUMBER path 'transNkid',
                JURIS_TAX_APPLICABILITY_ID        NUMBER path 'jurisTaxApplicabilityId',
                --JURISDICTION_NKID               NUMBER path 'jurisdiction_nkid',
                JURISDICTION_ID                 NUMBER path 'jurisdictionId',
                REFERENCE_GROUP_ID                NUMBER path 'referenceGroupId',
                TAXABILITY_ELEMENT_ID           NUMBER path 'taxabilityElementId',
                LOGICAL_QUALIFIER               VARCHAR2(100) path 'logicalQualifierId',
                VALUE                           VARCHAR2(100) path 'value',
                ELEMENT_QUAL_GROUP              VARCHAR2(100) path 'elementQualGroup',
                START_DATE                      varchar2(50) path 'startDate',
                END_DATE                        varchar2(50) path 'endDate',
                --ENTERED_BY                      NUMBER path 'enteredBy',
                --ENTERED_DATE                    varchar2(50) path 'enteredDate',
                --STATUS                          NUMBER path 'status',
                QUALIFIER_TYPE                  VARCHAR2(16) path 'element_value_type',
                DELETED                         VARCHAR2(1 CHAR) path 'deleted'
              ) h;

        rec := xmlapplcondarr;

    END parse_applConditions;


procedure parse_applheader ( sx in CLOB, rec_applheader OUT  appl_header)
is
    frmheader appl_header;

    begin

        SELECT
            h.id,
            h.nkid,
            h.applicability_type_id,
            h.calculation_method,
            h.input_recoverability,
            h.basis_percent,
            h.recoverable_amount,
            h.charge_type_id,
            h.unit_of_measure,
            h.ref_rule_order,
            h.tax_type,
            to_date(h.start_date,'dd-Mon-yy') start_date,
            to_date(h.end_date,'dd-Mon-yy') end_date,
            h.all_taxes_apply,
            h.commodity_id,
            h.jurisdiction_id,
            h.entered_by,
            h.default_taxability,
            h.product_tree_id,
            is_local,
            h.legal_statement,
            to_date(h.ls_start_date, 'dd-Mon-yy') ls_start_date,
            h.deleted
            into
                frmheader.id,
                frmheader.nkid,
                frmheader.applicability_type_id,
                frmheader.calculation_method,
                frmheader.input_recoverability,
                frmheader.basis_percent,
                frmheader.recoverable_amount,
                frmheader.charge_type_id,
                frmheader.unit_of_measure,
                frmheader.ref_Rule_Order,
                frmheader.tax_type,
                frmheader.start_date,
                frmheader.end_date,
                frmheader.all_taxes_apply,
                frmheader.commodity_id,
                frmheader.jurisdiction_id,
                frmheader.entered_by,
                frmheader.default_taxability,
                frmheader.product_tree_id,
                frmheader.is_local,
                frmheader.legal_statement,
                frmheader.ls_start_date,
                frmheader.deleted
            FROM XMLTABLE ('/taxability'
            PASSING xmltype (sx) COLUMNS
                id                     NUMBER PATH 'id',
                nkid                   NUMBER PATH 'nkid',
                applicability_type_id  NUMBER PATH 'applicabilityTypeId',
                calculation_method     NUMBER PATH 'calculationMethodId',
                input_recoverability   NUMBER PATH 'recoverablePercent',
                basis_percent          NUMBER PATH 'basisPercent',
                recoverable_amount     NUMBER PATH 'recoverableAmount',
                charge_type_id         NUMBER PATH 'chargeTypeId',
                unit_of_measure        NUMBER PATH 'unitOfMeasure',
                ref_rule_order         NUMBER PATH 'refRuleOrder',
                tax_type               VARCHAR2(10) PATH 'taxType',
                start_date             VARCHAR2(50) PATH 'startDate',
                end_date               VARCHAR2(50) PATH 'endDate',
                all_taxes_apply        NUMBER PATH 'allTaxesApply',
                commodity_id           NUMBER PATH 'commodityId',
                jurisdiction_id        NUMBER PATH 'jurisdictionId',
                entered_by             NUMBER PATH 'enteredBy',
                default_taxability     NUMBER PATH 'defaultTaxability',
                product_tree_id        NUMBER PATH 'productTreeId',
                is_local               VARCHAR2(2) PATH 'isLocal',
                legal_statement        varchar2(5000) PATH 'legalStatement',
                ls_start_date          varchar2(50) PATH 'defaultTaxabilityDate',
                deleted                number PATH 'deleted'
                ) h;

        rec_applheader := frmheader;

        dbms_output.put_line (' Unit of measure value is '||rec_applheader.unit_of_measure);

    END parse_applheader;


    /** XML Process Taxability Form
     *
     **/

    PROCEDURE xmlprocess_form (sx      IN  CLOB,
                               success OUT NUMBER,
                               nkid_o  OUT NUMBER,
                               rid_o   OUT NUMBER,
                               copy_flag IN NUMBER DEFAULT 0
                               )
    IS
        sxmlpart VARCHAR2(32);

        tag_list xmlform_tags_tt := xmlform_tags_tt();

        rec_appl_header appl_header:= null;

        rec_appl_taxes xmlform_appltaxes_ty := xmlform_appltaxes_ty();
        rec_appl_cond xmlform_applcond_ty := xmlform_applcond_ty();
        rec_appl_attr xmlform_applattr_ty := xmlform_applattr_ty();

        -- Qualif/Conditions
        tbl_qualif xmlform_qualifiers_cond_tt := xmlform_qualifiers_cond_tt();

        l_upd_success  NUMBER := 0;
        l_appl_pk      NUMBER;
        l_appl_nkid    NUMBER;
        l_entered_by   NUMBER;
    BEGIN
        -- Taxability Header --
        dbms_output.put_line('XMLPROCESS_FORM Start -->');

        insert into dev_applicability_xml values ( sx, sysdate, 'XMLPROCESS_FORM');
        COMMIT;

        parse_applheader ( sx, rec_appl_header );

        dbms_output.put_line ( 'rec_appl_header.start_date is '||rec_appl_header.start_date);
        dbms_output.put_line ( 'rec_appl_header.end_date is   '||rec_appl_header.end_date);

        l_entered_by := rec_appl_header.entered_by;

        --commit;

        -- Applicable Attributes
        parse_applAttr ( sx, rec_appl_attr);
        --commit;

        -- Applicable Taxes
        parse_applTaxes ( sx, rec_appl_taxes );
        --commit;

        -- Applicable Conidtions
        parse_applConditions ( sx, rec_appl_cond );
        --commit;

        /* Tags */

        FOR itags IN (SELECT
            h.tag_id,
            h.deleted,
            h.modified
        FROM XMLTABLE ('/taxability/publicationTags'
                        PASSING XMLTYPE(sx)
                        COLUMNS tag_id   NUMBER PATH 'tagId',
                                deleted  NUMBER PATH 'deleted',
                                modified NUMBER PATH 'modified'
                                ) h
        )
        LOOP
          tag_list.extend;
          tag_list( tag_list.last ):= xmlform_tags(4,
              rec_appl_header.nkid,
              rec_appl_header.entered_by,
              itags.tag_id,
              itags.deleted,
              0);
        END LOOP;
        form_update_full (rec_appl_header,
                          rec_appl_attr,
                          rec_appl_taxes,
                          rec_appl_cond,
                          tag_list,
                          rid_o,
                          nkid_o
                          );

       -- rid_o := tax_applicability.get_revision(rid_i => rid_o, entered_by_i => frmheader.entered_by);
        l_upd_success := 1;
        success := l_upd_success;
        commit;
        dbms_output.put_line('XMLPROCESS_FORM End   --> ');

    EXCEPTION
    WHEN errnums.duplicate_key THEN
      ROLLBACK;
      if copy_flag = 0
      then
        dbms_output.put_line('sqlerrm value is '||sqlerrm);
        RAISE_APPLICATION_ERROR(-20300,'Rule Order and Date Range combination already exists on another taxability. Please correct the data and try again.');
      end if;
    WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
        if copy_flag = 0
        then
            errlogger.report_and_stop (
                    errnums.en_cannot_update_record,
                    'Taxability end_date is beyond the start date. Please correct the end_date.');
        else
            --lcopy_err_message := nvl(lcopy_err_message, '{')||',"Entered By":"'||l_entered_by||'"';
            --lcopy_err_message := lcopy_err_message||',"Start Date":"'||rec_appl_header.start_date||'"';
            --lcopy_err_message := lcopy_err_message||',"End Date":"'||rec_appl_header.end_date||'"';
            lcopy_err_message := nvl(lcopy_err_message, '{')||',"Error Message":"Taxability end_date is beyond the start date. Please correct the end_date."}';
            dbms_output.put_line('lcopy_err_message value is '||lcopy_err_message);

            log_action_log_error(' '||lcopy_link, l_entered_by, lcopy_err_message);

        end if;

        WHEN errnums.cannot_update_child
        THEN
            ROLLBACK;
        if copy_flag = 0
        then
            errlogger.report_and_stop (
                errnums.en_cannot_update_child,
                'One of the child collection date range is above or beyond taxability date range. Please correct the dates');
        else
            --lcopy_err_message := nvl(lcopy_err_message, '{')||',"Entered By":"'||l_entered_by||'"';
            --lcopy_err_message := lcopy_err_message||',"Start Date":"'||rec_appl_header.start_date||'"';
            --lcopy_err_message := lcopy_err_message||',"End Date":"'||rec_appl_header.end_date||'"';
            lcopy_err_message := nvl(lcopy_err_message, '{')||',"Error Message":"One of the child collection date range is above or beyond taxability date range. Please correct the dates."}';
            dbms_output.put_line('lcopy_err_message value is '||lcopy_err_message);

            log_action_log_error(' '||lcopy_link, l_entered_by, lcopy_err_message);

        end if;
        WHEN NO_DATA_FOUND
        THEN
            ROLLBACK;
        if copy_flag = 0
        then
            errlogger.report_and_go (
                        SQLCODE,
                        'Record could not be updated because the ID was not found.');
        else
            --lcopy_err_message := nvl(lcopy_err_message, '{')||',"Entered By":"'||l_entered_by||'"';
            --lcopy_err_message := lcopy_err_message||',"Start Date":"'||rec_appl_header.start_date||'"';
            --lcopy_err_message := lcopy_err_message||',"End Date":"'||rec_appl_header.end_date||'"';
            lcopy_err_message := nvl(lcopy_err_message, '{')||',"Error Message":"Record could not be updated because the ID was not found."}';
            dbms_output.put_line('lcopy_err_message value is '||lcopy_err_message);

            log_action_log_error(' '||lcopy_link, l_entered_by, lcopy_err_message);

        end if;
        WHEN OTHERS
        THEN
            dbms_output.put_line('Entered into exception block '||sqlerrm);
            ROLLBACK;
          if copy_flag = 0
          then
--              RAISE;
                RAISE_APPLICATION_ERROR(-20300,'Taxability is not valid. Check start, end date and rule order.');
          else
              --lcopy_err_message := nvl(lcopy_err_message, '{')||',"Entered By":"'||l_entered_by||'"';
            --lcopy_err_message := lcopy_err_message||',"Start Date":"'||rec_appl_header.start_date||'"';
            --lcopy_err_message := lcopy_err_message||',"End Date":"'||rec_appl_header.end_date||'"';
            lcopy_err_message := nvl(lcopy_err_message, '{')||',"Error Message":"'||sqlcode||':'||sqlerrm||' at '||
                                    replace(
                                                replace( DBMS_UTILITY.format_error_backtrace, '"', '')
                                                , chr(10), ''
                                           )||'."}';
            dbms_output.put_line('lcopy_err_message value is '||lcopy_err_message);

            log_action_log_error(' '||lcopy_link, l_entered_by, lcopy_err_message);

          end if;
    END xmlprocess_form;

    function get_applicability_nkid (jta_or_tat_id in number, entity_id_i number ) -- JTA 1, TAT 2
    return number
    is
        l_nkid number;
    begin
        if entity_id_i = 1
        then
            select nkid into l_nkid from juris_tax_applicabilities where id = jta_or_tat_id;
        else
            select nkid into l_nkid from tax_applicability_taxes where id = jta_or_tat_id;
        end if;

        return l_nkid;

    exception
    when others
    then
        return -1;
    end;

-- ttt
    PROCEDURE form_update_full (
        frmheader        IN  appl_header,
        rec_appl_attr    IN  xmlform_applattr_ty,
        rec_appl_taxes   IN  xmlform_appltaxes_ty,
        rec_appl_cond    IN  xmlform_applcond_ty,
        tag_list         IN  xmlform_tags_tt,
        rid_o            OUT NUMBER,
        nkid_o           OUT NUMBER)

    IS
        l_tx_hdr_id      NUMBER := frmheader.id;
        l_appl_pk        NUMBER;
        l_applic_rid     NUMBER;
        l_applic_nkid    NUMBER;
        l_condition_id   NUMBER;
        l_attr_pk        NUMBER;
        l_entered_by     NUMBER := frmheader.entered_by;
        l_appltax_pk     NUMBER;
        l_applcond_pk    NUMBER;
        l_applattr_pk    NUMBER;
        l_cnt            NUMBER := 0;
        l_hdr_end_date   DATE := frmheader.end_date; -- crapp-2603

        -- 1 taxable, 2 exempt, notax, outof, notliab
        rec_ins_apptax   xmlform_appltaxes;
        rec_ins_applattr xmlform_applattr;
        rec_ins_appcond  xmlform_applcond;
        l_success_o      NUMBER;
        l_rid            NUMBER;
        lruleorder       NUMBER;
        vdup_taxability_cnt number;
        l_jta_nkid      NUMBER;
        l_tat_nkid      NUMBER;
        l_start_date    DATE;
        l_end_date      DATE;
		-- CRAPP-4050
		ln_id	juris_tax_applicabilities.id%TYPE;
		ln_status	juris_tax_applicabilities.status%TYPE;
		ln_rid	juris_tax_applicabilities.rid%TYPE;
		ln_delete_tax_flag NUMBER := 0;
		ln_delete_taxability_flag NUMBER := 0;
		ln_count_status	 NUMBER := 0;

    BEGIN
        -- Detail set items + Taxability Outputs
        Dbms_output.put_line('FORM_UPDATE_FULL Start -->');
        Dbms_output.put_line('Applicable Header Entered_by  -->  '|| l_entered_by );

        if frmheader.deleted = 1 then
            dbms_output.put_line(' Calling Delete Revsion');
            delete_revision ( frmheader.id, frmheader.entered_by, l_success_o, rid_o, nkid_o );
        else
          if nvl( frmheader.end_date, '31-Dec-9999' ) < frmheader.start_date then
             raise errnums.cannot_update_record;
          else
             Dbms_output.put_line('Applicable Header End_Date    -->  '|| l_hdr_end_date );

             -- There is a data restriction at Determination Level not to accept the data if there exists any under same authority
             -- with rule_order, start_date and is_local.

             -- Here below is the check to do that

/*             begin
               -- What should happen when inserting? Fail the process and stop. If it is during COPY, reject and log record details and proceed.
               -- What should happen when updating?

                select count(1) into vdup_taxability_cnt from juris_tax_applicabilities
                 where jurisdiction_id = frmheader.jurisdiction_id
                   and ref_rule_order = frmheader.ref_rule_order
                   and start_date = frmheader.start_date;
             end;*/
            /*
            begin
                Select count(1) into vdup_taxability_cnt
                from juris_tax_applicabilities jta
                LEFT JOIN tax_applicability_taxes tat ON (jta.nkid = tat.juris_tax_applicability_nkid)
                where jta.jurisdiction_id = frmheader.jurisdiction_id
                and jta.commodity_id = frmheader.commodity_id
                and nvl(jta.ref_rule_order,-1) = nvl(frmheader.ref_rule_order,-1)
                and jta.is_local = decode(frmheader.is_local,0,'N',1,'Y')
                and nvl(jta.default_taxability,'N') = decode(frmheader.default_taxability,0,'N',1,'D')
                and (
                (
                    jta.start_date <= nvl(frmheader.end_date,'31-dec-2036')
                    AND nvl(jta.end_date,'31-dec-2036')   >= frmheader.start_date
                )
                -- block any between specified date
                or
                (jta.start_date between frmheader.start_date and nvl(frmheader.end_date,'31-dec-2036'))
                )
                and jta.id != nvl(frmheader.id,-1);

DBMS_OUTPUT.Put_Line( 'Select count(1) into vdup_taxability_cnt
                from juris_tax_applicabilities jta
                LEFT JOIN tax_applicability_taxes tat ON (jta.nkid = tat.juris_tax_applicability_nkid)
                where jta.jurisdiction_id = '||frmheader.jurisdiction_id
                ||' and jta.commodity_id = '||frmheader.commodity_id
                ||' and nvl(jta.ref_rule_order,-1) = nvl('||frmheader.ref_rule_order||',-1)
                and jta.is_local = decode('||frmheader.is_local||',0,''N'',1,''Y'')
                and nvl(jta.default_taxability,''N'') = decode('||frmheader.default_taxability||',0,''N'',1,''D'')
                and (
                (
                    jta.start_date <= nvl('||frmheader.end_date||',''31-dec-2036'')
                    AND nvl(jta.end_date,''31-dec-2036'')   >= '||frmheader.start_date||'
                )
                -- block any between specified date
                or
                (jta.start_date between '||frmheader.start_date||' and nvl('||frmheader.end_date||',''31-dec-2036''))
                )
                and jta.id != nvl('||frmheader.id||',-1)');


-- For now UI does not have any validation for date pairs in the grid.
DBMS_OUTPUT.Put_Line( 'K-Date'||frmheader.start_date||' Recs:'||vdup_taxability_cnt );

                if vdup_taxability_cnt>0 then
                  raise errnums.duplicate_key;
                end if;


                -- We know copy has an issue copying taxability with same dates
                -- jurisdiction_id
                -- commodity_id
-- working on
DBMS_OUTPUT.Put_Line( 'Do we have existing ones-->');
                Select count(tat.ref_rule_order) into vdup_taxability_cnt
                -- count(1) into vdup_taxability_cnt
                from juris_tax_applicabilities jta
                LEFT JOIN tax_applicability_taxes tat ON (jta.nkid = tat.juris_tax_applicability_nkid)
                where jta.jurisdiction_id = frmheader.jurisdiction_id
                and jta.commodity_id = frmheader.commodity_id
                and nvl(tat.ref_rule_order,-1) = nvl(frmheader.ref_rule_order,-1)
                and jta.is_local = decode(frmheader.is_local,0,'N',1,'Y')
                and nvl(jta.default_taxability,'N') = decode(frmheader.default_taxability,0,'N',1,'D')
                and jta.start_date = frmheader.start_date
                and nvl(jta.end_date,'31-DEC-2036') = nvl(frmheader.end_date,'31-DEC-2036')
                and jta.applicability_type_id = frmheader.applicability_type_id
                and jta.id != nvl(frmheader.id,-1);

DBMS_OUTPUT.Put_Line( '
Select count(tat.ref_rule_order) into vdup_taxability_cnt
                from juris_tax_applicabilities jta
                LEFT JOIN tax_applicability_taxes tat ON (jta.nkid = tat.juris_tax_applicability_nkid)
                where jta.jurisdiction_id = '||frmheader.jurisdiction_id||'
                and jta.commodity_id = '||frmheader.commodity_id||'
                and nvl(tat.ref_rule_order,-1) = nvl('||frmheader.ref_rule_order||',-1)
                and jta.is_local = decode('||frmheader.is_local||',0,''N'',1,''Y'')
                and nvl(jta.default_taxability,''N'') = decode('||frmheader.default_taxability||',0,''N'',1,''D'')
                and jta.start_date = '||frmheader.start_date||'
                and nvl(jta.end_date,''31-DEC-2036'') = nvl('||frmheader.end_date||',''31-DEC-2036'')
                and jta.id != nvl('||frmheader.id||',-1);');

                DBMS_OUTPUT.Put_Line( 'Exists: '||vdup_taxability_cnt);

                if vdup_taxability_cnt>0 then
                  raise errnums.duplicate_key;
                end if;
            end;

            */

	-- CRAP-4092 start
	-- check for start date and end date of applicable taxes before proceed further.
				for i in 1..rec_appl_taxes.count
                loop
					l_start_date := nvl(rec_appl_taxes(i).start_date, frmheader.start_date);
					l_end_date := nvl(nvl(rec_appl_taxes(i).end_date, frmheader.end_date),'31-Dec-9999');
					if l_start_date > l_end_date then
						raise errnums.cannot_update_record;
					end if;
				end loop;

	-- check for start date and end date of applicable conditions before proceed further.
				for i in 1..rec_appl_cond.count
                loop
					l_start_date := nvl(rec_appl_cond(i).start_date, frmheader.start_date);
					l_end_date := nvl(nvl(rec_appl_cond(i).end_date, frmheader.end_date),'31-Dec-9999');
					if l_start_date > l_end_date then
						raise errnums.cannot_update_record;
					end if;
				end loop;

	-- check for start date and end date of attributes before proceed further.
				for i in 1..rec_appl_attr.count
                loop
					l_start_date := nvl(rec_appl_attr(i).start_date, frmheader.start_date);
					l_end_date := nvl(nvl(rec_appl_attr(i).end_date, frmheader.end_date),'31-Dec-9999');
					if l_start_date > l_end_date then
						raise errnums.cannot_update_record;
					end if;
				end loop;
	-- CRAP-4092 end

                        begin

                                --CRAPP-3866 start
                        if (frmheader.applicability_type_id = 2 or frmheader.applicability_type_id = 3) then
                               delete from tax_applicability_taxes where juris_tax_applicability_id in
                               (select id from juris_tax_applicabilities where nkid= frmheader.nkid ) and status !=2 ; -- Published records should not be deleted as per Jira-3866
                                delete from taxability_outputs where juris_tax_applicability_id in
                               (select id from juris_tax_applicabilities where nkid= frmheader.nkid ) and status !=2 ; -- Published records should not be deleted as per Jira-3866
                        else
                            null;
                        end if;

                            --CRAPP-3866 end

                for i in 1..rec_appl_taxes.count
                loop
                    if rec_appl_taxes(i).ref_rule_order is not null
                    then

                        l_jta_nkid := get_applicability_nkid(rec_appl_taxes(i).juris_tax_applicability_id, 1);
                        l_tat_nkid := get_applicability_nkid(rec_appl_taxes(i).id, 2);

                        l_start_date := nvl(rec_appl_taxes(i).start_date, frmheader.start_date);
                        l_end_date := nvl(nvl(rec_appl_taxes(i).end_date, frmheader.end_date),'31-Dec-9999');

                        dbms_output.put_line('l_start_date value is '||l_start_date);
                        dbms_output.put_line('l_end_date value is '||l_end_date);

                        if l_start_date > l_end_date
                        then
                            raise errnums.cannot_update_record;
                        end if;

                        dbms_output.put_line('rec_appl_taxes(i).end_date value is '||rec_appl_taxes(i).end_date);
                        dbms_output.put_line('rec_appl_taxes(i).start_date value is '||rec_appl_taxes(i).start_date);
                        dbms_output.put_line('frmheader.end_date value is '||frmheader.end_date);
                        dbms_output.put_line('frmheader.start_date value is '||frmheader.start_date);

                        select nvl(sum(cnt), 0) into vdup_taxability_cnt
                            from (
                            select 1 cnt from juris_tax_applicabilities jta
                             join jurisdictions j on jta.jurisdiction_nkid = j.nkid
                            where j.id = frmheader.jurisdiction_id
                              and jta.nkid != l_jta_nkid
                              and jta.ref_rule_order = rec_appl_taxes(i).ref_rule_order
                              and jta.start_date between l_start_date and l_end_date
                            union
                            select 1 cnt from juris_tax_applicabilities jta
                             join tax_applicability_taxes tat on jta.nkid = tat.juris_tax_applicability_nkid
                             join jurisdictions j on jta.jurisdiction_nkid = j.nkid
                            where j.id = frmheader.jurisdiction_id
                              and tat.ref_rule_order = rec_appl_taxes(i).ref_rule_order
                              and tat.nkid != l_tat_nkid
                              and tat.start_date between l_start_date and l_end_date
                            );

                        dbms_output.put_line('
                        select nvl(sum(cnt), 0)
                            from (
                            select 1 cnt from juris_tax_applicabilities jta
                             join jurisdictions j on jta.jurisdiction_nkid = j.nkid
                             left join commodities c on c.nkid = jta.commodity_nkid
                            where j.id = '||frmheader.jurisdiction_id||'
                              and c.id = '||frmheader.commodity_id||'
                              and jta.nkid != '||l_jta_nkid||'
                              and jta.ref_rule_order = '||rec_appl_taxes(i).ref_rule_order||'
                              and jta.start_date between '''||l_start_date||''' and '''||l_end_date||'''
                            union
                            select 1 cnt from juris_tax_applicabilities jta
                             join tax_applicability_taxes tat on jta.nkid = tat.juris_tax_applicability_nkid
                             join jurisdictions j on jta.jurisdiction_nkid = j.nkid
                             left join commodities c on c.nkid = jta.commodity_nkid
                            where j.id = '||frmheader.jurisdiction_id||'
                              and c.id = '||frmheader.commodity_id||'
                              and tat.ref_rule_order = '||rec_appl_taxes(i).ref_rule_order||'
                              and tat.nkid != '||l_tat_nkid||'
                              and tat.start_date between '''||l_start_date||''' and '''||l_end_date||'''
                            );
                        ');

                        dbms_output.put_line('vdup_taxability_cnt value is '||vdup_taxability_cnt);

                            if vdup_taxability_cnt > 0
                            then
                                raise errnums.duplicate_key;
                            end if;
                    end if;
                end loop;
            end;
	--CRAPP-4050
	-- Check the status of applicable taxes.If the tax is locked then restrict the user to un-select it from taxability Grid

		BEGIN
			FOR i IN 1..rec_appl_taxes.COUNT
			LOOP
				IF rec_appl_taxes(i).deleted = 1 THEN
					SELECT COUNT(status) INTO ln_count_status
					FROM tax_applicability_taxes
					WHERE id = rec_appl_taxes(i).id
					AND status IN (1);

					IF ln_count_status > 0 THEN
						ln_delete_tax_flag := 1;
					END IF;
				END IF;
			END LOOP;
		END;
	-- Check the status of taxability record.If the record is published then restrict the user to un-select
	--the tax from taxability Grid
		BEGIN
			FOR j IN 1..rec_appl_taxes.COUNT
			LOOP
				IF rec_appl_taxes(j).deleted = 1 THEN

						SELECT id,status,rid INTO ln_id,ln_status,ln_rid
						FROM juris_tax_applicabilities
						WHERE nkid = frmheader.nkid
						AND next_rid IS NULL;

					IF ln_status IN (2) THEN
						ln_delete_taxability_flag := 1;
					END IF;
				END IF;
			END LOOP;
		END;
		IF ln_delete_tax_flag = 0 AND ln_delete_taxability_flag = 0 THEN

             update_header(frmheader, l_appl_pk, l_applic_nkid, l_applic_rid );
DBMS_OUTPUT.Put_Line( l_applic_nkid );
             nkid_o := l_applic_nkid;
             rid_o  := l_applic_rid;
		ELSE
			SELECT id,rid INTO ln_id,ln_rid
			FROM juris_tax_applicabilities
			WHERE nkid = frmheader.nkid
			AND next_rid IS NULL;

			l_appl_pk := ln_id;
			nkid_o := frmheader.nkid;
			rid_o  := ln_rid;
		END IF;


             -- Applicable Taxes
             Dbms_output.put_line('Applicable Taxes Start -->');
             l_cnt := rec_appl_taxes.COUNT;

             -- Check to see if all we are doing is end-dating the header -- crapp-2603
             IF l_cnt = 0 AND l_hdr_end_date IS NOT NULL THEN
                 dbms_output.put_line(' - End-dating Applicable Taxes with NULL end dates for Pending changes to: '||l_hdr_end_date);
                 UPDATE tax_applicability_taxes
                     SET end_date = l_hdr_end_date
                        ,entered_by = frmheader.entered_by   -- crapp-2799
                 WHERE juris_tax_applicability_nkid = l_applic_nkid
                     AND status = 0;        -- pending changes
                     /*AND (end_date IS NULL
                          OR ( end_date IS NOT NULL
                               AND start_date < l_hdr_end_date  -- make sure we are not overlapping dates
                             )
                         );*/

                 dbms_output.put_line(' - End-dating Applicable Taxes with NULL end dates on Published records to: '||l_hdr_end_date);
                 UPDATE tax_applicability_taxes
                     SET end_date = l_hdr_end_date
                        ,entered_by = frmheader.entered_by   -- crapp-2799
                 WHERE juris_tax_applicability_nkid = l_applic_nkid
                     AND status = 2        -- published
                     AND end_date IS NULL
                     AND next_rid IS NULL
                     AND start_date < l_hdr_end_date;  -- make sure we are not overlapping dates

             ELSE
                 for i in 1..rec_appl_taxes.count
                 loop
                        -- For exempt and notax records, rule_ordre should be updated at header level
                        -- and there won't be any taxes associated with it.
                        -- Extract rule_order into variable and updated the header record later.
                        -- CRAPP-2828
                        if frmheader.applicability_type_id != 1 then
                            lruleorder := rec_appl_taxes(i).ref_rule_order;
                            -- This is to make sure when you set the rule order to blank that should update correctly.
                            --if lruleorder is not null
                            --then
                                update juris_tax_applicabilities set ref_rule_order = lruleorder where nkid = nkid_o and next_rid is null;
                            --end if;
                        end if;
                     IF rec_appl_taxes(i).deleted = 1 THEN
						IF ln_delete_tax_flag = 0 AND ln_delete_taxability_flag = 0 THEN
                        remove_taxes ( rec_appl_taxes(i).id, l_entered_by, nkid_o, frmheader.applicability_type_id );
						END IF;
                     ELSE

/*                        if (rec_appl_taxes(i).start_date < frmheader.start_date)
                          or (nvl(rec_appl_taxes(i).end_date, '31-dec-9999') > nvl(frmheader.end_date, '31-dec-9999'))
                          or (nvl(rec_appl_taxes(i).end_date, '31-dec-9999') < rec_appl_taxes(i).start_date)
                         then

01-Sep-2016 <01-Sep-2016
31-Dec-9999 >02-Sep-2016
31-Dec-9999 <01-Sep-2016


*/

                         -- CRAPP-2897
                         if (rec_appl_taxes(i).start_date < frmheader.start_date)
                          or (rec_appl_taxes(i).end_date > nvl(frmheader.end_date, '31-dec-9999'))
                          or (nvl(rec_appl_taxes(i).end_date, '31-dec-9999') < rec_appl_taxes(i).start_date)
                         then
                             rollback;
                             raise errnums.cannot_update_child;
                         else
                             rec_ins_apptax := rec_appl_taxes(i);
                             update_taxes ( rec_ins_apptax, l_appltax_pk, l_entered_by, l_appl_pk , frmheader.applicability_type_id,
                                            frmheader.default_taxability, frmheader.is_local
                                            );
                         end if;
                     end if;
                 end loop;
             END IF; -- header end-date only change
             Dbms_output.put_line('Applicable Taxes End   -->');

             -- Applicable Conditions
             Dbms_output.put_line('Applicable Conditions Start -->');
             l_cnt := rec_appl_cond.COUNT;

             -- Check to see if all we are doing is end-dating the hearder -- crapp-2603
             IF l_cnt = 0 AND l_hdr_end_date IS NOT NULL THEN
                dbms_output.put_line(' - End-dating Applicable Conditions with NULL end dates for Pending changes to: '||l_hdr_end_date);
                UPDATE tran_tax_qualifiers
                    SET end_date = l_hdr_end_date
                       ,entered_by = frmheader.entered_by   -- crapp-2799
                WHERE juris_tax_applicability_nkid = l_applic_nkid
                    AND status = 0;        -- pending changes
                    /*AND (end_date IS NULL
                         OR ( end_date IS NOT NULL
                              AND start_date < l_hdr_end_date  -- make sure we are not overlapping dates
                            )
                        );*/

                dbms_output.put_line(' - End-dating Applicable Conditions with NULL end dates on Published records to: '||l_hdr_end_date);
                UPDATE tran_tax_qualifiers
                    SET end_date = l_hdr_end_date
                       ,entered_by = frmheader.entered_by   -- crapp-2799
                WHERE juris_tax_applicability_nkid = l_applic_nkid
                    AND status = 2        -- published
                    AND end_date IS NULL
                    AND next_rid IS NULL
                    AND start_date < l_hdr_end_date;  -- make sure we are not overlapping dates
             ELSE
                Dbms_output.put_line('Applicable Conditions: Came into else block');
                 for i in 1..rec_appl_cond.count
                 loop
                        Dbms_output.put_line('Applicable Conditions: Inside the for loop');
                     if rec_appl_cond(i).deleted = 1 then
                         remove_condition ( rec_appl_cond(i).id, l_entered_by );
                     else
                        Dbms_output.put_line('Applicable Conditions: About to insert or update');
                         if (rec_appl_cond(i).start_date < frmheader.start_date
                          or nvl(rec_appl_cond(i).end_date, '31-dec-9999') > nvl(frmheader.end_date, '31-dec-9999')
                          or nvl(rec_appl_cond(i).end_date, '31-Dec-9999') < rec_appl_cond(i).start_date
                          )
                         then
                             rollback;
                             raise errnums.cannot_update_child;
                         else
                            Dbms_output.put_line('Applicable Conditions: Calling insert/update ');
                             rec_ins_appcond := rec_appl_cond(i);
                             update_condition ( rec_ins_appcond, l_applcond_pk, l_entered_by, l_appl_pk );
                         end if;
                     end if;
                 end loop;
             END IF; -- header end-date only change
             Dbms_output.put_line('Applicable Conditions End   -->');


             -- Applicable Attributes
             Dbms_output.put_line('Applicable Attributes Start -->');
             l_cnt := rec_appl_attr.COUNT;

             -- Check to see if all we are doing is end-dating the hearder -- crapp-2603
             IF l_cnt = 0 AND l_hdr_end_date IS NOT NULL THEN
                dbms_output.put_line(' - End-dating Applicable Attributes with NULL end dates for Pending changes to: '||l_hdr_end_date);
                UPDATE juris_tax_app_attributes
                    SET end_date = l_hdr_end_date
                       ,entered_by = frmheader.entered_by   -- crapp-2799
                WHERE juris_tax_applicability_nkid = l_applic_nkid
                    AND status = 0;        -- pending changes
                    /*AND (end_date IS NULL
                         OR ( end_date IS NOT NULL
                              AND start_date < l_hdr_end_date  -- make sure we are not overlapping dates
                            )
                        );*/

                dbms_output.put_line(' - End-dating Applicable Attributes with NULL end dates on Published records to: '||l_hdr_end_date);
                UPDATE juris_tax_app_attributes
                    SET end_date = l_hdr_end_date
                       ,entered_by = frmheader.entered_by   -- crapp-2799
                WHERE juris_tax_applicability_nkid = l_applic_nkid
                    AND status = 2        -- published
                    AND end_date IS NULL
                    AND next_rid IS NULL
                    AND start_date < l_hdr_end_date;  -- make sure we are not overlapping dates
             ELSE
                 for i in 1..rec_appl_attr.count
                 loop
                     if rec_appl_attr(i).deleted = 1 then
                         remove_attribute ( rec_appl_attr(i).id, l_entered_by );
                     else
                         if (rec_appl_attr(i).start_date < frmheader.start_date
                          or nvl(rec_appl_attr(i).end_date, '31-dec-9999') > nvl(frmheader.end_date, '31-dec-9999')
                          or nvl(rec_appl_attr(i).end_date, '31-Dec-9999') < rec_appl_attr(i).start_date
                          )
                         then
                             rollback;
                             raise errnums.cannot_update_child;
                         else
                             rec_ins_applattr := rec_appl_attr(i);
                             update_attributes ( rec_ins_applattr, l_applattr_pk, l_entered_by, l_appl_pk );
                         end if;
                     end if;
                 end loop;
             END IF; -- header end-date only change
             Dbms_output.put_line('Applicable Attributes End   -->');


             -- Handle tags
             Dbms_output.put_line('Tags Start -->');
DBMS_OUTPUT.Put_Line( l_applic_nkid );

             tags_registry.tags_entry(tag_list, l_applic_nkid);
             Dbms_output.put_line('Tags End   -->');
          end if;
        end if;
        Dbms_output.put_line('FORM_UPDATE_FULL End   -->');

        begin
            select id into rid_o from juris_tax_app_revisions where nkid = nkid_o and next_rid is null;
        exception
        when no_data_found
        then
            rid_o := null;
        end;

    -- EXCEPTION
        /*
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                    errnums.en_cannot_update_record,
                    'Taxability end_date is beyond the start date. Please correct the end_date.');
        WHEN errnums.cannot_update_child
        THEN
            ROLLBACK;
            errlogger.report_and_stop (
                errnums.en_cannot_update_child,
                'One of the child collection date range is above or beyond taxability date range. Please correct the dates');
        WHEN NO_DATA_FOUND
        THEN
            ROLLBACK;
            errlogger.report_and_go (
                        SQLCODE,
                        'Record could not be updated because the ID was not found.');
        WHEN OTHERS
        THEN
            dbms_output.put_line('Entered into exception block');
            ROLLBACK;
            RAISE;
        */
    END form_update_full;



    procedure update_legal_statement ( value_i varchar2, start_date_i in date, end_date_i in date,
                                       jta_id_i number, entered_by_i number, applattr_pk out number, jtaa_id in number default null )
    is
        vcnt           NUMBER;
        l_jta_nkid     NUMBER;
        l_applattr_rid NUMBER;

    begin

        dbms_output.put_line('Update_Legal_Statement Start -->');
        dbms_output.put_line (' the passed values are StartDate: '||start_date_i||'|| Value: '||value_i||'|| JTA_ID: '||jta_id_i||'|| EndDate: '||end_date_i);

        if start_date_i is not NULL then
            dbms_output.put_line('About to process legal statement ');
            select distinct nkid into l_jta_nkid from juris_tax_applicabilities where id = jta_id_i;
            dbms_output.put_line (' Updating end date information for the previously published record of nkid value as '||l_jta_nkid);

            if jtaa_id is not NULL then
                update juris_tax_app_attributes
                   set start_date = start_date_i,
                       value = nvl(value_i, ' '),
                       end_date = end_date_i
                where id = jtaa_id
                  and status != 2
                  returning id into applattr_pk;
            else
                update juris_tax_app_attributes
                   set start_date = start_date_i,
                       value = nvl(value_i, ' '),
                       end_date = end_date_i
                where juris_tax_applicability_id = jta_id_i
                  and attribute_id = 24
                  and status = 0
                  returning id into applattr_pk;
            end if;

            dbms_output.put_line ( ' the value of applattr_pk is '||applattr_pk ) ;

            select count(1) into vcnt from juris_tax_app_attributes
            where attribute_id = 24 and juris_tax_applicability_nkid = l_jta_nkid and status = 2 and end_date is null;

            if vcnt > 0 then

               alter_trigger('UPD_TAX_APP_ATTRIBUTES', 'disable', 'content_repo');
               update juris_tax_app_attributes
                  set end_date = GREATEST(start_date_i - 1, start_date)
               where juris_tax_applicability_nkid = l_jta_nkid
                 and attribute_id = 24
                 and status = 2
                 and end_date is null;
               alter_trigger('UPD_TAX_APP_ATTRIBUTES', 'enable', 'content_repo');
            end if;

            select count(1) into vcnt from juris_tax_app_attributes where juris_tax_applicability_id = jta_id_i and attribute_id = 24 and status = 0;

            if vcnt = 0 then
                insert into juris_tax_app_attributes
                  ( juris_tax_applicability_id,
                    attribute_id,
                    value,
                    start_date,
                    end_date,
                    entered_by
                   )
                   values
                   ( jta_id_i,
                     24,
                     nvl(value_i, ' '),
                     start_date_i,
                     end_date_i,
                     entered_by_i
                   )
                   returning id, rid into applattr_pk, l_applattr_rid;
             end if;

            if l_applattr_rid is not null then

               alter_trigger('UPD_TAX_APP_ATTRIBUTES', 'disable', 'content_repo');
               update juris_tax_app_attributes
                  set next_rid = l_applattr_rid
               where juris_tax_applicability_nkid = l_jta_nkid
                 and attribute_id = 24
                 and status = 2
                 and next_rid is null;
               alter_trigger('UPD_TAX_APP_ATTRIBUTES', 'enable', 'content_repo');
            end if;
        end if;
        dbms_output.put_line('Update_Legal_Statement End   -->');
    END update_legal_statement;


    /** Taxability Update Form Header
     *
     */
    PROCEDURE update_header (header_rec   IN     appl_header,
                             jtaid        IN OUT NUMBER,
                             nkid_o          OUT NUMBER,
                             rid_o           OUT NUMBER
                             )
    IS

        rec_attr    xmlform_applattr;
        l_attr_pk   number;
        vcnt        number;
        vls_id      number;
        vls_value   varchar2(5000);
        vls_start_date date;
        vattribute_id number;
        vls_end_date  date;
        v_is_local    varchar2(1):= 'N';
        l_output_pk   number;
        -- l_is_local varchar2(1 char);
        vappl_type_id number;
        vcharge_name  varchar2(2) := null;
        vrelated_charge varchar2(2) := null;
        vrecoverable_percent number := null;
        vrecoverable_amount  number := null;
        vinv_cnt    number;  -- CRAPP-2863

    BEGIN
        dbms_output.put_line('Update_Header Start -->');
        dbms_output.put_line(' about to insert/update the record '||header_rec.id);
        dbms_output.put_line(' about to insert/update the record (entered_by) '||header_rec.entered_by);

        if header_rec.input_recoverability is not null
        then
            vrecoverable_amount := null;
            vrecoverable_percent := header_rec.input_recoverability;
        elsif  header_rec.recoverable_amount is not null
        then
            vrecoverable_percent := null;
            vrecoverable_amount := header_rec.recoverable_amount;
        end if;

        if header_rec.is_local = 1 then
            v_is_local := 'Y';
        end if;

        IF header_rec.id IS NOT NULL THEN
            dbms_output.put_line(' Came inside to the update block');
            UPDATE juris_tax_applicabilities
               SET calculation_method_id    = header_rec.calculation_method,
                   basis_percent            = header_rec.basis_percent,
                   recoverable_percent      = vrecoverable_percent,
                   recoverable_amount       = vrecoverable_amount,
                   start_date               = header_rec.start_date,
                   end_date                 = header_rec.end_date,
                   entered_by               = header_rec.entered_by,
                   all_taxes_apply          = nvl(header_rec.all_taxes_apply,0),
                   charge_type_id           = header_rec.charge_type_id,
                   Unit_of_Measure          = header_rec.unit_of_measure,
                   commodity_id             = header_rec.commodity_id,
                   default_Taxability       = case when header_rec.default_Taxability = 1 then 'D' else null end ,
            -- CRAPP-2674
                   product_Tree_Id          = case when header_rec.all_taxes_apply = 1 then null else nvl(header_rec.product_Tree_Id, 13) end,
                   applicability_type_id    = header_rec.applicability_type_id,
                   is_local                 = v_is_local,
                   ref_rule_order           = nvl(header_rec.ref_rule_order, ref_rule_order)
            WHERE id = header_rec.id
            returning nkid into nkid_o;

            -- crapp-2603 --
            IF header_rec.end_date IS NOT NULL THEN
                dbms_output.put_line(' Updated header end_date to '||header_rec.end_date);
                vls_end_date := header_rec.end_date;
            ELSE
                vls_end_date := NULL;
            END IF;

        else
            dbms_output.put_line(' Came inside to the Insert block');
            insert into juris_tax_applicabilities
            (
                applicability_type_id, calculation_method_id, recoverable_percent, basis_percent, Unit_of_Measure,
                start_date, end_date, all_taxes_apply, status, commodity_id,
                jurisdiction_id, default_Taxability, product_Tree_Id, entered_by, is_local, recoverable_amount,
                charge_type_id, ref_rule_order
            )
            values
            (
                header_rec.applicability_type_id, header_rec.calculation_method, vrecoverable_percent, header_rec.basis_percent,
                header_rec.Unit_of_Measure, header_rec.start_date, header_rec.end_date, nvl(header_rec.all_taxes_apply,0),0, header_rec.commodity_id,
                header_rec.jurisdiction_id, --header_rec.jurisdiction_Nkid, --null, --header_rec.commodity_id
                case when header_rec.default_Taxability = 1 then 'D' else null end,
                case when header_rec.all_taxes_apply = 1 then null else nvl(header_rec.product_Tree_Id, 13) end,
                --nvl(header_rec.product_Tree_Id, 13),
                header_rec.entered_by, v_is_local, vrecoverable_amount , header_rec.charge_type_id, header_rec.ref_rule_order
            ) returning
            nkid into nkid_o;
            dbms_output.put_line('the values are jtaid '||jtaid||' nkid '||nkid_o||' rid '||rid_o);

        end if;
        select id, nkid, rid into jtaid, nkid_o, rid_o from juris_tax_applicabilities where next_rid is null and nkid = nkid_o;
        select id into vattribute_id from additional_attributes where name = 'Legal Statement';

        update_legal_statement ( header_rec.legal_statement, header_rec.ls_start_date, vls_end_date, jtaid, header_rec.entered_by, l_attr_pk );

        select id into vappl_type_id from applicability_types where name = 'Taxable';
        if header_rec.applicability_type_id != vappl_type_id then
            -- CRAPP-2863
            select count(1) into vinv_cnt from taxability_outputs where juris_tax_applicability_nkid = nkid_o;
            if vinv_cnt = 0 then
                    l_output_pk := fcreatetaxabilityoutput ( jtaid, null, null, null, header_rec.start_date, header_rec.end_date,
                                        header_rec.applicability_type_id, header_rec.entered_by );

            end if;
        end if;
        -- crapp-2603 --
        IF header_rec.end_date IS NOT NULL AND l_output_pk IS NULL THEN -- only update when we haven't already generated a Taxability OutputID
            dbms_output.put_line(' setting Taxability_Output End_Date to Header End_Date - Pending');
            UPDATE taxability_outputs
               SET end_date = header_rec.end_date
                  ,entered_by = header_rec.entered_by   -- crapp-2799
            WHERE juris_tax_applicability_nkid = nkid_o
                  AND status = 0;    -- pending
                  /*AND (end_date IS NULL
                       OR ( end_date IS NOT NULL
                            AND start_date < header_rec.end_date  -- make sure we are not overlapping dates
                          )
                      );*/

            dbms_output.put_line(' setting NULL Taxability_Output End_Date to Header End_Date - Published');
            UPDATE taxability_outputs
               SET end_date = header_rec.end_date
                  ,entered_by = header_rec.entered_by   -- crapp-2799
            WHERE juris_tax_applicability_nkid = nkid_o
                  AND status = 2    -- published
                  AND end_date IS NULL
                  AND next_rid IS NULL
                  AND start_date < header_rec.end_date;  -- make sure we are not overlapping dates
        END IF;
        select id into rid_o from juris_tax_app_revisions where nkid = nkid_o and next_rid is null;
        dbms_output.put_line('Update_Header End -->');
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
                    'Record could not be updated because the ID was not found.');
        WHEN OTHERS
        THEN
            dbms_output.put_line('Entered into exception block');
            ROLLBACK;
            RAISE;
    END update_header;

    /** Update Contributes
     *
     */

    /** Update Attributes **/
    PROCEDURE update_attributes (rec_i IN xmlform_applattr, applattr_pk out number, entered_by_i number, jta_id number default null
                                 )
    IS
        l_id   NUMBER;
        l_appl_pk number;

    BEGIN

        if rec_i.juris_tax_applicability_id is null
        then
            l_appl_pk := jta_id;
        else
            l_appl_pk := rec_i.juris_tax_applicability_id;
        end if;

     if rec_i.attribute_id is not null
     then
        if rec_i.attribute_id = 24
        then
            dbms_output.put_line('rec_i.value '||rec_i.value);
            update_legal_statement ( rec_i.value, rec_i.start_date, rec_i.end_date, jta_id, entered_by_i, applattr_pk, rec_i.id );
        else
            IF (rec_i.id IS NOT NULL)
            THEN
                l_id := rec_i.id;
                DBMS_OUTPUT.Put_Line( 'Upd -->'||rec_i.id );
                if rec_i.attribute_id is not null then

                    UPDATE juris_tax_app_attributes attr
                       SET attribute_id = rec_i.attribute_id,
                           attr.VALUE = rec_i.value,
                           attr.start_date = rec_i.start_date,
                           attr.end_date = rec_i.end_date,
                           attr.entered_by = entered_by_i
                     WHERE attr.id = rec_i.id;
                end if; -- 6/30 go around the xml tag issue
            ELSE

                DBMS_OUTPUT.Put_Line( 'New Attribute to add-->' );
                DBMS_OUTPUT.Put_Line( 'INS: jta '||l_appl_pk);
                DBMS_OUTPUT.Put_Line( 'Attribute: '||rec_i.attribute_id);
                INSERT INTO juris_tax_app_attributes (juris_tax_applicability_id,
                                                      attribute_id,
                                                      VALUE,
                                                      start_date,
                                                      end_date,
                                                      entered_by)
                VALUES (l_appl_pk,
                        rec_i.attribute_id,
                        rec_i.value,
                        rec_i.start_date,
                        rec_i.end_date,
                        entered_by_i)
                RETURNING id
                   INTO l_id;

            END IF;

        end if;

        applattr_pk := l_id;

      else
            raise errnums.missing_req_val;
      end if;

    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (errnums.en_missing_req_val,
                              'Key elements missing for record at "Applicability Taxes" level');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || l_id);
    END update_attributes;

    procedure update_invoice(tot_id number, tat_id number, jta_id number, invoice_statement varchar2, entered_by number, entered_date date)
    is
    begin
        null;
    end;


    /** Update Applicable Taxes **/
    PROCEDURE update_taxes (rec_i xmlform_appltaxes, appltax_pk out number , entered_by_i number,  jta_id number default null, applicability_type_i number,
                            default_taxability_i number, is_local_i number
                                 )
    IS
      l_id             NUMBER;
      nUpdateRec_Count NUMBER;
      av_array         apex_application_global.vc_arr2;
      v_string         varchar2(4000);
      l_appl_pk        number;
      l_appltax_pk     number := null;
      l_invoice_pk     number;
      l_short_text     varchar2(250);
      l_start_date     date;
      l_end_date       date;
      l_appltax_nkid   number; -- CRAPP-2682
      ltax_type_id     number; -- CRAPP-2415 -- When tax_type set to null in UI, XML receiving it as 0
      l_reference_code varchar2(20);
      l_rule_order number;

      n_cnt number;
      EDupRule exception;
    BEGIN
      -- av_array := apex_util.string_to_table(applic_id, ',');

        l_rule_order := rec_i.ref_rule_order;
        if applicability_type_i = 1 and ( rec_i.juris_tax_imposition_id is null or rec_i.start_date is null )
        then
            raise errnums.missing_req_val;
        else
                if rec_i.juris_tax_applicability_id is null
                then
                    l_appl_pk := jta_id;
                else
                    l_appl_pk := rec_i.juris_tax_applicability_id;
                end if;

            if rec_i.juris_tax_imposition_id is not null
            then
                if rec_i.taxtypeid = 0 or rec_i.taxtypeid is null then
                    ltax_type_id := null;
                else
                    ltax_type_id := rec_i.taxtypeid;
                end if;

            if default_taxability_i = 1
            then
                select reference_code into l_reference_code from juris_tax_impositions where id = rec_i.juris_tax_imposition_id;

                dbms_output.put_line('l_reference_code value is '||l_reference_code);

                    if is_local_i = 1
                    then
                        if l_reference_code = 'CU' and l_rule_order is null
                        then
                            l_rule_order :=  9971;

                        elsif l_reference_code = 'SU' and l_rule_order is null
                        then
                            l_rule_order :=  9981;

                        elsif l_reference_code = 'ST' and l_rule_order is null
                        then

                            l_rule_order :=  9991;
                        end if;
                    else
                        if l_reference_code = 'CU' and l_rule_order is null
                        then
                            l_rule_order :=  9970;

                        elsif l_reference_code = 'SU' and l_rule_order is null
                        then
                            l_rule_order :=  9980;

                        elsif l_reference_code = 'ST' and l_rule_order is null
                        then
                            l_rule_order :=  9990;
                        end if;
                    end if;
            end if;

               if rec_i.id is not null
               then
-->TODO: look for duplicates
-- alt. t2.start_date and end_date check (UI validation should be in place)
                 DBMS_OUTPUT.Put_Line( 'Update block' );
                       UPDATE tax_applicability_taxes t1
                       SET t1.end_date = rec_i.end_date,
                               t1.entered_by = entered_by_i,
                               t1.tax_type_id = ltax_type_id,
                               t1.ref_rule_order = l_rule_order
                        /*
                           Where not exists
                           (select 1 from tax_applicability_taxes t2
                            where t2.juris_tax_applicability_nkid = t1.juris_tax_applicability_nkid
                            and t2.ref_rule_order = l_rule_order
                            and t2.id <> t1.id
                            and t2.status = 0
                            )
                        */
                          where t1.id = rec_i.id
                           returning nkid into l_appltax_nkid;
                        /*
                       if SQL%NOTFOUND then
                          DBMS_OUTPUT.Put_Line( 'Rule exists' );
                          raise EDupRule;
                       end if;
                       */

               ELSE

                DBMS_OUTPUT.Put_Line( 'Insert block' );
                /*
                Select count(1) l_cnt into n_cnt
                from
                tax_applicability_taxes t1
                where t1.juris_tax_applicability_id = l_appl_pk
                and t1.ref_rule_order = l_rule_order
                and t1.status=0;

                if n_cnt > 0 then
                    raise EDupRule;
                end if;

                */
                    -- Changes for CRAPP-2791
                     INSERT INTO tax_applicability_taxes
                     (juris_tax_applicability_id,
                      juris_tax_imposition_id,
                      tax_type_id,
                      start_date,
                      status,
                      end_date,
                      entered_by,
                      ref_rule_order
                      )
                     values
                     (l_appl_pk,
                      rec_i.juris_tax_imposition_id,
                      ltax_type_id,
                      rec_i.start_date,
                      0,
                      rec_i.end_date,
                      entered_by_i,
                      l_rule_order
                      )
                      returning id into l_appltax_pk;
                  dbms_output.put_line('After insert tax_applicability_taxes the pk value is '||l_appltax_pk);
               END IF;
               DBMS_OUTPUT.Put_Line( '---- AT ==> rec_i.invoice_statement value is '||rec_i.invoice_statement );
            end if;
            -- CRAPP-2682
            if l_appltax_nkid is not null
            then
                select id into l_appltax_pk from tax_applicability_taxes where nkid = l_appltax_nkid and next_rid is null;
            end if;

                dbms_output.put_line('l_appltax_pk value is '||l_appltax_pk);
                l_invoice_pk := fcreatetaxabilityoutput
                                    ( l_appl_pk, l_appltax_pk, rec_i.invoice_statement, rec_i.juris_tax_imposition_id,
                                      rec_i.start_date, rec_i.end_date, applicability_type_i, entered_by_i
                                      );
        end if;

    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (errnums.en_missing_req_val,
                              'Key elements missing for record.');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN EDupRule
        THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20202,'Check rule order');
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': Rec id:'||rec_i.id);
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': rid:'  --|| rid_o
                );
    END update_taxes;

    /* Update Conditions */
    procedure update_condition(rec_i xmlform_applcond, applcond_pk out number , entered_by_i number,  jta_id number default null )
    is
     l_id number;
     l_appl_pk number;
     l_logical_qualifier varchar2(200);
    begin

        dbms_output.put_line('rec_i.juris_tax_applicability_id value is '||rec_i.juris_tax_applicability_id);
        dbms_output.put_line('rec_i.logical_qualifier value is '||rec_i.logical_qualifier);
        dbms_output.put_line('rec_i.taxability_element_id value is '||rec_i.taxability_element_id);
        dbms_output.put_line('rec_i.jurisdiction_id value is '||rec_i.jurisdiction_id);
        dbms_output.put_line('jta_id value is '||jta_id);

        if rec_i.juris_tax_applicability_id is null
        then
            l_appl_pk := jta_id;
        else
            l_appl_pk := rec_i.juris_tax_applicability_id;
        end if;

    dbms_output.put_line('l_appl_pk value is '||l_appl_pk);
      if l_appl_pk is not null
      then

        if rec_i.logical_qualifier is not null
        then
            select name into l_logical_qualifier from logical_qualifiers where id = rec_i.logical_qualifier;
        end if;

        if l_logical_qualifier is not null and COALESCE(rec_i.taxability_element_id, rec_i.jurisdiction_id, NULL) IS NOT NULL THEN -- crapp-2841 added rec_i.jurisdiction_id

            IF (rec_i.id IS NOT NULL) THEN
                l_id := rec_i.id;
                dbms_output.put_line('About to update the record ');
                UPDATE tran_tax_qualifiers ttq
                   SET ttq.taxability_element_id = rec_i.taxability_element_id,
                       ttq.logical_qualifier = l_logical_qualifier,
                       ttq.value = rec_i.value,
                       ttq.start_date = rec_i.start_date,
                       ttq.end_date = rec_i.end_date,
                       ttq.entered_by = entered_by_i,
                       ttq.reference_group_id = rec_i.reference_group_id,
                       ttq.jurisdiction_id = rec_i.jurisdiction_id
                 WHERE ttq.id = rec_i.id
                  returning id into applcond_pk;
                 dbms_output.put_line('After update, the value is '||applcond_pk);
            ELSE
                dbms_output.put_line('About to insert ');
                INSERT INTO tran_tax_qualifiers(juris_tax_applicability_id,
                            taxability_element_id,
                            logical_qualifier,
                            value,
                            start_date,
                            end_date,
                            entered_by,
                            reference_group_id,
                            jurisdiction_id)
                VALUES (l_appl_pk,
                        rec_i.taxability_element_id,
                        l_logical_qualifier,
                        rec_i.value,
                        rec_i.start_date,
                        rec_i.end_date,
                        entered_by_i,
                        rec_i.reference_group_id,
                        rec_i.jurisdiction_id
                        )
                RETURNING id
                   INTO l_id;
                   dbms_output.put_line('After Insert the value is '||l_id);
            END IF;

            applcond_pk := l_id;

        else
            raise errnums.missing_req_val;
        end if;
      else
            raise errnums.missing_req_val;
      end if;

    EXCEPTION
        WHEN errnums.missing_req_val
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (errnums.en_missing_req_val,
                              'Key elements missing for record at "Applicabile Conditions" level');
        WHEN errnums.cannot_update_record
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (
                errnums.en_cannot_update_record,
                'Record could not be updated because it does not match the pending record :)');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || l_id);
    end update_condition;

    /** Remove Attribute
     *
     */
    PROCEDURE remove_attribute (jta_att_id IN NUMBER, deleted_by_i IN NUMBER)
    IS
        l_rid    NUMBER;
        l_nkid   NUMBER;
    BEGIN
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('JURIS_TAX_APP_ATTRIBUTES', jta_att_id);

        DELETE FROM juris_tax_app_attributes attr
         WHERE attr.id = jta_att_id
        RETURNING rid, nkid
          INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, deleted_by_i
               FROM tmp_delete
              WHERE primary_key = jta_att_id);

        UPDATE juris_tax_app_attributes ata
           SET next_rid = NULL
         WHERE ata.next_rid = l_rid AND ata.nkid = l_nkid;

    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (SQLCODE, SQLERRM || ': ' || jta_att_id);
    END remove_attribute;

    /** Remove Applicable Taxes
     *
     */
    PROCEDURE remove_taxes (appltax_id IN VARCHAR2, deleted_by_i IN NUMBER, jta_nkid number, Applicability_Type_ID number)
    IS
        l_rid    NUMBER;
        l_nkid   NUMBER;
        av_array  apex_application_global.vc_arr2;
        v_string varchar2(4000);
        vcnt     number;
    BEGIN

          INSERT INTO tmp_delete (table_name, primary_key)
          VALUES ('TAX_APPLICABILITY_TAXES', appltax_id );

          DELETE FROM taxability_outputs
           WHERE tax_applicability_tax_id = appltax_id;

          DELETE FROM tax_applicability_taxes applic
          WHERE applic.id = appltax_id
          RETURNING rid, nkid
          INTO l_rid, l_nkid;

         INSERT INTO delete_logs (table_name, primary_key, deleted_by)
         (SELECT table_name, primary_key, deleted_by_i
            FROM tmp_delete
           WHERE primary_key = appltax_id
          );

         UPDATE tax_applicability_taxes ata
            SET ata.next_rid = NULL
          WHERE ata.next_rid = l_rid AND ata.nkid = l_nkid;

        if Applicability_Type_ID = 1
        then
          select count(1) into vcnt from tax_applicability_taxes where nkid = jta_nkid;

          if vcnt = 0 then
                raise errnums.missing_req_val;
          end if;

        end if;


    EXCEPTION
    WHEN errnums.missing_req_val
        THEN
            errlogger.
             report_and_stop (errnums.en_missing_req_val,
                              'Taxable type should have atleast one Applicable Tax attached to it.');
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE, SQLERRM || ': ' || appltax_id);
    END remove_taxes;


    /* Remove condition (qualifiers) */
    PROCEDURE remove_condition (condition_id IN NUMBER, deleted_by_i IN NUMBER)
    IS
        l_rid    NUMBER;
        l_nkid   NUMBER;
    BEGIN
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('TRAN_TAX_QUALIFIERS', condition_id);

        DELETE FROM TRAN_TAX_QUALIFIERS trq
         WHERE trq.id = condition_id
        RETURNING rid, nkid
          INTO l_rid, l_nkid;

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, deleted_by_i
               FROM tmp_delete
              WHERE primary_key = condition_id);

        UPDATE TRAN_TAX_QUALIFIERS trq
           SET next_rid = NULL
         WHERE trq.next_rid = l_rid AND trq.nkid = l_nkid;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (SQLCODE, SQLERRM || ': ' || condition_id);
    END remove_condition;

    /** Remove Taxability Items Taxable, Exempt, NoTax
     *
     */

    PROCEDURE remove_taxability_items (
        refsection     IN NUMBER,
        tax_app_set    IN xmlformtaxability_taxapplsets,
        deleted_by_i   IN NUMBER)
    IS
        l_id     NUMBER;
        l_rid    NUMBER;
        l_nkid   NUMBER;
        l_tx_output_id number;
        l_existing_sets number;
    BEGIN
      -- Log delete of set
        INSERT INTO tmp_delete (table_name, primary_key)
        VALUES ('TAX_APPLICABILITY_SETS', tax_app_set.id);

        /*
        DELETE FROM tax_applicability_taxes tat
        WHERE tat.juris_tax_applicability_id = tax_app_set.
        AND tat.rid = tax_app_set.rid;*/

        --INSERT INTO tmp_delete (table_name, primary_key)
        --VALUES ('TAXABILITY_OUTPUTS', l_tx_output_id);

       -- /* start temp fix */
       -- Remove Outputs based on the removed set record
       -- This was the default way
       /* Delete from taxability_outputs tao
          where tao.id = l_tx_output_id
          and tao.rid = tax_app_set.rid;*/

           -- Temp fix to look up if there are multiple sets using the same
           -- might not cover all scenarios (revisions for example) since
           -- UI is not validating that unique records are entered.
           -- taxability output
/*
           Select count(*)
             into l_existing_sets
             From tax_applicability_sets
            Where taxability_output_id = l_tx_output_id
              and rid = tax_app_set.rid;

           if l_existing_sets > 0 then
              -- multiple available
              DBMS_OUTPUT.Put_Line( 'Recommendation: Warning log Duplicate records' );
           else
             Delete from taxability_outputs tao
             where tao.id = l_tx_output_id
               and tao.rid = tax_app_set.rid;
           end if;

           /* end temp fix */

        INSERT INTO delete_logs (table_name, primary_key, deleted_by)
            (SELECT table_name, primary_key, deleted_by_i
               FROM tmp_delete
              WHERE primary_key = tax_app_set.id);

    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            errlogger.
             report_and_stop (SQLCODE, SQLERRM || ': ' || tax_app_set.id);
    END remove_taxability_items;


    /** Taxability Search **/
    PROCEDURE gettaxability (
        pjurisdiction_id     IN     NUMBER,
        ptaxabilityrefcode   IN     VARCHAR2 DEFAULT NULL,
        ptaxability          IN     VARCHAR2 DEFAULT NULL,
        ptaxsystem           IN     VARCHAR2 DEFAULT NULL,
        pspecapplic          IN     VARCHAR2 DEFAULT NULL,
        ptransapplic         IN     VARCHAR2 DEFAULT NULL,
        pcalcmethod          IN     VARCHAR2 DEFAULT NULL,
        ptags                IN     VARCHAR2 DEFAULT NULL,
        peffective           IN     VARCHAR2 DEFAULT NULL,
        prevision            IN     VARCHAR2 DEFAULT NULL,
        p_ref                   OUT SYS_REFCURSOR)
    IS
        datarecord   outset;
        sq_whr       CLOB := '';
        ds_applicability juris_tax_applicabilities%ROWTYPE;
        nsetcount NUMBER;
    BEGIN
        -- Search page columns
        sq_main :=
            'SELECT DISTINCT
                jrs.id jurisdiction_id,
                jrs.nkid jurisdiction_nkid,
                jrs.rid jurisdiction_rid,
                juris_tax_applic_refcode,
                ati.name applicability_type_name,
                -- juris_tax_app_set_id,
                -- remove duplicate tax_reference_column
case when srch.all_taxes_apply = 0 then
                REGEXP_REPLACE(
                LISTAGG(juris_tax_imp_refcode, '','')
                WITHIN GROUP (ORDER BY juris_tax_imp_refcode)
                over (PARTITION BY
                juris_tax_applic_start,
                juris_tax_applic_end,
                juris_tax_applic_id)
                ,''([^,]*)(,\1)+($|,)'',
                ''\1\3'')
ELSE ''...'' END  tax_reference_column,
                -- remove duplicate juris_tax_applic_id
                REGEXP_REPLACE(
                LISTAGG(juris_tax_applic_id, '','')
                WITHIN GROUP (ORDER BY juris_tax_imp_refcode)
                over (PARTITION BY juris_tax_applic_refcode, juris_tax_applic_start,
                juris_tax_applic_end, juris_tax_app_set_id)
                ,''([^,]*)(,\1)+($|,)'',
                ''\1\3'') juris_tax_applic_ids,
                rev.id juris_tax_applic_entity_rid,
                to_char(juris_tax_applic_start,''mm/dd/yyyy'') juris_tax_applic_start,
                to_char(juris_tax_applic_end,''mm/dd/yyyy'') juris_tax_applic_end,
                ctg.NAME||''(''||to_char(ctg.id)||'')'' name,
                ctg.rid COMMODITY_TAX_GROUP_RID,
                srch.all_taxes_apply
                FROM taxability_applic_sets_v srch
                LEFT JOIN applicability_types ati ON (srch.applicability_type_id = ati.id)
                LEFT JOIN commodity_groups ctg
                     ON ( ctg.id = srch.commodity_group_id )
                ';

        sq_whr :=
               ' LEFT JOIN vjurisdictions jrs
                  ON (jrs.id = srch.jurisdiction_id)
                WHERE
                  -- Jurisdiction
                  jrs.nkid = '
            || pjurisdiction_id
            || '
            -- Skipped the binding for now
                  AND upper(decode( '''
            || ptaxabilityrefcode
            || ''', NULL , ''-1'',
                      srch.juris_tax_applic_refcode))
                      LIKE upper(decode( '''
            || ptaxabilityrefcode
            || ''', NULL, ''-1'', '''
            || ptaxabilityrefcode
            || '''))||''%'' ';

        sq_current_rev :=
            ' LEFT JOIN juris_tax_app_revisions rev
                      ON (srch.juris_tax_applic_nkid = rev.nkid
                      AND rev.id >= srch.juris_tax_applic_rid
                      AND rev.id < NVL(srch.juris_tax_applic_next_rid,999999999)
                    ) ';
        sq_include_tag := fnAndIs(searchVar=>pTags, dataCol=>'tgs.id');

        listtaxability := fnandis (searchvar   => ptaxability,
                     datacol     => 'applicability_type_id');
        listtaxsystem := fnandis (searchvar => ptaxsystem, datacol => 'taxation_type_id');
        listspecapplic := fnandis (searchvar   => pspecapplic,
                     datacol     => 'spec_applicability_type_id');
        listtransapplic := fnandis (searchvar   => ptransapplic,
                     datacol     => 'transaction_type_id');
        listcalcmethod := fnandis (searchvar => pcalcmethod, datacol => 'calc_method_id');

        IF prevision = 0
        THEN
            sq_main :=
                   sq_main
                || sq_current_rev
                || ' LEFT OUTER JOIN juris_tax_app_tags atgs on (atgs.ref_nkid = rev.nkid) '
                || ' LEFT OUTER JOIN Tags tgs ON (tgs.id = atgs.tag_id) '
                || sq_whr
                || listtaxability
                || listtaxsystem
                || listspecapplic
                || listtransapplic
                || listcalcmethod;
        ELSE
            sq_main :=
                sq_main
                || '  LEFT JOIN juris_tax_app_revisions rev
                  ON (srch.juris_tax_applic_nkid = rev.nkid
                      AND rev.id = srch.juris_tax_applic_rid
                    ) '
                || ' LEFT OUTER JOIN juris_tax_app_tags atgs on (atgs.ref_nkid = rev.nkid) '
                || ' LEFT OUTER JOIN Tags tgs ON (tgs.id = atgs.tag_id) '
                || sq_whr
                || listtaxability
                || listtaxsystem
                || listspecapplic
                || listtransapplic
                || listcalcmethod
                || sq_include_tag;
        END IF;

        IF peffective IS NOT NULL
        THEN
            sq_main :=
                   sq_main
                || ' and juris_tax_applic_start <= to_date('''
                || peffective
                || ''',''mm/dd/yyyy'')
                    AND (juris_tax_applic_end >= to_date('''
                || peffective
                || ''',''mm/dd/yyyy'') or juris_tax_applic_end is null) ';
        END IF;

    --> Here is the order by for the columns in Search Taxability page
    -- 8/25/2014: columns are formatted as VARCHAR...
    -- (There are some views used in other place that uses to_char. No idea why. Might be a UI thing.)
    -- Note that an order by in a ref cursor or piped is "not the best" way.

sq_Main:=sq_Main||' order by crapp_lib.fmtdate(juris_tax_applic_end) desc,
crapp_lib.fmtdate(juris_tax_applic_start) desc, juris_tax_applic_refcode asc, ati.name asc';

        -- Debug for search query:
        dbms_output.put_line(sq_Main);

        OPEN p_ref FOR sq_main;
    END;

    /* Taxability: Header Data */
    PROCEDURE taxability_header (applicability_rid   IN     NUMBER,
                                 p_ref                  OUT SYS_REFCURSOR)
    IS
    BEGIN
        Open p_ref For 'Select q1.*,
        q2.NXT JSON_CITATIONS
        from
        (SELECT distinct
        a.rid, a.nkid, a.id,
        rev.id entity_rid,
        rev.next_rid rev_next_rid,
        a.tax_applicability_sets_id,
        a.tax_reference,
        ''...'' reference_code,
        a.calculation_method_id,
        a.recoverable_percent,
        a.basis_percent,
        to_char(a.start_date,''mm/dd/yyyy'') start_date,
        to_char(a.end_date,''mm/dd/yyyy'') end_date
        ,a.status
        ,a.all_taxes_apply
        FROM
         juris_tax_app_revisions rev
         JOIN
        (
        SELECT
        jta.rid
        ,jta.nkid
        ,jta.id
        ,'' '' tax_applicability_sets_id
        ,jta.reference_code Tax_Reference
        ,jta.Calculation_Method_id
        ,jta.recoverable_percent
        ,jta.basis_percent
        ,jta.start_date
        ,jta.end_date
        ,jta.status
        ,jta.next_rid
        ,jta.all_taxes_apply
        FROM
         juris_tax_applicabilities jta
        ) A
        ON (a.nkid = rev.nkid
            AND rev_join(a.rid,rev.id,a.next_rid) = 1
        )
        WHERE rev.id = :revid) Q1,
       (
       select crapp_lib.refcursjson(P_REF_CURSOR=>cursor(SELECT
         a.citation_id,
         a.status,
         a.status_modified_date,
         a.change_log_id,
         a.rid,
         a.table_name,
         replace(a.summary,''&'','';'') summary,
         a.attachment_id,
         replace(a.text,''&'','';'') text
         FROM juris_tax_app_citations_v a where rid = :revid)) NXT
         from dual
       ) Q2'
       USING applicability_rid, applicability_rid;

    END;

    /* Taxability: Taxable/Exempt/O...
     *
     */
    PROCEDURE taxability_groups (applicability_rid   IN     NUMBER,
                                 p_ref                  OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR
            'Select v.id, v.rid, v.nkid, v.juris_tax_applicability_id,
                      v.commodity_tax_group_id,
                      v.commodity_tax_group_rid,
                      v.transaction_taxability_id,
                      v.taxability_output_id,
                      v.applicability_type_id,
                      apy.name,
                      to_char(v.start_date,''mm/dd/yyyy'') start_date,
                      to_char(v.end_date,''mm/dd/yyyy'') end_date,
                      v.commodity_tax_group_name,
                      v.short_text,
                      v.full_text,
                      v.status
                      From TAXABILITY_GROUP_DISPL_V v
                      JOIN juris_tax_applicabilities jta ON (v.juris_tax_applicability_id = jta.id)
                      JOIN applicability_types apy ON (apy.id = v.applicability_type_id)
                      where v.jtr_rid = :applicability_rid
                      order by v.applicability_type_id, v.end_date desc, v.start_date desc'
            USING applicability_rid;
    END;

    -- Applicable Taxes
    PROCEDURE taxability_applic (applicability_rid   IN     NUMBER,
                                 p_ref                  OUT SYS_REFCURSOR)
    IS
    BEGIN
    OPEN p_ref FOR '
    SELECT
         DISTINCT
         regexp_replace(LISTAGG(tat.id, '','')
         WITHIN GROUP (ORDER BY jti.reference_code)
         OVER (PARTITION BY jti.id),''([^,]+)(,\1)+'', ''\1'') tax_applicability_taxes_ids,
         jti.nkid juris_tax_imposition_nkid,
         jti.id juris_tax_imposition_id,
         jti.reference_code,
         to_char(tat.start_date,''mm/dd/yyyy'') start_date,
         to_char(tat.end_date ,''mm/dd/yyyy'') end_date,
         tat.status
         , txbo.short_text
            FROM tax_applicability_sets tas
            JOIN juris_tax_applicabilities jta ON
                 (
                   tas.juris_tax_applicability_id = jta.id
                 )
            JOIN juris_tax_app_revisions jtr ON
                 (
                   jtr.nkid = jta.nkid
                   and rev_join(tas.rid,jtr.id,tas.next_rid) = 1
                  )
            JOIN tax_applicability_taxes tat ON
                 (
                   tat.juris_tax_applicability_id = jta.id
                   and rev_join(tat.rid,jtr.id,tat.next_rid) = 1
                 )
            JOIN juris_tax_impositions jti ON
                 (
                   jti.id = tat.juris_tax_imposition_id
                 )
            LEFT JOIN taxability_outputs txbo on (txbo.juris_tax_applicability_id = jta.id)
            where jtr.id = :applicability_rid
            order by crapp_lib.fmtdate(end_date) desc
                   , crapp_lib.fmtdate(start_date) desc
                   , jti.reference_code'
    USING applicability_rid;

/*        OPEN p_ref FOR 'SELECT
         DISTINCT
         LISTAGG(tat.id, '','')
         WITHIN GROUP (ORDER BY jti.reference_code)
         OVER (PARTITION BY jti.id) tax_applicability_taxes_ids,
         jti.nkid juris_tax_imposition_nkid,
         jti.id juris_tax_imposition_id,
         jti.reference_code,
         to_char(tat.start_date,''mm/dd/yyyy'') start_date,
         to_char(tat.end_date ,''mm/dd/yyyy'') end_date,
         tat.status
            FROM tax_applicability_sets tas
            JOIN juris_tax_applicabilities jta ON (tas.juris_tax_applicability_id = jta.id)
    JOIN juris_tax_app_revisions jtr ON
    (
    jtr.nkid = jta.nkid
    and rev_join(tas.rid,jtr.id,tas.next_rid) = 1
    )
            JOIN tax_applicability_taxes tat
                ON (tat.juris_tax_applicability_id = jta.id
                AND tat.rid = tas.rid)
            JOIN juris_tax_impositions jti
            ON (jti.id = tat.juris_tax_imposition_id)
            where jtr.id = :applicability_rid
            order by crapp_lib.fmtdate(end_date) desc, crapp_lib.fmtdate(start_date) desc, jti.reference_code'
            USING applicability_rid;*/
    END;

    -- Lookup imposition reference_code
    PROCEDURE lookup_imp_refcode (jurisdiction_nkid   IN     NUMBER,
                                  p_ref                OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR
            'SELECT jti.id,
                      jti.rid,
                      jti.nkid,
                      jti.reference_code,
                      to_char(jti.start_date ,''mm/dd/yyyy'') start_date,
                      to_char(jti.end_date ,''mm/dd/yyyy'') end_date,
                      vtd.taxation_type,
                      vtd.transaction_type,
                      vtd.specific_applicability_type
                      FROM juris_tax_impositions jti
                      JOIN vtax_descriptions vtd ON (vtd.id = jti.tax_description_id)
                      JOIN jurisdictions jr ON (jti.jurisdiction_id = jr.id)
                      where jr.nkid = :jurisdiction_nkid
                      AND jti.next_rid IS NULL '
            USING jurisdiction_nkid;
    END;

    -- Additional attributes
    PROCEDURE taxability_additional (
        applicability_rid   IN     NUMBER,
        p_ref                  OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR
'SELECT lkp.attrid
      ,lkp.catid
      ,atr.value,
      to_char(atr.start_date ,''mm/dd/yyyy'') start_date,
      to_char(atr.end_date ,''mm/dd/yyyy'') end_date
      ,atr.status
      ,atr.id
      ,atr.rid
      ,atr.nkid
      ,lkp.attrname
      FROM juris_tax_app_attributes atr
      JOIN juris_tax_applicabilities jta ON (atr.juris_tax_applicability_id = jta.id)
      JOIN attributes_lookup_v lkp ON (lkp.attrid = atr.attribute_id)
      JOIN juris_tax_app_revisions jtr ON (jtr.nkid = jta.nkid
                                           and rev_join(atr.rid,jtr.id,atr.next_rid) > 0)
      WHERE jtr.id = :applicability_rid
      order by crapp_lib.fmtdate(end_date) desc, crapp_lib.fmtdate(start_date) desc, lkp.attrname'
            USING applicability_rid;

            /* old
                        'SELECT lkp.attrid
               ,lkp.catid
               ,attr.value,
               to_char(attr.start_date ,''mm/dd/yyyy'') start_date,
               to_char(attr.end_date ,''mm/dd/yyyy'') end_date
               ,attr.status
               ,attr.id
               ,attr.rid
               ,attr.nkid
               FROM juris_tax_applicabilities jta
               JOIN juris_tax_app_attributes attr ON (attr.rid = jta.rid)
               JOIN attributes_lookup_v lkp ON (lkp.attrid = attr.attribute_id)
               JOIN juris_tax_app_revisions jtr ON (jtr.nkid = jta.nkid
                 AND COALESCE(jta.next_rid,jtr.next_rid,99999999999) <= NVL(jtr.next_rid,99999999999))
               WHERE jtr.id = :applicability_rid
               order by start_date desc, end_date desc, lkp.catid ,attr.value'
            */
    END;

    -- Conditions
    PROCEDURE taxability_conditions(
      applicability_rid   IN  NUMBER,
      p_ref               OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_ref FOR
        'select
         id, nkid, rid, next_rid, entity_rid, entity_nkid, entity_next_rid, juris_tax_applicability_id,
         taxability_element_id, logical_qualifier, value, jurisdiction_id, start_date,
         end_date, status, status_modified_date, entered_by, entered_date, is_current
         from tran_tax_qualifiers_v
         where entity_rid = :applicability_rid
         order by crapp_lib.fmtdate(end_date) desc, crapp_lib.fmtdate(start_date) desc, juris_tax_applicability_id, taxability_element_id'
        USING applicability_rid;
    END;


    /* Delete */
    PROCEDURE delete_revision
       (
       jta_id IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER,
       prev_rid  OUT NUMBER,
       nkid_o    OUT NUMBER
       )
       IS
        l_rid NUMBER;
        l_deleted_by NUMBER := deleted_by_i;
        l_admin_pk NUMBER;
        l_status NUMBER;
    BEGIN
        success_o := 0;
        --Get revision ID to delete all depedent records by

        SELECT rid, nkid
          INTO l_rid, nkid_o
          FROM juris_tax_applicabilities
         WHERE id = jta_id;

      SELECT status, id
        INTO l_status, l_rid
        FROM juris_tax_app_revisions
        where nkid = nkid_o and next_rid is null;

        DBMS_OUTPUT.Put_Line( 'Status:'||l_status||':'||l_rid);

        IF (l_status = 0) THEN
            --Reset prior revisions to current

            dbms_output.put_line('updating outputs ');

                        -- taxability_outputs
            UPDATE taxability_outputs tr
            SET tr.next_rid = NULL
            WHERE tr.next_rid = l_rid;

            INSERT INTO tmp_delete (table_name, primary_key) (
                      SELECT 'TAXABILITY_OUTPUTS', tr.id
                      FROM taxability_outputs tr
                      WHERE tr.rid = l_rid
                  );

                DBMS_OUTPUT.Put_Line( '-- taxability_outputs' );

            DELETE FROM taxability_outputs tr
            WHERE tr.rid = l_rid;

            dbms_output.put_line('updating attributes ');

            UPDATE juris_tax_app_attributes aa
            SET aa.next_rid = NULL
            WHERE aa.next_rid = l_rid;

            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'JURIS_TAX_APP_ATTRIBUTES', aa.id
                FROM juris_tax_app_attributes aa
                WHERE aa.rid = l_rid
            );

                DBMS_OUTPUT.Put_Line( '-- juris_tax_app_attributes' );

            DELETE FROM juris_tax_app_attributes aa
            WHERE aa.rid = l_rid;

            -- tax_applicability_taxes
            UPDATE tax_applicability_taxes ac
            SET ac.next_rid = NULL
            WHERE ac.next_rid = l_rid;

            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'TAX_APPLICABILITY_TAXES', ac.id
                FROM tax_applicability_taxes ac
                WHERE ac.rid = l_rid
            );

            DBMS_OUTPUT.Put_Line( '-- tax_applicability_taxes' );

            DELETE FROM tax_applicability_taxes tr
            WHERE tr.rid = l_rid;

            -- tran_tax_qualifiers
            UPDATE tran_tax_qualifiers ac
            SET ac.next_rid = NULL
            WHERE ac.next_rid = l_rid;

            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'TRAN_TAX_QUALIFIERS', ac.id
                FROM TRAN_TAX_QUALIFIERS ac
                WHERE ac.rid = l_rid
            );

            DBMS_OUTPUT.Put_Line( '-- tran_tax_qualifiers' );

            DELETE FROM TRAN_TAX_QUALIFIERS tr
            WHERE tr.rid = l_rid;

            UPDATE juris_tax_applicabilities ji
            SET ji.next_rid = NULL
            WHERE ji.next_rid = l_rid;

            UPDATE juris_tax_app_revisions ji
            SET ji.next_rid = NULL
            WHERE ji.next_rid = l_rid;

            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'JURIS_TAX_APPLICABILITIES', ja.id
                FROM juris_tax_applicabilities ja
                WHERE ja.rid = l_rid
            );

            DBMS_OUTPUT.Put_Line( '-- juris_tax_applicabilities' );

            DELETE FROM juris_tax_applicabilities ji WHERE ji.rid = l_rid;

            --Remove Revision record
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('JURIS_TAX_APP_REVISIONS',l_rid);
            DELETE FROM juris_tax_app_chg_logs cl WHERE cl.rid = l_rid;
            DELETE FROM juris_tax_app_revisions ar WHERE ar.id = l_rid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
                SELECT table_name, primary_key, l_deleted_by
                FROM tmp_delete
            );

            success_o := 1;

          begin

          dbms_output.put_line('The value to extract revisions nkid value is '||nkid_o);

            select id, nkid into prev_rid, nkid_o from juris_tax_app_revisions where nkid = nkid_o and next_rid is null;

          exception
          when no_data_found
          then
                prev_rid := null;
                nkid_o  := null;
          end;




        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision;


    PROCEDURE Copy_Taxability(pJuris_taxab_id IN NUMBER
                              ,pNewJurisdiction IN number
                              ,pEntered_by IN NUMBER
                              ,rtnCopied OUT NUMBER)
    is
      recFound NUMBER := 0;
      l_txb_id juris_tax_applicabilities.id%TYPE;
      l_txb_nkid juris_tax_applicabilities.nkid%TYPE;
      l_txb_rid juris_tax_applicabilities.rid%TYPE;
      l_txo_id taxability_outputs.id%type;
      tao_id taxability_outputs.id%type;
      -- cpyToJurisdiction    selected_string; -- update multiple style (old)

      cpyOf_Applicability juris_tax_applicabilities%ROWTYPE;
      ds_taxability_outputs taxability_outputs%ROWTYPE;

      -- Note this is ONE set
      --TYPE tt_tax_set IS TABLE OF tax_applicability_sets%ROWTYPE;
      --ds_tax_set tt_tax_set:=tt_tax_set();

      -- Note and this is MULTIPLE sets
      TYPE rec_tax_sets IS RECORD
      (new_jta_id number,
       new_tou_id number,
       short_text varchar2(256),
       full_text varchar2(256),
       applicability_type_id number,
       start_date date,
       end_date date,
       entered_by number,
       commodity_group_id number);
      TYPE tt_ds_tax_sets IS TABLE OF rec_tax_sets;
      ds_tax_sets tt_ds_tax_sets:=tt_ds_tax_sets();

      -- dataset for current tags
      TYPE tt_tax_tags IS TABLE OF juris_tax_imposition_tags%ROWTYPE;
      ds_tax_tags tt_tax_tags:=tt_tax_tags();
      -- dataset for new tags
      ds_new_tax_tags xmlform_tags_tt := xmlform_tags_tt();

      type tt_tax_cond is table of tran_tax_qualifiers%rowtype;
      ds_tax_cond tt_tax_cond:=tt_tax_cond();

      TYPE rec_current_jta IS RECORD
      (record_id NUMBER,
       record_nkid NUMBER,
       record_rid number,
       record_juris_id number);
      jta_ds_cur rec_current_jta;

      type rec_tax_applic_new is record
      (jti_id number,
       jta_id number,
       jta_rid number,
       jti_rid number,
       start_date date,
       end_date date,
       entered_by number);
      type tt_records IS TABLE OF rec_tax_applic_new; --%ROWTYPE;
      ds_tax_applic_new tt_records:=tt_records();

      TYPE tt_applicability_list IS TABLE OF tax_applicability_taxes.id%TYPE;
      ds_applicability_id_list tt_applicability_list:=tt_applicability_list();

    begin
DBMS_OUTPUT.Put_Line( 'taxabId:'||pJuris_taxab_id||' '|| pNewJurisdiction );

      rtnCopied := 0;
      -- Taxability record #1...n
      DBMS_OUTPUT.Put_Line( '------------------------------------------------------' );
      DBMS_OUTPUT.Put_Line( 'Copy Taxability #ID:'||pJuris_taxab_id );

      SELECT *
      INTO cpyOf_Applicability
      FROM juris_tax_applicabilities
      WHERE id = pJuris_taxab_id
        AND next_rid is null;

      --
      IF (SQL%FOUND) THEN
        INSERT INTO juris_tax_applicabilities(
             jurisdiction_id,
             reference_code,
             calculation_method_id,
             basis_percent,
             recoverable_percent,
             start_date,
             end_date,
             entered_by,
             all_taxes_apply
          )
            VALUES (
             pNewJurisdiction
            ,cpyOf_Applicability.reference_code
            ,cpyOf_Applicability.calculation_method_id
            ,cpyOf_Applicability.basis_percent
            ,cpyOf_Applicability.recoverable_percent
            ,cpyOf_Applicability.start_date
            ,cpyOf_Applicability.end_date
            ,pEntered_by
            ,cpyOf_Applicability.all_taxes_apply
            )
            RETURNING id, nkid, rid INTO l_txb_id, l_txb_nkid, l_txb_rid;
DBMS_OUTPUT.Put_Line('Id:'||l_txb_id||' rid:'||l_txb_rid||' Nkid:'||l_txb_nkid);

            -- TAX_APPLICABILITY_TAXES
            -- l_txb_id :: juris_tax_applicability_id
            -- Get Imposition ID's
            -- tax_applicability_taxes
/*
            DBMS_OUTPUT.Put_Line( 'Tax Relationships' );
--11/14 trigger throws pri key null
DBMS_OUTPUT.Put_Line( 'insert into tax_relationships
            (tax_applicability_id, related_tax_applicability_id, relationship_type, entered_by, start_date, end_date,
            basis_amount_type, basis_value,
            status)
            (Select '||l_txb_id||', rl.related_tax_applicability_id, rl.relationship_type,'|| pEntered_by||', rl.start_date, rl.end_date,
            rl.basis_amount_type,
            rl.basis_value,'||
            l_txb_nkid||','|| l_txb_rid ||',status
            from tax_relationships rl
            where rl.tax_applicability_id ='|| pJuris_taxab_id||');');

            insert into tax_relationships
            (tax_applicability_id, related_tax_applicability_id, relationship_type, entered_by, start_date, end_date,
            basis_amount_type, basis_value,
            --nkid, rid,
            status)
            (Select l_txb_id, rl.related_tax_applicability_id, rl.relationship_type, pEntered_by, rl.start_date, rl.end_date,
            rl.basis_amount_type,
            rl.basis_value,
            --l_txb_nkid, l_txb_rid
            status
            from tax_relationships rl
            where rl.tax_applicability_id = pJuris_taxab_id);
*/
DBMS_OUTPUT.Put_Line( 'Outputs' );
--7/24 ah...code cleanup; columns not needed - set to 0 (record set is still the same though)

/*
            Select 0 new_jta_id,
                   0 new_tou_id, -- empty for new record
                   tou.short_text,
                   tou.full_text,
                   st.applicability_type_id,
                   st.start_date,
                   st.end_date,
                   pEntered_by,
                   st.commodity_group_id
                   Bulk Collect Into ds_tax_sets
            from tax_applicability_sets st
            join taxability_outputs tou on (st.taxability_output_id = tou.id)
            where st.juris_tax_applicability_id=pJuris_taxab_id
            and st.next_rid is null;

            if ds_tax_sets.count>0 then
              FOR txo IN ds_tax_sets.first..ds_tax_sets.last
              LOOP

                Insert into taxability_outputs
                (juris_tax_applicability_id, short_text, full_text, entered_by)
                values (
                  l_txb_id,
                  ds_tax_sets(txo).short_text,
                  ds_tax_sets(txo).full_text,
                  ds_tax_sets(txo).entered_by
                ) returning id into tao_id;

                Insert into tax_applicability_sets a
                (juris_tax_applicability_id, taxability_output_id,
                applicability_type_id, start_date,
                end_date, entered_by, commodity_group_id)
                values (l_txb_id,
                 tao_id,
                 ds_tax_sets(txo).applicability_type_id,
                 ds_tax_sets(txo).start_date,
                 ds_tax_sets(txo).end_date,
                 ds_tax_sets(txo).entered_by,
                 ds_tax_sets(txo).commodity_group_id);

               END LOOP;
            END IF;
*/

            -- Applicable Conditions
            Select *
            Bulk Collect Into ds_tax_cond
            From tran_tax_qualifiers trq
            Where trq.juris_tax_applicability_id = pJuris_taxab_id
              and trq.next_rid is null;
              -- and nkid=

            IF (ds_tax_cond.count > 0) then
              FOR lp IN ds_tax_cond.first..ds_tax_cond.last
              LOOP
                Insert Into tran_tax_qualifiers trq
                 (juris_tax_applicability_id,
                  taxability_element_id,
                  logical_qualifier,
                  value,
                  element_qual_group,
                  start_date,
                  end_date,
                  jurisdiction_id,
                  reference_group_id,
                  qualifier_type,
                  entered_by)
                  values(l_txb_id,
                  ds_tax_cond(lp).taxability_element_id,
                  ds_tax_cond(lp).logical_qualifier,
                  ds_tax_cond(lp).value,
                  ds_tax_cond(lp).element_qual_group,
                  ds_tax_cond(lp).start_date,
                  ds_tax_cond(lp).end_date,
                  ds_tax_cond(lp).jurisdiction_id,
                  ds_tax_cond(lp).reference_group_id,
                  ds_tax_cond(lp).qualifier_type,
                  pEntered_by);
              END LOOP;

            END IF;

            -- Additional Attributes
            FOR dsAttRec IN (
            SELECT txa.attribute_id, txa.value, txa.start_date, txa.end_date
            FROM juris_tax_app_attributes txa
            WHERE txa.juris_tax_applicability_id= pJuris_taxab_id
            AND txa.attribute_id NOT IN
            (SELECT id FROM additional_attributes WHERE NAME = 'Reporting Code')
            AND txa.next_rid is null)
            LOOP
              Insert into juris_tax_app_attributes
              (juris_tax_applicability_id, attribute_id, value, start_date, end_date, entered_by)
              values
              (l_txb_id,
               dsAttRec.attribute_id,
               dsAttRec.value,
               dsAttRec.start_date,
               dsAttRec.end_date,
               pEntered_by);
            END LOOP;


            /*
            -- Contributes
            FOR dsTaxRel IN (
             select tax_applicability_id, related_tax_applicability_id,
             relationship_type, entered_by,
             start_date, end_date, status,
             basis_amount_type, basis_value
             from
             tax_relationships
             where tax_applicability_id = pJuris_taxab_id
               and next_rid is null)
            loop
            insert into tax_relationships
            (tax_applicability_id, related_tax_applicability_id,
             relationship_type, entered_by,
             start_date, end_date, status,
             basis_amount_type, basis_value)
            (select l_txb_id, related_tax_applicability_id,
             relationship_type, pEntered_by,
             start_date, end_date, status,
             basis_amount_type, basis_value
             FROM tax_relationships
             where tax_applicability_id = pJuris_taxab_id);
            end loop;

            */

        -- Publication Tags
        -- TAGS
        -- (might want to specify what columns are needed only)
        Select tg.*
        Bulk Collect Into ds_tax_tags
             From juris_tax_app_tags tg
        Where tg.ref_nkid =
         (SELECT max(j.nkid) mxi
          FROM juris_tax_app_revisions r
          join juris_tax_applicabilities j on (j.nkid = r.nkid)
          where r.id = cpyOf_Applicability.rid
          and j.rid <= r.id );

        IF (ds_tax_tags.count > 0) then
            FOR lp IN ds_tax_tags.first..ds_tax_tags.last
            LOOP
              DBMS_OUTPUT.Put_Line('Rec:'||lp||' Tag Id:'||ds_tax_tags(lp).tag_id||' Nkid:'||l_txb_nkid);
              ds_new_tax_tags.extend;
              ds_new_tax_tags( ds_new_tax_tags.last ):=xmlform_tags(4,
              ds_tax_tags(lp).ref_nkid,
              pEntered_by,
              ds_tax_tags(lp).tag_id,
              0,
              0);
            END LOOP;
            tags_registry.tags_entry(ds_new_tax_tags, l_txb_nkid);
        End if;

      --> Check (test with a distinct / n/a)
      DBMS_OUTPUT.Put_Line( 'JTA' );
      Select distinct jta.id, jta.nkid, jta.rid, jta.jurisdiction_id
      into jta_ds_cur
      from juris_tax_applicabilities jta
      where jta.rid = l_txb_rid;

/* Alpha version Test */
      select
        jti.id,
        -- FOR DEBUG PURPOSES jti.reference_code,
        jta.id,
        jta.rid,
        -- FOR DEBUG PURPOSES jta.nkid,
        jti.rid,
        a.start_date,
        a.end_date,
        pEntered_by
      Bulk Collect Into ds_tax_applic_new
      from juris_tax_impositions jti
      join
      (select tx.*, jti.reference_code from tax_applicability_taxes tx
       join juris_tax_impositions jti
       on (jti.id = tx.juris_tax_imposition_id)
       where jti.jurisdiction_id = cpyOf_Applicability.jurisdiction_id -- known copy from id
       and tx.juris_tax_applicability_id = pJuris_taxab_id
       and tx.next_rid is null
       ) A
       on (a.reference_code = jti.reference_code)
       join juris_tax_applicabilities jta on (jta.jurisdiction_id = jti.jurisdiction_id
       and jta.id=jta_ds_cur.record_id) -- 415315 cpyOf_Applicability (known item)
       and jti.jurisdiction_id = jta_ds_cur.record_juris_id -- 30985 known new jurisdiction id
       and jta.rid = l_txb_rid  -- known rid
       and jti.next_rid is null;


       FORALL i IN ds_tax_applic_new.FIRST..ds_tax_applic_new.LAST
         INSERT INTO Tax_applicability_taxes (
                juris_tax_imposition_id,
                juris_tax_applicability_id,
                start_date,
                end_date,
                entered_by
                )
            VALUES (
                ds_tax_applic_new(i).jti_id,
                ds_tax_applic_new(i).jta_id,
                ds_tax_applic_new(i).start_date,
                ds_tax_applic_new(i).end_date,
                ds_tax_applic_new(i).entered_by
                )
            RETURNING id BULK COLLECT INTO ds_applicability_id_list;
      END IF;


      FORALL i IN ds_applicability_id_list.FIRST..ds_applicability_id_list.LAST
         INSERT INTO log_copy_juris_applic (
                log_date,
                tax_applicability_id,
                entered_by
                )
            VALUES (sysdate,
                ds_applicability_id_list(i),
                pEntered_by
                );


    END Copy_Taxability;

    PROCEDURE unique_check(juris_nkid_i IN NUMBER, ref_code_i IN VARCHAR2, nkid_i IN NUMBER)
    IS
        l_count number;
    BEGIN
        select count(*)
        INTO l_count
        from juris_tax_applicabilities
        where reference_code = ref_code_i
        and nkid != nvl(nkid_i,0)
        and abs(status) != 3
        and jurisdiction_nkid = juris_nkid_i;

        IF (l_count > 0) THEN
           raise_application_Error( errnums.en_duplicate_key,'Duplicate error: Reference Code provided already exists for another Taxability in this Jurisdiction.');
        END IF;
    END unique_check;


    /*
    *  Reset Status
    */
    PROCEDURE reset_status
       (
       revision_id_i IN NUMBER,
       reset_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_reset_by NUMBER := reset_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        setVal NUMBER := 0;

        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
        success_o := 0;
        --Get status to validate that it's a record that can be reset

        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM juris_tax_app_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN
            SELECT status
            INTO l_status
            FROM juris_tax_app_revisions
            WHERE id = l_rid;

            IF (l_status = 1) THEN

                UPDATE juris_tax_app_attributes ja
                SET status = setVal,
                ja.entered_By = l_reset_by
                WHERE ja.rid = l_rid;

                UPDATE tax_applicability_taxes ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE taxability_outputs ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE tran_tax_qualifiers ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE juris_tax_applicabilities ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                --Reset status
                UPDATE juris_tax_app_revisions ji
                SET ji.status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.id = l_rid;

                --COMMIT;
                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record status could not be changed because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END reset_status;

    /*
    || prc: delete_revision
    || Overloaded
    || Reset status, remove revision, remove documentations
    */
    PROCEDURE delete_revision
       (
       resetAll IN Number,
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        l_cit_count number;
        --l_submit_id NUMBER := submit_delete_id.nextval;

        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
        success_o := 0;

        if resetAll = 1 then
            SELECT COUNT(status)
            INTO l_stat_cnt
            FROM juris_tax_applicabilities
            WHERE id = l_rid;

            IF l_stat_cnt > 0 THEN -- crapp-2749
              SELECT status
              INTO l_status
              FROM juris_tax_applicabilities
              WHERE id = l_rid;

              IF (l_status = 1) THEN
                reset_status(revision_id_i=>revision_id_i, reset_by_i=>deleted_by_i, success_o=>success_o);
                -- {{Any option if failed?}}
              End If; -- status

              Delete From juris_tax_app_chg_vlds vld
              Where vld.juris_tax_app_chg_log_id in
              (Select id From juris_tax_app_chg_logs
                Where rid=l_rid);

              IF SQL%NOTFOUND THEN
                DBMS_OUTPUT.PUT_LINE('No validations to remove');
              END IF;
            END IF; -- l_stat_cnt
        end if; -- resetAll

        --Get revision ID to delete all depedent records by
        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM juris_tax_app_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM juris_tax_app_revisions
            where id = l_rid;

DBMS_OUTPUT.Put_Line( 'Status:'||l_status);

            IF (l_status = 0) THEN
                --Reset prior revisions to current
                UPDATE juris_tax_app_attributes aa
                SET aa.next_rid = NULL
                WHERE aa.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'JURIS_TAX_APP_ATTRIBUTES', aa.id
                    FROM juris_tax_app_attributes aa
                    WHERE aa.rid = l_rid
                );

DBMS_OUTPUT.Put_Line( '-- juris_tax_app_attributes' );

                DELETE FROM juris_tax_app_attributes aa
                WHERE aa.rid = l_rid;

                -- tax_applicability_taxes
                UPDATE tax_applicability_taxes ac
                SET ac.next_rid = NULL
                WHERE ac.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'TAX_APPLICABILITY_TAXES', ac.id
                    FROM tax_applicability_taxes ac
                    WHERE ac.rid = l_rid
                );

DBMS_OUTPUT.Put_Line( '-- tax_applicability_taxes' );

                DELETE FROM tax_applicability_taxes tr
                WHERE tr.rid = l_rid;

                -- taxability_outputs
                UPDATE taxability_outputs tr
                SET tr.next_rid = NULL
                WHERE tr.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key) (
                          SELECT 'TAXABILITY_OUTPUTS', tr.id
                          FROM taxability_outputs tr
                          WHERE tr.rid = l_rid
                      );

DBMS_OUTPUT.Put_Line( '-- taxability_outputs' );

                DELETE FROM taxability_outputs tr
                WHERE tr.rid = l_rid;

                -- tran_tax_qualifiers
                UPDATE tran_tax_qualifiers ac
                SET ac.next_rid = NULL
                WHERE ac.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'TRAN_TAX_QUALIFIERS', ac.id
                    FROM TRAN_TAX_QUALIFIERS ac
                    WHERE ac.rid = l_rid
                );

                DELETE FROM TRAN_TAX_QUALIFIERS tr
                WHERE tr.rid = l_rid;

                UPDATE juris_tax_applicabilities ji
                SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                UPDATE juris_tax_app_revisions ji
                SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'JURIS_TAX_APPLICABILITIES', ja.id
                    FROM juris_tax_applicabilities ja
                    WHERE ja.rid = l_rid
                );

                DELETE FROM juris_tax_applicabilities ji WHERE ji.rid = l_rid;

                if resetAll = 1 then
                    Select count(*) INTO l_cit_count
                    From juris_tax_app_chg_cits cit where cit.juris_tax_app_chg_log_id
                    IN (Select id From juris_tax_app_chg_logs jc where jc.rid = l_rid);

                    If l_cit_count > 0 Then
                        DELETE FROM juris_tax_app_chg_cits cit where cit.juris_tax_app_chg_log_id
                        IN (Select id From juris_tax_app_chg_logs jc where jc.rid = l_rid);
                    End if;
              end if;

                --Remove Revision record
                INSERT INTO tmp_delete (table_name, primary_key) VALUES ('JURIS_TAX_APP_REVISIONS',l_rid);
                DELETE FROM juris_tax_app_chg_logs cl WHERE cl.rid = l_rid;
                DELETE FROM juris_tax_app_revisions ar WHERE ar.id = l_rid;

                INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
                    SELECT table_name, primary_key, l_deleted_by
                    FROM tmp_delete
                );

                --COMMIT;

                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        ELSE
            success_o := 1; -- returning success since there was nothing to remove
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END delete_revision; -- Overloaded 1


procedure update_appltaxes ( sx clob, success out number, appltax_pk out number)
is
upd_appl_taxes xmlform_appltaxes_ty := xmlform_appltaxes_ty();
rec_upd  xmlform_appltaxes;
l_success number := 0;

l_entered_by number := -2918; -- The current xml have entered_by only at header section. This procedure will be used in future.
begin

    --insert into dev_applicability_xml values ( sx, sysdate, 'update_appltaxes');
    --commit;

    parse_applTaxes ( sx, upd_appl_taxes );

    for i in 1..upd_appl_taxes.count
    loop
        if i=1 then

            rec_upd := upd_appl_taxes(i);

            if rec_upd.deleted = 0 then
                update_taxes(rec_upd, appltax_pk, l_entered_by, null, null, null, null);
                l_success := 1;
            else
                remove_taxes(rec_upd.id, l_entered_by, null, null );
            end if;

        end if;

    end loop;

    success := l_success;

end;

procedure update_applconditions ( sx clob, success out number, applcond_pk out number )
is
upd_appl_cond xmlform_applcond_ty := xmlform_applcond_ty();
rec_upd  xmlform_applcond;
l_success number := 0;
l_entered_by number := -2918; -- The current xml have entered_by only at header section. This procedure will be used in future.
begin

    --insert into dev_applicability_xml values ( sx, sysdate, 'update_applconditions');
    --commit;

    dbms_output.put_line('Processing Applicable COnditions ');

    parse_applConditions ( sx, upd_appl_cond, 1 );


    for i in 1..upd_appl_cond.count
    loop

    dbms_output.put_line('Insert Applicable Taxes '||upd_appl_cond(i).juris_tax_applicability_id);
    --dbms_output.put_line('Insert Applicable Taxes '||upd_appl_cond(i).juris_tax_applicability_nkid);

        if i = 1 then
        rec_upd := upd_appl_cond(i);

        update_condition(rec_upd, applcond_pk, l_entered_by );
        l_success := 1;

        end if;

    end loop;

    success := l_success;
end;

procedure update_applattribute ( sx clob, success out number, applattr_pk out number )
is
upd_appl_attr xmlform_applattr_ty := xmlform_applattr_ty();
rec_ins  xmlform_applattr;
l_success number := 0;
l_entered_by number := -2918; -- The current xml have entered_by only at header section. This procedure will be used in future.

begin

     --insert into dev_applicability_xml values ( sx, sysdate, 'update_applattribute');
     --commit;

    dbms_output.put_line('Processing Applicable Attributes ');
    parse_applattr ( sx, upd_appl_attr, 1 );
    for i in 1..upd_appl_attr.count
    loop

    dbms_output.put_line('Insert Applicable Taxes '||upd_appl_attr(i).juris_tax_applicability_id);
    --dbms_output.put_line('Insert Applicable Taxes '||upd_appl_attr(i).juris_tax_applicability_nkid);

        if i = 1 then
        rec_ins := upd_appl_attr(i);

        update_attributes (rec_ins, applattr_pk, l_entered_by);

        l_success := 1;

        end if;

    end loop;

    success := l_success;

end;

Procedure Update_ApplHeader (sx clob, success out number, appl_pk out number )
is

ins_upd_header appl_header;
l_jta_id number;
l_jta_nkid number;
l_jta_rid number;
l_success number := 0;

begin

    --insert into dev_applicability_xml values ( sx, sysdate, 'Update_ApplHeader');
        --commit;

    success := 0;
    parse_applheader ( sx, ins_upd_header);

    update_header (ins_upd_header, l_jta_id, l_jta_nkid, l_jta_rid);

     appl_pk := l_jta_id;
     success := 1;

end;

procedure update_applattribute_dev ( sx clob, success out number, applattr_pk out number )
is

upd_appl_attr xmlform_applattr_ty := xmlform_applattr_ty();
rec_ins  xmlform_applattr;
l_success number := 0;

begin

    dbms_output.put_line('Processing Applicable COnditions ');
    parse_applattr ( sx, upd_appl_attr, 1 );
    for i in 1..upd_appl_attr.count
    loop

    dbms_output.put_line('Insert Applicable Taxes '||upd_appl_attr(i).juris_tax_applicability_id);
    --dbms_output.put_line('Insert Applicable Taxes '||upd_appl_attr(i).juris_tax_applicability_nkid);
    end loop;

end;

/*
PROCEDURE generate_xml_old (jta_id_i        NUMBER,
                        juris_id        NUMBER,
                        entered_by_i    NUMBER,
                        start_date_i      date,
                        end_date_i        date default null
)
IS
    l_xmlclob   CLOB;
    l_newxml    XMLTYPE;
    x           NUMBER;
    y           NUMBER;
    z           NUMBER;
    l_start_date date;
    l_end_date date;
BEGIN

l_start_date := to_date ( start_date_i, 'dd-mon-yyyy');
l_end_date := to_date ( end_date_i, 'dd-mon-yyyy');


    INSERT INTO taxability_xml_copy_taxes (jta_id,
                                tax_id_old,
                                reference_code,
                                jurisdiction_id)
        SELECT a.id,
               '<jurisTaxImpositionId>' || b.juris_tax_imposition_id,
               c.reference_code,
               juris_id
          FROM juris_tax_applicabilities a
               JOIN tax_applicability_taxes b
                   ON (a.id = b.juris_tax_applicability_id)
               JOIN juris_tax_impositions c
                   ON (b.juris_tax_imposition_id = c.id)
         WHERE a.id = jta_id_i;

    UPDATE taxability_xml_copy_taxes a
       SET tax_id_new =
               (SELECT '<jurisTaxImpositionId>' || id
                  FROM juris_tax_impositions b
                 WHERE     a.jurisdiction_id = b.jurisdiction_id
                       AND a.reference_code = b.reference_code
                       AND b.next_rid IS NULL)
     WHERE tax_id_new IS NULL AND a.jta_id = jta_id_i;

    --COMMIT;


    SELECT XMLSERIALIZE (
               DOCUMENT SYS_XMLGEN (
                            gen_appl_xml_ty (
                                -999,
                                NVL (d.applicability_type_id, -999),
                                NVL (d.calculation_method_id, -999),
                                NVL (d.recoverable_percent, -999),
                                NVL (d.basis_percent, -999),
                                nvl (d.charge_type_id, -999),
                                NVL (d.unit_of_measure, -999),
                                NVL (d.tax_type, ''),
                                nvl(l_start_date, d.start_date ),
                                NVL (nvl(l_end_date, d.end_date), '31-Dec-9999'),
                                NVL (d.all_taxes_apply, -999),
                                NVL (d.commodity_id, -999),
                                juris_id,
                                entered_by_i,
                                NVL (d.default_taxability, ''),
                                NVL (d.product_tree_id, -999),
                                0,
                                CAST (
                                    MULTISET (
                                        SELECT gen_appltaxes (
                                                   -999,
                                                   t.juris_tax_imposition_id,
                                                   -999,
                                                   -999,
                                                   t.tax_type,
                                                   nvl(l_start_date, t.start_date) ,
                                                   NVL (nvl( l_end_date, t.end_date),'31-Dec-9999'),
                                                   entered_by_i,
                                                   0,
                                                   tot.short_text)
                                          FROM tax_applicability_taxes t
                                               LEFT OUTER JOIN
                                               taxability_outputs tot
                                                   ON (t.id =
                                                           tot.tax_applicability_tax_id)
                                         WHERE t.juris_tax_applicability_id =
                                                   d.id) AS gen_appltaxes_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_applattr (
                                                   -999,
                                                   -999,
                                                   attribute_id,
                                                   nvl(l_start_date, start_date),
                                                   NVL ( nvl(l_end_date, end_date), '31-dec-9999'),
                                                   entered_by_i,
                                                   VALUE,
                                                   0)
                                          FROM juris_tax_app_attributes e
                                         WHERE e.juris_tax_applicability_id =
                                                   d.id) AS gen_applattr_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_applcond (
                                                   -999,
                                                   -999,
                                                   NVL (q.jurisdiction_id, -999),
                                                   q.reference_group_id,
                                                   q.taxability_element_id,
                                                   q.logical_qualifier,
                                                   q.VALUE,
                                                   q.element_qual_group,
                                                   nvl(l_start_date, q.start_date),
                                                   NVL (nvl(l_end_date, q.end_date),'31-Dec-9999'),
                                                   entered_by_i,
                                                   q.qualifier_type,
                                                   0)
                                          FROM tran_tax_qualifiers q
                                         WHERE q.juris_tax_applicability_id =
                                                   d.id) AS gen_applcond_ty))) AS CLOB)
               AS dep_xml
      INTO l_xmlclob
      FROM juris_tax_applicabilities d
           LEFT JOIN commodities c ON (d.commodity_id = c.id)
     WHERE d.id = jta_id_i;

    FOR i IN (SELECT *
              FROM taxability_copy_xml_elements)
    LOOP
        l_xmlclob := REPLACE (l_xmlclob, i.column_name, i.tag_name);
    END LOOP;

    l_xmlclob := REPLACE (l_xmlclob, '31-Dec-9999', '');
    l_xmlclob := REPLACE (l_xmlclob, -999, '');
    l_xmlclob := REPLACE (l_xmlclob, '&apos;', '''');
    -- l_xmlclob := REPLACE (l_xmlclob, '''', '''''');
    l_xmlclob := REPLACE (l_xmlclob, CHR (10), '');


    FOR i IN (SELECT *
              FROM taxability_xml_copy_taxes
              WHERE jta_id = jta_id_i AND jurisdiction_id = juris_id)
    LOOP
        l_xmlclob := REPLACE (l_xmlclob, i.tax_id_old, i.tax_id_new);
    END LOOP;

    DBMS_OUTPUT.put_line (l_xmlclob);

    SELECT XMLSERIALIZE (DOCUMENT xmltype (l_xmlclob))
      INTO l_xmlclob
      FROM DUAL;

    DBMS_OUTPUT.put_line (l_xmlclob);

    xmlprocess_form (l_xmlclob,
                     x,
                     y,
                     z);

    --COMMIT;
END;
*/

procedure enddate_taxability( jta_id_i number, start_date_i date )
is

l_end_date date;
vcnt        number;

begin

l_end_date := start_date_i - 1;

dbms_output.put_line('The end date should be '||l_end_date);

for i in ( select id from tax_applicability_taxes where juris_tax_applicability_id = jta_id_i and end_date is null )
loop
    dbms_output.put_line ('About to update the end date info on tax_applicability_taxes '||i.id);
    update tax_applicability_taxes set end_date = l_end_date where id = i.id;
end loop;

for i in ( select id from juris_tax_app_attributes where juris_tax_applicability_id = jta_id_i and end_date is null )
loop
    dbms_output.put_line ('About to update the end date info on juris_tax_app_attributes '||i.id);
    update juris_tax_app_attributes set end_date = l_end_date where id = i.id;
end loop;

for i in ( select id from tran_tax_qualifiers where juris_tax_applicability_id = jta_id_i and end_date is null )
loop
    dbms_output.put_line ('About to update the end date info on juris_tax_app_attributes '||i.id);
    update tran_tax_qualifiers set end_date = l_end_date where id = i.id;
end loop;

dbms_output.put_line ('About to update the end date info on juris_tax_applicabilities '||jta_id_i||'  '||l_end_date);
update juris_tax_applicabilities set end_date = l_end_date where id = jta_id_i and end_date is null;


end;
/*
-- This is the older version. Keeping it commented for any reference in future.
PROCEDURE generate_xml (jta_id_i        NUMBER,
                        juris_id        NUMBER,
                        entered_by_i    NUMBER,
                        start_date_i      date,
                        end_date_i        date default null,
                        local_flag      number default 0,
                        commodity_list  varchar2_32_t default null
                        )
IS
    l_xmlclob   CLOB;
    l_newxml    XMLTYPE;
    x           NUMBER;
    y           NUMBER;
    z           NUMBER;
    l_start_date date;
    l_end_date   date;
    l_loop_max   number;
    vcommodity   number;

BEGIN

l_start_date := to_date ( start_date_i, 'dd-mon-yyyy');
l_end_date := to_date ( end_date_i, 'dd-mon-yyyy');

if commodity_list is null
then
    l_loop_max := 1 ;
else
    l_loop_max := commodity_list.count;
end if;

if local_flag = 1 then

    dbms_output.put_line('About to call enddate_taxability '||local_flag);

    l_end_date := null;

    enddate_taxability( jta_id_i, l_start_date );

end if;


for i in 1..l_loop_max
loop
    if commodity_list is not null
    then
    vcommodity := commodity_list(i);
    end if;


    INSERT INTO taxability_xml_copy_taxes (jta_id,
                                tax_id_old,
                                reference_code,
                                jurisdiction_id)
        SELECT a.id,
               '<jurisTaxImpositionId>' || b.juris_tax_imposition_id,
               c.reference_code,
               juris_id
          FROM juris_tax_applicabilities a
               JOIN tax_applicability_taxes b
                   ON (a.id = b.juris_tax_applicability_id)
               JOIN juris_tax_impositions c
                   ON (b.juris_tax_imposition_id = c.id)
         WHERE a.id = jta_id_i;

    UPDATE taxability_xml_copy_taxes a
       SET tax_id_new =
               (SELECT '<jurisTaxImpositionId>' || b.id
                  FROM juris_tax_impositions b, jurisdictions j
                 WHERE     a.jurisdiction_id = j.id
                       AND j.nkid = b.jurisdiction_nkid
                       AND a.reference_code = b.reference_code
                       AND b.next_rid IS NULL)
     WHERE tax_id_new IS NULL AND a.jta_id = jta_id_i;

    SELECT XMLSERIALIZE (
               DOCUMENT SYS_XMLGEN (
                            gen_appl_xml_ty (
                                -999,
                                NVL (d.applicability_type_id, -999),
                                NVL (d.calculation_method_id, -999),
                                NVL (d.recoverable_percent, -999),
                                NVL (d.basis_percent, -999),
                                nvl (d.charge_type_id, -999),
                                NVL (d.unit_of_measure, -999),
                                NVL (d.tax_type, ''),
                                nvl(l_start_date, d.start_date ),
                                case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                     else NVL (nvl(l_end_date, d.end_date), '31-Dec-9999')
                                end,
                                NVL (d.all_taxes_apply, -999),
                                coalesce ( vcommodity, d.commodity_id, -999),
                                nvl ( juris_id, jurisdiction_id ),

                                entered_by_i,
                                case when d.default_taxability = 'D' then 1 else 0 end,
                                NVL (d.product_tree_id, -999),
                                0,
                                CAST (
                                    MULTISET (
                                        SELECT gen_appltaxes (
                                                   -999,
                                                   t.juris_tax_imposition_id,
                                                   -999,
                                                   -999,
                                                   t.tax_type,
                                                   nvl(l_start_date, t.start_date) ,
                                                    case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                                         else NVL (nvl(l_end_date, d.end_date), '31-Dec-9999')
                                                    end,
                                                    entered_by_i,
                                                   0,
                                                   tot.short_text)
                                          FROM tax_applicability_taxes t
                                               LEFT OUTER JOIN
                                               taxability_outputs tot
                                                   ON (t.id =
                                                           tot.tax_applicability_tax_id)
                                         WHERE t.juris_tax_applicability_id =
                                                   d.id) AS gen_appltaxes_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_applattr (
                                                   -999,
                                                   -999,
                                                   attribute_id,
                                                   nvl(l_start_date, start_date),
                                                    case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                                         else NVL (nvl(l_end_date, d.end_date), '31-Dec-9999')
                                                    end,
                                                   entered_by_i,
                                                   VALUE,
                                                   0)
                                          FROM juris_tax_app_attributes e
                                         WHERE e.juris_tax_applicability_id =
                                                   d.id) AS gen_applattr_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_applcond (
                                                   -999,
                                                   -999,
                                                   NVL (q.jurisdiction_id, -999),
                                                   q.reference_group_id,
                                                   q.taxability_element_id,
                                                   l.id,
                                                   q.VALUE,
                                                   q.element_qual_group,
                                                   nvl(l_start_date, q.start_date),
                                                    case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                                         else NVL (nvl(l_end_date, d.end_date), '31-Dec-9999')
                                                    end,
                                                   entered_by_i,
                                                   q.qualifier_type,
                                                   0)
                                          FROM tran_tax_qualifiers q
                                               join logical_qualifiers l on ( q.logical_qualifier = l.name )
                                         WHERE q.juris_tax_applicability_id =
                                                   d.id) AS gen_applcond_ty))) AS CLOB)
               AS dep_xml
      INTO l_xmlclob
      FROM juris_tax_applicabilities d
           LEFT JOIN commodities c ON (d.commodity_id = c.id)
     WHERE d.id = jta_id_i;

    FOR i IN (SELECT *
              FROM taxability_copy_xml_elements)
    LOOP
        l_xmlclob := REPLACE (l_xmlclob, i.column_name, i.tag_name);
    END LOOP;




    l_xmlclob := REPLACE (l_xmlclob, '31-Dec-9999', '');
    l_xmlclob := REPLACE (l_xmlclob, '31-DEC-99', '');
    l_xmlclob := REPLACE (l_xmlclob, -999, '');
    l_xmlclob := REPLACE (l_xmlclob, '&apos;', '''');
    -- l_xmlclob := REPLACE (l_xmlclob, '''', '''''');
    l_xmlclob := REPLACE (l_xmlclob, CHR (10), '');



    FOR i IN (SELECT *
              FROM taxability_xml_copy_taxes
              WHERE jta_id = jta_id_i AND jurisdiction_id = juris_id)
    LOOP
        l_xmlclob := REPLACE (l_xmlclob, i.tax_id_old, i.tax_id_new);
    END LOOP;

    DBMS_OUTPUT.put_line (l_xmlclob);

    SELECT XMLSERIALIZE (DOCUMENT xmltype (l_xmlclob))
      INTO l_xmlclob
      FROM DUAL;

    DBMS_OUTPUT.put_line (l_xmlclob);



    xmlprocess_form (l_xmlclob,
                     x,
                     y,
                     z);

end loop;

END;
*/
PROCEDURE generate_xml (jta_id_i        NUMBER,
                        juris_nkid      NUMBER,
                        entered_by_i    NUMBER,
                        start_date_i    date,
                        end_date_i      date default null,
                        local_flag      number default 0,
                        commodity_list  varchar2_32_t default null
                        )
IS
    l_xmlclob   CLOB;
    l_newxml    XMLTYPE;
    x           NUMBER;
    y           NUMBER;
    z           NUMBER;
    l_start_date date;
    l_end_date   date;
    l_loop_max   number;
    vcommodity   number;
    ljta_rid     number;
    errMsg varchar2(2000);
    ljuris_id number;
    lcomm_from varchar2(500);
    lcomm_to varchar2(500);
    ljuris_from varchar2(500);
    ljuris_from_nkid varchar2(500);
    ljuris_from_rid varchar2(500);
    ljuris_to varchar2(500);
    lappl_link varchar2(100);
    lcomm_from_rid number;
    lcomm_authority varchar2(100);
    ljuris_comm_name varchar2(500);
BEGIN

lcopy_err_message := null;
-- Jurisdiction_NKID will be blank for copy commodity.
if juris_nkid is null then
    select jurisdiction_id into ljuris_id from juris_tax_applicabilities where id = jta_id_i;
else
    -- Changes for CRAPP-2823
    select id into ljuris_id from jurisdictions where nkid = juris_nkid and next_rid is null;
end if;

l_start_date := start_date_i;
l_end_date := end_date_i;

Dbms_output.put_line('l_start_date value is '||l_start_date);
Dbms_output.put_line('l_end_date value is '||l_end_date||':'||end_date_i);

select max(jtr.id) into ljta_rid from juris_tax_app_revisions jtr join juris_tax_applicabilities jta on ( jta.nkid = jtr.nkid )
where jta.id = jta_id_i;

if commodity_list is null
then
    l_loop_max := 1 ;
else
    l_loop_max := commodity_list.count;
end if;

--insert into dev_applicability_xml values ( start_date_i||':'||end_date_i||':'||jta_id_i||':'||ljuris_id||':'||l_loop_max, sysdate, 'paramteres');
--commit;

if local_flag = 1 then

    dbms_output.put_line('About to call enddate_taxability '||local_flag);

    l_end_date := null;

    enddate_taxability( jta_id_i, l_start_date );

end if;

for i in 1..l_loop_max
loop
    lcopy_link := null;
    lappl_link := null;
    if commodity_list is not null
    then
        -- Changes for CRAPP-2826
        select id, name into vcommodity, lcomm_to from commodities where product_tree_id = 13 and next_rid is null and nkid = commodity_list(i);
        select distinct c.name, c.rid, j.official_name
          into lcomm_from, lcomm_from_rid, lcomm_authority
          from juris_tax_applicabilities jta
          join commodities c on jta.commodity_id = c.id
          join jurisdictions j on ( jta.jurisdiction_id = j.id )
         where jta.id = jta_id_i;

         select url into lappl_link from action_log_url where entity = 'COMMODITY';

        lcopy_err_message := '{"Copy from commodity":"'||lcomm_from||'","Copy to commodity":"'||lcomm_to||'"," Jurisdiction, Taxability_RID":"'||lcomm_authority||':'||ljta_rid||'"';
        lcopy_link := lappl_link||lcomm_from_rid||'/upd';
    else
        /*
        select official_name, j.nkid, j.rid into ljuris_from, ljuris_from_nkid, ljuris_from_rid from juris_tax_applicabilities jta join jurisdictions j on j.id = jta.jurisdiction_id
          where jta.id = jta_id_i;
        */
        select official_name, j.nkid, j.rid, nvl(c.name, ' ')
          into ljuris_from, ljuris_from_nkid, ljuris_from_rid, ljuris_comm_name
          from juris_tax_applicabilities jta
          join jurisdictions j on j.id = jta.jurisdiction_id
     left join commodities c on ( c.id = jta.commodity_id)
        where jta.id = jta_id_i;

        select distinct official_name into ljuris_to from jurisdictions where nkid = juris_nkid and next_rid is null;

        select url into lappl_link from action_log_url where entity = 'JURISDICTION';

        -- lcopy_err_message := '{"Copy from jurisdiction":"'||ljuris_from||'", "Copy to jurisdiction":"'||ljuris_to||'"';
        lcopy_err_message := '{"Copy from jurisdiction":"'||ljuris_from||'", "Copy to jurisdiction":"'||ljuris_to||'", "Commodity":"'||ljuris_comm_name||'"';
        lcopy_link := lappl_link||ljuris_from_rid||'/'||ljuris_from_nkid||'/taxability/'||ljta_rid||'/upd';
    end if;
    INSERT INTO taxability_xml_copy_taxes (jta_id,
                                tax_id_old,
                                reference_code,
                                jurisdiction_id)
        SELECT a.juris_tax_applicability_id,
               '<jurisTaxImpositionId>' || a.juris_tax_imposition_id,
               a.reference_code,
               ljuris_id
          FROM vappl_tax_appl_inv a
         WHERE a.JURIS_TAX_APPLICABILITY_RID = ljta_rid and next_rid is null;

    UPDATE taxability_xml_copy_taxes a
       SET tax_id_new =
               (SELECT '<jurisTaxImpositionId>' || b.id
                  FROM juris_tax_impositions b, jurisdictions j
                 WHERE     a.jurisdiction_id = j.id
                       AND j.nkid = b.jurisdiction_nkid
                       AND a.reference_code = b.reference_code
                       AND b.next_rid IS NULL)
     WHERE tax_id_new IS NULL AND a.jta_id = jta_id_i;

dbms_output.put_line('About to call generating CLOB value');

    SELECT XMLSERIALIZE (
               DOCUMENT SYS_XMLGEN (
                            gen_appl_xml_ty (
                                -999,
                                NVL (d.applicability_type_id, -999),
                                NVL (d.calculation_method_id, -999),
                                NVL (d.recoverable_percent, -999),
                                NVL (d.recoverable_amount, -999),
                                NVL (d.basis_percent, -999),
                                nvl (d.charge_type_id, -999),
                                NVL (d.unit_of_measure, -999),
                                NVL (d.ref_Rule_Order, -999),
                                NVL (d.tax_type, ''),
                                coalesce (l_start_date, d.start_date, to_date('31-Dec-9999')),
                                case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                else coalesce (l_end_date, d.end_date, to_date('31-Dec-9999'))
                                end,
                                NVL (d.all_taxes_apply, -999),
                                coalesce ( vcommodity, d.commodity_id, -999),
                                nvl ( ljuris_id, jurisdiction_id ),
                                entered_by_i,
                                d.default_taxability,
                                NVL (d.product_tree_id, -999),
                                d.is_local,
                                CAST (
                                    MULTISET (
                                        SELECT gen_appltaxes (
                                                   -999,
                                                   t.juris_tax_imposition_id,
                                                   -999,
                                                   t.ref_rule_order,
                                                   tt.id,
                                                   coalesce (l_start_date, start_date, to_date('31-Dec-9999')),
                                                   case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                                         else coalesce (l_end_date, end_date, to_date('31-Dec-9999'))
                                                   end,
                                                   entered_by_i,
                                                   0,
                                                   t.invoice_statement)
                                          FROM vappl_tax_appl_inv t
                                               LEFT OUTER JOIN tax_types tt
                                                    on ( t.tax_type_id = tt.id )
                                         WHERE t.juris_tax_applicability_rid = d.rid and t.next_rid is null
                                                   ) AS gen_appltaxes_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_applattr (
                                                   -999,
                                                   -999,
                                                   attribute_id,
                                                   coalesce (l_start_date, to_date(e.start_date, 'MM/DD/YYYY'), to_date('31-Dec-9999')),
                                                   --coalesce (l_end_date, end_date, to_date('31-Dec-9999')),
                                                    case when local_flag = 1 then nvl(l_end_date, '31-Dec-9999')
                                                         else coalesce (l_end_date, to_date(e.end_date, 'MM/DD/YYYY'), to_date('31-Dec-9999'))
                                                    end,
                                                   entered_by_i,
                                                   VALUE,
                                                   0)
                                          FROM vjuris_tax_app_attributes e
                                         WHERE e.juris_tax_app_rid = d.rid) AS gen_applattr_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_applcond (
                                                   -999,
                                                   -999,
                                                   NVL (q.jurisdiction_id, -999),
                                                   q.reference_group_id,
                                                   q.taxability_element_id,
                                                   l.id,
                                                   q.VALUE,
                                                   q.element_qual_group,
                                                  -- coalesce (l_start_date, to_date(q.start_date), to_date('31-Dec-9999')),
                                                  -- coalesce (l_end_date, to_date(q.end_date), to_date('31-Dec-9999')),
                                                  nvl(nvl(l_start_date, to_date(q.start_date, 'MM/DD/YYYY')), '31-Dec-9999'),
                                                  nvl(nvl(l_end_date, to_date(q.end_date, 'MM/DD/YYYY')), '31-Dec-9999'),
                                                   entered_by_i,
                                                   null,
                                                   --q.qualifier_type,
                                                   0)
                                          FROM taxability_conditions_v q
                                               join logical_qualifiers l on ( q.logical_qualifier = l.name )
                                         WHERE q.trans_rid = d.rid
                                                   ) AS gen_applcond_ty),
                                CAST (
                                    MULTISET (
                                        SELECT gen_appltags (
                                                    jt.tag_id,
                                                   0,
                                                   1
                                                   )
                                          FROM juris_tax_app_tags jt
                                         WHERE jt.ref_nkid = d.nkid
                                                   ) AS gen_appltags_ty)
                                                   )) AS CLOB)
               AS dep_xml
      INTO l_xmlclob
      FROM taxability_search_v d
           LEFT JOIN commodities c ON (d.commodity_id = c.id)
     WHERE d.rid = ljta_rid;

dbms_output.put_line('Generated the XML and validating it further '||l_xmlclob);
    FOR i IN (SELECT *
              FROM taxability_copy_xml_elements)
    LOOP
        l_xmlclob := REPLACE (l_xmlclob, i.column_name, i.tag_name);
    END LOOP;

    l_xmlclob := REPLACE (l_xmlclob, '31-Dec-9999', '');
    l_xmlclob := REPLACE (l_xmlclob, '31-DEC-99', '');
    l_xmlclob := REPLACE (l_xmlclob, -999, '');
    l_xmlclob := REPLACE (l_xmlclob, ';', '''');
    -- l_xmlclob := REPLACE (l_xmlclob, '''', '''''');
    l_xmlclob := REPLACE (l_xmlclob, CHR (10), '');


    FOR i IN (SELECT *
              FROM taxability_xml_copy_taxes
              WHERE jta_id = jta_id_i AND jurisdiction_id = ljuris_id)
    LOOP
        l_xmlclob := REPLACE (l_xmlclob, i.tax_id_old, i.tax_id_new);
    END LOOP;

    DBMS_OUTPUT.put_line (l_xmlclob);

    SELECT XMLSERIALIZE (DOCUMENT xmltype (l_xmlclob))
      INTO l_xmlclob
      FROM DUAL;

    DBMS_OUTPUT.put_line (l_xmlclob);

    --insert into dev_applicability_xml values ( l_xmlclob, sysdate, 'GENERATE_XML');
    --commit;
    xmlprocess_form (l_xmlclob,
                     x,
                     y,
                     z,
                     1);
end loop;

    EXCEPTION
        WHEN others THEN
            ROLLBACK;
                errMsg:='Could not copy selected taxabilities.';
            errlogger.report_and_stop(SQLCODE,SQLERRM);

END;

procedure testing (jta_id_i number, start_date_i date )
is
l_end_date date;

begin

dbms_output.put_line(' the applicability id is '||jta_id_i ||' '||start_date_i);

l_end_date := start_date_i - 1;

    for i in ( select id from tax_applicability_taxes where juris_tax_applicability_id = jta_id_i and end_date is not null )
    loop
            update tax_applicability_taxes set end_date = l_end_date where id = i.id;
    end loop;

    for i in ( select id from juris_tax_app_attributes where juris_tax_applicability_id = jta_id_i and end_date is not null )
    loop
            update juris_tax_app_attributes set end_date = l_end_date where id = i.id;
    end loop;

    for i in ( select id from tran_tax_qualifiers where juris_tax_applicability_id = jta_id_i and end_date is not null )
    loop
            update tran_tax_qualifiers set end_date = l_end_date where id = i.id;
    end loop;

    update tran_tax_qualifiers set end_date = l_end_date where id = jta_id_i;

end;


PROCEDURE processCopy_Locally( jta_list_i in clob, Start_Date_i in date, entered_by_i number, processid_io out number, success_o out number) is
    type rzx is table of varchar2(32);

    rz rzx:=rzx();

    errmsg varchar2(200);
    errMsg_Out varchar2(100); -- concat(msg)
    n_Entered_By Number;
    l_juris_id Number := 0;
    vcnt number;
    vindex number := 0;
    already_extsts exception;
    l_process_id number;
    l_juris_nkid number := 0;

  begin

    success_o := 0;

    with cmList as (select ''''||replace(jta_list_i,',',''''||','||' ''')||'''' colx from dual)
    select xt.column_value.getClobVal()
    bulk collect into rz
    from xmltable((select colx from cmList)) xt;

    l_process_id := id_copy_taxability_local.nextval;

    processid_io := l_process_id;

    FOR lg in rz.first..rz.last
    loop

        for i in (
                        SELECT jta.id jta_id,
                           jta.jurisdiction_id,
                           calculation_method_id,
                           --basis_percent,
                           --recoverable_percent,
                           all_taxes_apply,
                           jta.start_date,
                           jta.end_date,
                           applicability_type_id,
                           unit_of_measure,
                           default_taxability,
                           product_tree_id,
                           commodity_id,
                           --related_charge,
                           tt.juris_tax_imposition_id,
                           --tt.tax_type,
                           --tt.start_date tax_start_date,
                           jtaa.attribute_id,
                           tq.taxability_element_id,
                           tq.logical_qualifier,
                           tq.VALUE,
                           tq.reference_group_id,
                           tq.jurisdiction_id juris_id
                      FROM juris_tax_applicabilities jta
                           LEFT JOIN tax_applicability_taxes tt
                               ON (jta.id = tt.juris_tax_applicability_id)
                           LEFT JOIN juris_tax_app_attributes jtaa
                               ON (jtaa.juris_tax_applicability_id = jta.id and attribute_id = 11)
                           LEFT JOIN tran_tax_qualifiers tq
                               ON (tq.juris_tax_applicability_id = jta.id)
                     WHERE jta.id = rz(lg)
                  )
        loop
                dbms_output.put_line ('checking existing taxabilituies that have the same criteria as below ');

                    insert into copy_taxability_local
                    select l_process_id, i.jta_id current_jta_id, jta.id existing_jta_id, 0 status
                    FROM juris_tax_applicabilities jta
                           LEFT JOIN tax_applicability_taxes tt
                               ON (jta.id = tt.juris_tax_applicability_id)
                           LEFT JOIN juris_tax_app_attributes jtaa
                               ON (jtaa.juris_tax_applicability_id = jta.id and attribute_id = 11)
                           LEFT JOIN juris_tax_impositions jti
                               ON ( jti.id = tt.juris_tax_imposition_id and jti.jurisdiction_id = jta.jurisdiction_id )
                           LEFT JOIN tran_tax_qualifiers tq
                              ON (tq.juris_tax_applicability_id = jta.id)
                  WHERE jta.jurisdiction_id = i.jurisdiction_id
                    AND jta.calculation_method_id = i.calculation_method_id
                    --AND jta.basis_percent = i.basis_percent
                    --AND jta.recoverable_percent = i.recoverable_percent
                    AND nvl(jta.all_taxes_apply, -999) = nvl(i.all_taxes_apply,-999)
                    AND jta.applicability_type_id = i.applicability_type_id

                    --AND NVL (jta.unit_of_measure, -999) = NVL (i.unit_of_measure, -999)
                    AND NVL (jta.default_taxability, -999) = NVL (i.default_taxability, -999)
                    AND NVL (jta.product_tree_id, -999) = NVL (i.product_tree_id, -999)
                    AND NVL (jta.commodity_id, -999) = NVL (i.commodity_id, -999)
                   -- AND NVL (jta.related_charge, -999) = NVL (i.related_charge, -999)
                    AND NVL (tt.juris_tax_imposition_id, -999) = NVL (i.juris_tax_imposition_id, -999)
                    --AND NVL (tt.tax_type, 'xx') = NVL (i.tax_type, 'xx')
                    AND NVL (jtaa.attribute_id, -999) = NVL (i.attribute_id, -999)
                    AND ( nvl(jti.start_date, '01-Jan-1900') <= start_date_i and ( jti.end_date is null or nvl(jti.end_date,'31-Dec-9999') > start_date_i ) )
                    AND NVL (tq.taxability_element_id, -999) = NVL (i.taxability_element_id, -999)
                    AND NVL (tq.logical_qualifier, -999) = NVL (i.logical_qualifier, -999)
                    AND NVL (tq.VALUE, -999) = NVL (i.VALUE, -999)
                    AND NVL (tq.reference_group_id, -999) = NVL (i.reference_group_id, -999)
                    AND NVL (tq.jurisdiction_id, -999) = NVL (i.juris_id, -999)
                    AND jta.start_date <= start_date_i
                    AND (jta.end_date IS NULL OR jta.end_date >= start_date_i )
                    AND jta.id != i.jta_id;

            select count(1) into vcnt from copy_taxability_local where process_id = l_process_id and current_jta_id = i.jta_id;

            if vcnt >= 1 then
                dbms_output.put_line ('before raising exception');
                raise already_extsts;
            end if;

        end loop;

    end loop;

    FOR lg in rz.first..rz.last
    loop

        select jurisdiction_nkid into l_juris_nkid from juris_tax_applicabilities where id = rz(lg);

        dbms_output.put_line('About to create the Jurisdiction_id is ' ||l_juris_nkid);

        dbms_output.put_line('About to call enddaate taxability');
        enddate_taxability( rz(lg), start_date_i );
        dbms_output.put_line('After calling enddaate taxability');
        generate_xml(jta_id_i=> rz(lg), juris_nkid=>l_juris_nkid, entered_by_i=> entered_by_i, start_date_i=> start_date_i, local_flag=>1);

        insert into copy_taxability_local values ( l_process_id, rz(lg), null, 1 );

    end loop;

    success_o := 1;

    EXCEPTION
        when already_extsts then
            rollback;
            errMsg := 'Could not copy selected taxabilities, dates overlapped.';
            errlogger.report_and_stop(-20999,errMsg);
        WHEN others THEN
            rollback;
                errMsg:='Could not copy selected taxabilities.';
                errlogger.report_and_stop(SQLCODE,SQLERRM);
  end processCopy_Locally;

PROCEDURE processCopy_Locally1( selectedJTA in clob, defStartDate in date, entered_by number) is
    type rzx is table of varchar2(32);

    rz rzx:=rzx();

    errmsg varchar2(200);
    errMsg_Out varchar2(100); -- concat(msg)
    n_Entered_By Number;
    l_juris_id Number := 0;
    vcnt number;
    vindex number := 0;
    l_juris_nkid Number := 0;

    already_extsts exception;
    l_process_id number;

  begin

    with cmList as (select ''''||replace(selectedJTA,',',''''||','||' ''')||'''' colx from dual)
    select xt.column_value.getClobVal()
    bulk collect into rz
    from xmltable((select colx from cmList)) xt;

    l_process_id := id_copy_taxability_local.nextval;

    FOR lg in rz.first..rz.last
    loop
        for i in ( select id jta_id, jurisdiction_id, calculation_method_id, basis_percent, recoverable_percent, start_date, all_taxes_apply,
                          applicability_type_id, charge_type_id,
                          unit_of_measure, default_taxability, product_tree_id, commodity_id --related_charge
                     from juris_tax_applicabilities where id = rz(lg)
                  )
        loop
                dbms_output.put_line ('checking existing taxabilituies that have the same criteria as below ');

              insert into copy_taxability_local
              select l_process_id, id, i.jta_id, 0 from juris_tax_applicabilities
              where calculation_method_id = i.calculation_method_id
                and basis_percent         = i.basis_percent
                and recoverable_percent   = i.recoverable_percent
                and nvl(all_taxes_apply, -999)       = nvl(i.all_taxes_apply,  -999)
                and applicability_type_id = i.applicability_type_id
                and nvl(charge_type_id, -999)     = nvl(i.charge_type_id, -999)
                and nvl(unit_of_measure, -999)       = nvl(i.unit_of_measure,  -999)
                and nvl(default_taxability,  -999)   = nvl(i.default_taxability, -999)
                and nvl(product_tree_id,  -999)      = nvl(i.product_tree_id,  -999)
                and nvl(commodity_id,  -999)         = nvl(i.commodity_id,  -999)
               -- and nvl(related_charge, -999)        = nvl(i.related_charge,  -999)
                and start_date <= defStartDate
                and end_date is null
                and jurisdiction_id       = i.jurisdiction_id
                and id != i.jta_id;
        end loop;

    end loop;

    select count(1) into vcnt from copy_taxability_local where process_id = l_process_id;

    if vcnt = 0
    then
        FOR lg in rz.first..rz.last
        loop
            if l_juris_id is null
            then
                select jurisdiction_nkid into l_juris_nkid from juris_tax_applicabilities where id = rz(lg);
            end if;
            generate_xml(jta_id_i=> rz(lg), juris_nkid=>l_juris_nkid, entered_by_i=> n_Entered_By, start_date_i=> defStartDate, local_flag=>1);
        end loop;
    else
        raise already_extsts;
    end if;

    EXCEPTION
        when already_extsts then
            raise_application_error(-20201, 'The dates are overlapped and could not copy the taxability');
        WHEN others THEN
            ROLLBACK;
                errMsg:='Could not copy selected taxabilities.';
                errlogger.report_and_stop(SQLCODE,SQLERRM);
  end processCopy_Locally1;

  -- Bulk Add Verifications for revisions

/******************************************************************************/
/* for prototype only
/* add verification
--modifying add_verification for CRAPP-3921
/******************************************************************************/
procedure add_verification(
    revisionId IN NUMBER,
    enteredBy IN NUMBER,
    reviewTypeId in number,
    success_o OUT NUMBER)
    IS
        l_chg_tbl NUMBER;
        l_pk NUMBER;
        l_rid NUMBER;
        l_Review_type varchar2(50);
        l_count_chg_logs NUMBER;
        l_count_fr NUMBER;
        TYPE rids IS TABLE OF INTEGER;
        l_rids rids := rids();
        l_rid_counter NUMBER := 1;
        verif_exists number:=0;
        reviewed_by_i number := enteredBy;
        review_type_id_i number := reviewTypeId;
        errmsg varchar2(200);
        l_chg_log_min_status NUMBER;
    BEGIN
        success_o := 0;


        SELECT name
        INTO l_review_type
        FROM assignment_types
        WHERE id = review_type_id_i;
        IF (l_review_type = 'Final Review') THEN
            select min(status) into l_chg_log_min_status from juris_tax_app_chg_logs where rid=revisionId;
            if ( l_chg_log_min_status =1)
                then
                FOR r IN 1..l_rids.COUNT LOOP
                /*
                SELECT COUNT(DISTINCT juris_tax_app_chg_log_id), NVL(SUM(CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END),0)
                INTO l_count_chg_logs, l_count_fr
                FROM juris_tax_app_chg_vlds
                WHERE rid = l_rids(r);
                */
                -- CRAPP-3149
                SELECT COUNT (DISTINCT juris_tax_app_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 2 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_tax_app_chg_log_id, assignment_type_id
                        FROM juris_tax_app_chg_vlds
                        WHERE rid = l_rids(r)
                    );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE juris_tax_app_revisions
                    SET summ_ass_status = 5
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
            else
            --Raise_Application_Error (-20400, 'Final Review is no longer possible due to a recent change to the revision, please refresh the page to see this change');
            RAISE errnums.recs_unlocked_in_mid_of_pub;
            end if;
        -- Changes for "Test in Staging", If all changes have "Test in Staging", set summ_ass_status = 2, that way these records will get pulled into ETL.
        ELSIF (l_review_type = 'Test in Staging') THEN

          FOR ii IN (select id from juris_tax_app_chg_logs lg where rid = revisionid) LOOP

            UPDATE juris_tax_app_chg_logs lg
            SET status = 1
            WHERE id = ii.id
            RETURNING rid into l_rid;

            IF (NVL(l_rids.PRIOR(l_rid_counter),-1) != l_rid) THEN
                l_rids.extend;
                l_rids(l_rid_counter) := l_rid;
                l_rid_counter := l_rid_counter+1;
            END IF;

            INSERT INTO juris_tax_app_chg_vlds(assigned_user_id, signoff_date, juris_tax_app_chg_log_id, assignment_type_id, assigned_by, rid)
            VALUES (reviewed_by_i, SYSTIMESTAMP, ii.id, review_type_id_i, reviewed_by_i, l_rid);
        END LOOP;

            FOR r IN 1..l_rids.COUNT LOOP

                SELECT COUNT (DISTINCT juris_tax_app_chg_log_id),
                       NVL (SUM (CASE WHEN assignment_type_id = 7 THEN 1 ELSE 0 END), 0)
                INTO l_count_chg_logs, l_count_fr
                FROM (SELECT DISTINCT juris_tax_app_chg_log_id, assignment_type_id
                        FROM juris_tax_app_chg_vlds
                        WHERE rid = l_rids(r)
                );
                IF (l_count_chg_logs > 0 AND l_count_chg_logs = l_count_fr) THEN
                    UPDATE juris_tax_app_revisions
                    SET summ_ass_status = 2
                    WHERE id = l_rids(r);
                END IF;
            END LOOP;
        END IF;

        success_o := 1;

    EXCEPTION
        WHEN errnums.recs_unlocked_in_mid_of_pub
        THEN
        errlogger.report_and_stop (errnums.en_recs_unlocked_in_mid_of_pub,'Final Review is no longer possible due to a recent change to the revision.');


        WHEN others THEN
            rollback;
                errMsg:='Could not add taxability verifications.';
                errlogger.report_and_stop(SQLCODE,SQLERRM);

end add_verification;




  -- Bulk Add Verifications for revisions

-- Start changes for CRAPP-2800

PROCEDURE add_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            reviewtypeid   IN     NUMBER,
                            success_o         OUT NUMBER)
IS
    l_chg_tbl          NUMBER;
    l_pk               NUMBER;
    l_rid              NUMBER;
    l_review_type      VARCHAR2 (50);
    l_count_chg_logs   NUMBER;
    l_count_fr         NUMBER;

    TYPE rids IS TABLE OF INTEGER;

    l_rids             rids := rids ();
    l_rid_counter      NUMBER := 1;
    verif_exists       NUMBER := 0;
    reviewed_by_i      NUMBER := enteredby;
    review_type_id_i   NUMBER := reviewtypeid;
    errmsg             VARCHAR2 (200);
    revisions_list     numtabletype;
    rid_tt             rids := rids ();
    lsumm_ass_status   NUMBER := 0;
    lstatus number;
    laction_log_url  varchar2(100);
    lreferrer varchar2(4000);
    lnkid number;
    lprocess_id number := crapp_admin.pk_action_log_process_id.nextval;
BEGIN
    revisions_list := str2tbl (revisionids);

    SELECT DISTINCT COLUMN_VALUE
      BULK COLLECT INTO rid_tt
      FROM TABLE (revisions_list);

    success_o := 0;

    IF review_type_id_i = 2
    THEN
        lsumm_ass_status := 5;
    ELSIF review_type_id_i = 7
    THEN
        lsumm_ass_status := 2;
    ELSIF review_type_id_i IN (4, 5)
    THEN
        lsumm_ass_status := 4;
    END IF;

    FOR i IN 1 .. rid_tt.COUNT
    LOOP

        -- Checking to make sure, its not a published revision.
        select status, nkid into lstatus, lnkid from juris_tax_app_revisions where id = rid_tt (i);

        if lstatus !=2
        then
            INSERT INTO juris_tax_app_chg_vlds (assigned_user_id,
                                                signoff_date,
                                                juris_tax_app_chg_log_id,
                                                assignment_type_id,
                                                assigned_by,
                                                rid)
                SELECT reviewed_by_i,
                       SYSTIMESTAMP,
                       id,
                       review_type_id_i,
                       reviewed_by_i,
                       rid
                  FROM juris_tax_app_chg_logs a
                 WHERE     rid = rid_tt (i)
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM juris_tax_app_chg_vlds b
                                 WHERE     a.id = b.juris_tax_app_chg_log_id
                                       AND b.assignment_type_id =
                                               review_type_id_i
                                       AND b.assigned_by = reviewed_by_i);

            UPDATE juris_tax_app_chg_logs
               SET status = 1
             WHERE rid = rid_tt (i) AND status = 0;

            UPDATE juris_tax_app_revisions
               SET summ_ass_status = lsumm_ass_status, ready_for_staging = 1
             WHERE id = rid_tt (i);
        else
            select url into laction_log_url from action_log_url where entity = 'TAXABILITY_BULK_VERIFICATION';

            laction_log_url := replace (replace(laction_log_url, 'nkid', lnkid), 'rid', rid_tt (i) );
            log_action_log_error ('/taxability/addbulkverification' , -2918, laction_log_url||chr(10)||' This revision has been already published.', lprocess_id);
        end if;
    END LOOP;

    success_o := 1;
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        success_o := 0;
        errmsg := 'Could not add taxability verifications.';
        errlogger.report_and_stop (SQLCODE, SQLERRM);
END add_bulk_verification;

PROCEDURE remove_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            success_o         OUT NUMBER)
IS
    l_chg_tbl          NUMBER;
    l_pk               NUMBER;
    l_rid              NUMBER;
    l_review_type      VARCHAR2 (50);
    l_count_chg_logs   NUMBER;
    l_count_fr         NUMBER;

    TYPE rids IS TABLE OF INTEGER;

    l_rids             rids := rids ();
    l_rid_counter      NUMBER := 1;
    verif_exists       NUMBER := 0;
    reviewed_by_i      NUMBER := enteredby;
    --review_type_id_i   NUMBER := reviewtypeid;
    errmsg             VARCHAR2 (200);
    revisions_list     numtabletype;
    rid_tt             rids := rids ();
    lsumm_ass_status   NUMBER := 0;
    lnkid number;
    lcnt number;
    lstatus number;
    laction_log_url varchar2(4000);
    lprocess_id number;
BEGIN
    revisions_list := str2tbl (revisionids);

    SELECT DISTINCT COLUMN_VALUE
      BULK COLLECT INTO rid_tt
      FROM TABLE (revisions_list);

    lprocess_id := crapp_admin.pk_action_log_process_id.nextval;

    success_o := 0;

    FOR i IN 1 .. rid_tt.COUNT
    LOOP

        select nkid, status into lnkid, lstatus from juris_tax_app_revisions where id = rid_tt(i);

        select count(1) into lcnt from juris_tax_app_revisions where nkid = lnkid and id > rid_tt(i);

        if lcnt = 0 and lstatus = 1
        then
            delete from juris_tax_app_chg_vlds where rid = rid_tt(i);

            UPDATE juris_tax_app_chg_logs
               SET status = 0
             WHERE rid = rid_tt (i) AND status = 1;

            UPDATE juris_tax_app_revisions
               SET summ_ass_status = 0, ready_for_staging = 0
             WHERE id = rid_tt (i);
        else
            select url into laction_log_url from action_log_url where entity = 'TAXABILITY_BULK_VERIFICATION';

            laction_log_url := replace (replace(laction_log_url, 'nkid', lnkid), 'rid', rid_tt (i) );
            log_action_log_error ('/taxability/removebulkverification' , -2918, laction_log_url||chr(10)||' The verifications on this revision could not be deleted, as it is already published.',
                    lprocess_id);
        end if;

    END LOOP;

    success_o := 1;
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        success_o := 0;
        errmsg := 'Could not remove taxability verifications.';
        errlogger.report_and_stop (SQLCODE, SQLERRM);
END remove_bulk_verification;

-- End changes for CRAPP-2800
-- Start changes for CRAPP-2800

PROCEDURE add_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            reviewtypeid   IN     NUMBER,
                            success_o         OUT NUMBER)
IS
    l_chg_tbl          NUMBER;
    l_pk               NUMBER;
    l_rid              NUMBER;
    l_review_type      VARCHAR2 (50);
    l_count_chg_logs   NUMBER;
    l_count_fr         NUMBER;

    TYPE rids IS TABLE OF INTEGER;

    l_rids             rids := rids ();
    l_rid_counter      NUMBER := 1;
    verif_exists       NUMBER := 0;
    reviewed_by_i      NUMBER := enteredby;
    review_type_id_i   NUMBER := reviewtypeid;
    errmsg             VARCHAR2 (200);
    revisions_list     numtabletype;
    rid_tt             rids := rids ();
    lsumm_ass_status   NUMBER := 0;
    lstatus number;
    laction_log_url  varchar2(100);
    lreferrer varchar2(4000);
    lnkid number;
    lprocess_id number := crapp_admin.pk_action_log_process_id.nextval;
BEGIN
    revisions_list := str2tbl (revisionids);

    SELECT DISTINCT COLUMN_VALUE
      BULK COLLECT INTO rid_tt
      FROM TABLE (revisions_list);

    success_o := 0;

    IF review_type_id_i = 2
    THEN
        lsumm_ass_status := 5;
    ELSIF review_type_id_i = 7
    THEN
        lsumm_ass_status := 2;
    ELSIF review_type_id_i IN (4, 5)
    THEN
        lsumm_ass_status := 4;
    END IF;

    FOR i IN 1 .. rid_tt.COUNT
    LOOP

        -- Checking to make sure, its not a published revision.
        select status, nkid into lstatus, lnkid from juris_tax_app_revisions where id = rid_tt (i);

        if lstatus !=2
        then
            INSERT INTO juris_tax_app_chg_vlds (assigned_user_id,
                                                signoff_date,
                                                juris_tax_app_chg_log_id,
                                                assignment_type_id,
                                                assigned_by,
                                                rid)
                SELECT reviewed_by_i,
                       SYSTIMESTAMP,
                       id,
                       review_type_id_i,
                       reviewed_by_i,
                       rid
                  FROM juris_tax_app_chg_logs a
                 WHERE     rid = rid_tt (i)
                       AND NOT EXISTS
                               (SELECT 1
                                  FROM juris_tax_app_chg_vlds b
                                 WHERE     a.id = b.juris_tax_app_chg_log_id
                                       AND b.assignment_type_id =
                                               review_type_id_i
                                       AND b.assigned_by = reviewed_by_i);

            UPDATE juris_tax_app_chg_logs
               SET status = 1
             WHERE rid = rid_tt (i) AND status = 0;

            UPDATE juris_tax_app_revisions
               SET summ_ass_status = lsumm_ass_status, ready_for_staging = 1
             WHERE id = rid_tt (i);
        else
            select url into laction_log_url from action_log_url where entity = 'TAXABILITY_BULK_VERIFICATION';

            laction_log_url := replace (replace(laction_log_url, 'nkid', lnkid), 'rid', rid_tt (i) );
            log_action_log_error ('/taxability/addbulkverification' , -2918, laction_log_url||chr(10)||' This revision has been already published.', lprocess_id);
        end if;
    END LOOP;

    success_o := 1;
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        success_o := 0;
        errmsg := 'Could not add taxability verifications.';
        errlogger.report_and_stop (SQLCODE, SQLERRM);
END add_bulk_verification;

PROCEDURE remove_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            success_o         OUT NUMBER)
IS
    l_chg_tbl          NUMBER;
    l_pk               NUMBER;
    l_rid              NUMBER;
    l_review_type      VARCHAR2 (50);
    l_count_chg_logs   NUMBER;
    l_count_fr         NUMBER;

    TYPE rids IS TABLE OF INTEGER;

    l_rids             rids := rids ();
    l_rid_counter      NUMBER := 1;
    verif_exists       NUMBER := 0;
    reviewed_by_i      NUMBER := enteredby;
    --review_type_id_i   NUMBER := reviewtypeid;
    errmsg             VARCHAR2 (200);
    revisions_list     numtabletype;
    rid_tt             rids := rids ();
    lsumm_ass_status   NUMBER := 0;
    lnkid number;
    lcnt number;
    lstatus number;
    laction_log_url varchar2(4000);
    lprocess_id number;
BEGIN
    revisions_list := str2tbl (revisionids);

    SELECT DISTINCT COLUMN_VALUE
      BULK COLLECT INTO rid_tt
      FROM TABLE (revisions_list);

    lprocess_id := crapp_admin.pk_action_log_process_id.nextval;

    success_o := 0;

    FOR i IN 1 .. rid_tt.COUNT
    LOOP

        select nkid, status into lnkid, lstatus from juris_tax_app_revisions where id = rid_tt(i);

        select count(1) into lcnt from juris_tax_app_revisions where nkid = lnkid and id > rid_tt(i);

        if lcnt = 0 and lstatus = 1
        then
            delete from juris_tax_app_chg_vlds where rid = rid_tt(i);

            UPDATE juris_tax_app_chg_logs
               SET status = 0
             WHERE rid = rid_tt (i) AND status = 1;

            UPDATE juris_tax_app_revisions
               SET summ_ass_status = 0, ready_for_staging = 0
             WHERE id = rid_tt (i);
        else
            select url into laction_log_url from action_log_url where entity = 'TAXABILITY_BULK_VERIFICATION';

            laction_log_url := replace (replace(laction_log_url, 'nkid', lnkid), 'rid', rid_tt (i) );
            log_action_log_error ('/taxability/removebulkverification' , -2918, laction_log_url||chr(10)||' The verifications on this revision could not be deleted, as it is already published.',
                    lprocess_id);
        end if;

    END LOOP;

    success_o := 1;
EXCEPTION
    WHEN OTHERS
    THEN
        ROLLBACK;
        success_o := 0;
        errmsg := 'Could not remove taxability verifications.';
        errlogger.report_and_stop (SQLCODE, SQLERRM);
END remove_bulk_verification;
-- End changes for CRAPP-2800
END taxability;
/