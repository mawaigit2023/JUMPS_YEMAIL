CLASS zcl_http_lot_rej_mail DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_LOT_REJ_MAIL IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA: lv_action1 TYPE char10,
          lv_date    TYPE char10,
          iv_date    TYPE sy-datum,
          gt_data    TYPE TABLE OF zi_insp_lot_rej,
          gs_data    TYPE zi_insp_lot_rej.

    DATA: lo_client TYPE REF TO zcl_rej_mail.

    DATA: miw_string TYPE string.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action1 = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_date) WITH KEY name = 'date'.
    IF sy-subrc EQ 0.
      lv_date = ls_date-value. "20-09-2023
      iv_date = lv_date+6(4) && lv_date+3(2) && lv_date+0(2).
    ENDIF.

    "********Creation of object**************
    CREATE OBJECT lo_client.
    CLEAR: miw_string.

    IF lv_action1 = 'getdata'.

      gt_data[]  = lo_client->get_insp_lot_data( im_date = iv_date im_action = lv_action1 ).

      DATA(json) = /ui2/cl_json=>serialize(
        data             = gt_data[]
        compress         = abap_true
        assoc_arrays     = abap_true
        assoc_arrays_opt = abap_true
        pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
        ).

      miw_string = json .

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'sendmail'.

      "Get inbound data
      DATA(lv_request_body) = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_data
                   ).

      DATA(lv_mail_stat) = lo_client->get_data_send_mail(
                             xt_rej    = gt_data
                             im_date   = iv_date
                             im_mode   = 'NBG'
                             im_action = lv_action1
                           ).

      miw_string = lv_mail_stat.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.
