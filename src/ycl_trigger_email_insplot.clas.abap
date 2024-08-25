CLASS ycl_trigger_email_insplot DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: gt_rej TYPE TABLE OF zi_insp_lot_rej,
          gs_rej LIKE LINE OF gt_rej.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .

    CONSTANTS : default_inventory_id          TYPE c LENGTH 1 VALUE '1',
                wait_time_in_seconds          TYPE i VALUE 5,
                selection_name                TYPE c LENGTH 8   VALUE 'INSPLOT',
                selection_description         TYPE c LENGTH 255 VALUE 'Lot Data',
                application_log_object_name   TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_ALOG_01',
                application_log_sub_obj1_name TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_ALOGS_01'.


    METHODS:
      send_mail
        IMPORTING
          xt_rej  LIKE gt_rej
          im_date TYPE sy-datum
          im_mode TYPE char10.
    "RETURNING VALUE(rv_mail_stat) TYPE char120.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_TRIGGER_EMAIL_INSPLOT IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.

    "Return the supported selection parameters here
    et_parameter_def = VALUE #(
      ( selname  = selection_name
        kind     = if_apj_dt_exec_object=>parameter
        datatype = 'C'
        length   =  8
        param_text = selection_description
        changeable_ind = abap_true )
    ).

    "Return the default parameters values here
    et_parameter_val = VALUE #(
      ( selname = selection_name
        kind = if_apj_dt_exec_object=>parameter
        sign = 'I'
        option = 'EQ'
        low = sy-datum )
    ).

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.

    DATA:
      is_date TYPE sy-datum.

    is_date = sy-datum.
    me->send_mail(
      EXPORTING
        xt_rej       = gt_rej
        im_date      = is_date
        im_mode      = 'BCG'
    ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    DATA  et_parameters TYPE if_apj_rt_exec_object=>tt_templ_val  .

    et_parameters = VALUE #(
        ( selname = selection_name
          kind = if_apj_dt_exec_object=>parameter
          sign = 'I'
          option = 'EQ'
          low = sy-datum )
      ).

    TRY.

        if_apj_rt_exec_object~execute( it_parameters = et_parameters ).
        out->write( |Finished| ).

      CATCH cx_root INTO DATA(job_scheduling_exception).

    ENDTRY.


  ENDMETHOD.


  METHOD send_mail.

    DATA: ct_rej TYPE TABLE OF zi_insp_lot_rej,
          cs_rej LIKE LINE OF gt_rej.

    DATA:
      lv_docnum         TYPE char15,
      lv_refdoc         TYPE char30,
      lv_eobj           TYPE char15,
      lv_date           TYPE char10,
      lv_decision       TYPE char20,
      lv_desc_date      TYPE char10,
      lv_post_date      TYPE char10,
      lv_email_add(512) TYPE c.

    DATA: lt_done TYPE TABLE OF yemail_triggered,
          ls_done TYPE yemail_triggered.

    DATA : rt_lot TYPE RANGE OF zi_insp_lot_rej-InspectionLot,
           rs_lot LIKE LINE OF  rt_lot.

    IF im_mode NE 'BCG'.
      IF xt_rej[] IS NOT INITIAL.

        LOOP AT xt_rej INTO DATA(xs_rej).

          rs_lot-low    = xs_rej-InspectionLot.
          rs_lot-high   = '' .
          rs_lot-option = 'EQ' .
          rs_lot-sign   = 'I' .
          APPEND rs_lot TO rt_lot.

          CLEAR: xs_rej.
        ENDLOOP.

      ENDIF.

      SELECT * FROM zi_insp_lot_rej
               WHERE InspectionLot IN @rt_lot AND
               InspectionLotUsageDecisionCode IN ( 'A1', 'R0' )
               INTO TABLE @DATA(gt_lot).
    ELSE.

      lv_date = im_date.
      SELECT * FROM zi_insp_lot_rej
               WHERE InspectionLotUsageDecidedOn = @lv_date AND
                     InspectionLotUsageDecisionCode IN ( 'A1', 'R0' )
               INTO TABLE @gt_lot.

    ENDIF.

    IF gt_lot[] IS NOT INITIAL.

      SELECT * FROM yemail_triggered
                     FOR ALL ENTRIES IN @gt_lot
                    WHERE documentnumber = @gt_lot-InspectionLot
                    INTO TABLE @DATA(gt_done).

      SELECT * FROM zi_grn_detail
               FOR ALL ENTRIES IN @gt_lot
               WHERE MaterialDocument = @gt_lot-MaterialDocument AND MaterialDocumentYear = @gt_lot-MaterialDocumentYear
               INTO TABLE @DATA(gt_matodc).

    ENDIF.

    IF gt_lot[] IS NOT INITIAL.

      LOOP AT gt_lot INTO DATA(gs_lot) WHERE InspLotQtyToBlocked IS NOT INITIAL.

        READ TABLE gt_matodc INTO DATA(gs_matdoc) WITH KEY
                                                  MaterialDocument = gs_lot-MaterialDocument
                                                  MaterialDocumentYear = gs_lot-MaterialDocumentYear.
        IF sy-subrc EQ 0.
          lv_refdoc = gs_matdoc-ReferenceDocument.
        ENDIF.

        READ TABLE gt_done INTO DATA(gs_done) WITH KEY documentnumber = gs_lot-InspectionLot.
        IF sy-subrc NE 0.

          SELECT * FROM zi_insp_lot_email WHERE lot_type = @gs_lot-InspectionLotType AND
                                                plant    = @gs_lot-Plant
                                                INTO TABLE @DATA(lt_email).
        ENDIF.

        IF lt_email[] IS NOT INITIAL.

          TRY.

              lv_docnum   = gs_lot-InspectionLot.
              lv_desc_date = gs_lot-InspectionLotUsageDecidedOn+6(2) && '.'
                             &&  gs_lot-InspectionLotUsageDecidedOn+4(2) && '.'
                             &&  gs_lot-InspectionLotUsageDecidedOn+0(4).

              CLEAR: lv_decision.
              IF gs_lot-InspectionLotUsageDecisionCode+0(1) EQ 'A'.
                lv_decision = 'Accepted'.
              ELSEIF gs_lot-InspectionLotUsageDecisionCode+0(1) EQ 'R'.
                lv_decision = 'Rejected'.
              ENDIF.

              DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).

              CLEAR: lv_email_add.
              lv_email_add = gs_matdoc-supll_email.
              IF lv_email_add IS NOT INITIAL.
                lo_mail->add_recipient( lv_email_add ).
              ENDIF.

              LOOP AT lt_email INTO DATA(ls_email).

                lv_email_add = ls_email-emailid.
                IF ls_email-to_cc = 'TO'.

                  IF gs_matdoc-supll_email IS INITIAL.
                    lo_mail->add_recipient( lv_email_add ).
                  ENDIF.

                ELSEIF ls_email-to_cc = 'CC'.

                  lo_mail->add_recipient( iv_address = lv_email_add iv_copy = cl_bcs_mail_message=>cc ).

                ENDIF.

              ENDLOOP.

              lo_mail->set_subject( |Quality alert for Inspection Lot - | && lv_docnum ).


              SELECT
                def~InspectionLot,
                def~Material,
                def~Plant,
                def~DefectCodeGroup,
                def~DefectCode,
                def~DefectiveQuantity,
                def~DefectText,
                deftxt~DefectCodeText
                From I_defect as def
                INNER JOIN I_DefectCodeText as deftxt
                on deftxt~DefectCode = def~DefectCode AND deftxt~language = 'E'
                WHERE def~InspectionLot = @lv_docnum
                INTO TABLE @DATA(lt_defcode).


              lv_post_date = gs_matdoc-PostingDate+6(2) && '.' && gs_matdoc-PostingDate+4(2) && '.'
                             && gs_matdoc-PostingDate+0(4).

              DATA:
                ls_str_def_code TYPE string.

              DATA(lv_mail_body) = '<p>Dear Sir,</p>'
              && '<p>Please find the below status of usage desicion taken by quality team</p>'
              && '<p>Requested you to please proceed for required action</p>'.

              DATA(lv_body_data) = |<p></p>|
              && |<p>Lot Number: { lv_docnum } </p>|
              && |<p>Vendor Code: { gs_matdoc-Supplier } </p>|
              && |<p>Vendor Name: { gs_matdoc-SupplierName } </p>|
              && |<p>Purchase Order: { gs_lot-PurchasingDocument } </p>|
              && |<p>Material Document: { gs_lot-MaterialDocument } </p>|
              && |<p>Material: { gs_lot-Material } </p>|
              && |<p>Material Description: { gs_lot-InspectionLotObjectText } </p>|
              && |<p>Posting Date: { lv_post_date } </p>|
              && |<p>Delivery Number: { lv_refdoc } </p>|
              && |<p>Decision Date: { lv_desc_date } </p>|
*             && |<p>Usage Decision: { lv_decision } </p>|
              && |<p>Lot Qty: { gs_lot-InspectionLotQuantity } </p>|
              && |<p>Accepted Qty: { gs_lot-InspLotQtyToFree } </p>|
              && |<p>Rejected Qty: { gs_lot-InspLotQtyToBlocked } </p>|.

*              if lt_defcode[] is NOT INITIAL.
*               loop at lt_defcode INTO DATA(ls_defcode).
*
*                ls_str_def_code = ls_str_def_code
*                 && |<p>Defect Code: { ls_defcode-DefectCode } </p>|
*                 && |<p>Defect Code description: { ls_defcode-DefectCodeText } </p>|
*                 && |<p>Defective Qty.: { ls_defcode-DefectText } </p>|.
*
*               ENDLOOP.
*              ENDIF.
*

*              lv_body_data = lv_body_data && ls_str_def_code && |<p></p>|
*              && '<br>'.

              DATA(lv_footer) = '<B>Regards,</B>' && '<br>'
              && 'Quality Assurance' && '<br>'
              && 'JUMPS Auto Industries Limited' && '<br>'
              && '<p>**** This is an auto generated Notification by SAP, please do not reply****</p>'.
*
              DATA(lv_final_mail_body)  = lv_mail_body && lv_body_data && lv_footer.

              lo_mail->set_main( cl_bcs_mail_textpart=>create_text_html( lv_final_mail_body ) ).

              "*CATCH cx_web_http_conversion_failed.
              lo_mail->send( IMPORTING et_status = DATA(lt_status) ).

              IF sy-subrc EQ 0.
                CLEAR: ls_done.
                ls_done-documentnumber = gs_lot-InspectionLot.
                ls_done-email_done     = abap_true.
                ls_done-email_obj      = 'INSPLOT'.
                ls_done-email_date     = sy-datum.
                ls_done-email_time     = sy-uzeit.
                APPEND ls_done TO lt_done.
              ENDIF.

            CATCH cx_bcs_mail INTO DATA(lx_mail).

              "handle exceptions here
            CATCH cx_web_http_conversion_failed INTO DATA(lx_mail_con).

          ENDTRY.

        ENDIF.

        CLEAR: gs_lot, lt_email[].
      ENDLOOP.

      IF lt_done[] IS NOT INITIAL.
        MODIFY yemail_triggered FROM TABLE @lt_done.
      ENDIF.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
