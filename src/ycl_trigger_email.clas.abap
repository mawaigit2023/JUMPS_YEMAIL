CLASS ycl_trigger_email DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS:
      send_mail
        IMPORTING
          im_docnum TYPE char15
          im_eobj   TYPE char15.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_TRIGGER_EMAIL IMPLEMENTATION.


  METHOD send_mail.

    DATA:
      lv_docnum         TYPE char15,
      lv_eobj           TYPE char15,
      lv_date           TYPE char10,
      lv_email_add(512) TYPE c.

    SELECT * FROM zi_ship_email INTO TABLE @DATA(lt_email).

    IF lt_email[] IS NOT INITIAL.

      TRY.

          lv_docnum = im_docnum.
          lv_date   = sy-datum+6(2) && '.' && sy-datum+4(2) && '.' && sy-datum+0(4).

          DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).


          LOOP AT lt_email INTO DATA(ls_email).

            lv_email_add = ls_email-emailid.

            IF ls_email-to_cc = 'TO'.
              lo_mail->add_recipient( lv_email_add ).
            ELSEIF ls_email-to_cc = 'CC'.
              lo_mail->add_recipient( iv_address = lv_email_add iv_copy = cl_bcs_mail_message=>cc ).
            ENDIF.

          ENDLOOP.

          lo_mail->set_subject( 'New delivery created for billing' ).

          DATA(lv_mail_body) = '<p>Dear Sir,</p>'
          && '<p>A new delivery document created and ready for billing</p>'
          && '<p>Requested you to please proceed for the same</p>'.

          DATA(lv_body_data) = |<p></p>|
          && |<p>Delivery dcouement Number: { lv_docnum } </p>|
          && |<p>Creation Date: { lv_date } </p>|
          && |<p></p>|.

          DATA(lv_footer) = '<p>Regards,</p>'
          && '<p>SAP System</p>'
          && '<p>**** This is an auto generated Notification by SAP, please do not reply****</p>'.

          DATA(lv_final_mail_body)  = lv_mail_body && lv_body_data && lv_footer.

          lo_mail->set_main( cl_bcs_mail_textpart=>create_text_html( lv_final_mail_body ) ).

          "*CATCH cx_web_http_conversion_failed.
          lo_mail->send( IMPORTING et_status = DATA(lt_status) ).

        CATCH cx_bcs_mail INTO DATA(lx_mail).
          "handle exceptions here

      ENDTRY.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
