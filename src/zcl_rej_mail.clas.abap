CLASS zcl_rej_mail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: gt_rej TYPE TABLE OF zi_insp_lot_rej,
          gs_rej LIKE LINE OF gt_rej.

    METHODS:
      get_insp_lot_data
        IMPORTING
                  im_date        TYPE sy-datum
                  im_action      TYPE char10
        RETURNING VALUE(et_item) LIKE gt_rej,

      get_data_send_mail
        IMPORTING
                  xt_rej              LIKE gt_rej
                  im_date             TYPE sy-datum
                  im_mode             TYPE char10
                  im_action           TYPE char10
        RETURNING VALUE(rv_mail_stat) TYPE char120.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_REJ_MAIL IMPLEMENTATION.


  METHOD get_data_send_mail.

    DATA: lo_mail TYPE REF TO ycl_trigger_email_insplot.

    CREATE OBJECT lo_mail.

    lo_mail->send_mail(
      xt_rej  = xt_rej
      im_date = im_date
      im_mode = im_mode
    ).

    if sy-subrc eq 0.
     rv_mail_stat = 'Mail sent successfully'.
    ENDIF.

  ENDMETHOD.


  METHOD get_insp_lot_data.

    DATA: lv_index TYPE sy-tabix.

    DATA(lv_date) = im_date.

    SELECT * FROM zi_insp_lot_rej
             WHERE InspectionLotUsageDecidedOn = @lv_date  AND
                   InspectionLotUsageDecisionCode IN ( 'A1', 'R0' )
             INTO TABLE @DATA(gt_lot).

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

    LOOP AT gt_lot ASSIGNING FIELD-SYMBOL(<gs_lot>).

      IF <gs_lot> IS ASSIGNED.

        lv_index = sy-tabix.

        READ TABLE gt_done INTO DATA(gs_done) WITH KEY documentnumber = <gs_lot>-InspectionLot.
        IF sy-subrc EQ 0.

          DELETE gt_lot INDEX lv_index.

        ELSE.

          READ TABLE gt_matodc INTO DATA(gs_matdoc) WITH KEY
                                                    MaterialDocument = <gs_lot>-MaterialDocument
                                                    MaterialDocumentYear = <gs_lot>-MaterialDocumentYear.
          IF sy-subrc EQ 0.
            <gs_lot>-DeliveryDocument = gs_matdoc-ReferenceDocument.
          ENDIF.

        ENDIF.

      ENDIF.

    ENDLOOP.

    IF gt_lot[] IS NOT INITIAL.
      et_item[] = gt_lot[].
    ENDIF.

  ENDMETHOD.
ENDCLASS.
