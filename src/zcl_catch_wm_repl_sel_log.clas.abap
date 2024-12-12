CLASS zcl_catch_wm_repl_sel_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF constants,
        object     TYPE balobj_d VALUE 'ZINHAALBEWEGING',
        sub_object TYPE balsubobj VALUE 'ZINH_CREATE_DOSSIER', ##TODO "Setup for multiple subobjects
        BEGIN OF msg,
          id TYPE symsgid VALUE 'ZCM_CATCH_WM_REPL_SE',
          BEGIN OF nr,
            cd_start TYPE symsgno VALUE '000',
            cd_log_handle TYPE symsgno VALUE '001',
            cd_start_order TYPE symsgno VALUE '002',
            cd_created_order TYPE symsgno VALUE '003',
            cd_start_notif TYPE symsgno VALUE '004',
            cd_created_notif TYPE symsgno VALUE '005',
            cd_stop TYPE symsgno VALUE '006',
            cd_update_log_handle TYPE symsgno VALUE '007',
            mandatory_parameter TYPE symsgno VALUE '008',
            cd_start_input_valid TYPE symsgno VALUE '009',
            cd_input_invalid TYPE symsgno VALUE '010',
            cd_input_valid TYPE symsgno VALUE '011',
            cd_has_notif TYPE symsgno VALUE '012',
            cd_has_order TYPE symsgno VALUE '013',
            cd_update_watermeter TYPE symsgno VALUE '014',
            cd_parameters TYPE symsgno VALUE '015',
            cd_has_no_notif TYPE symsgno VALUE '016',
            cd_has_no_order TYPE symsgno VALUE '017',
            cd_job_active TYPE symsgno VALUE '018',
          END OF nr,
        END OF msg,
      END OF constants.

    METHODS:
      constructor,
      log_message IMPORTING !iv_id    TYPE symsgid DEFAULT constants-msg-id
                            !iv_type  TYPE symsgty DEFAULT zcl_error=>gcs_message_type-info
                            !iv_nr    TYPE symsgno
                            !iv_v1    TYPE any OPTIONAL
                            !iv_v2    TYPE any OPTIONAL
                            !iv_v3    TYPE any OPTIONAL
                            !iv_v4    TYPE any OPTIONAL,
      log_messages IMPORTING messages TYPE BAPIRETTAB.
PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
        application_log TYPE REF TO zcl_application_log.
ENDCLASS.



CLASS zcl_catch_wm_repl_sel_log IMPLEMENTATION.
  METHOD constructor.
    application_log = NEW zcl_application_log( iv_object    = constants-object
                                               iv_subobject = constants-sub_object ).
    application_log->create_log( ).
  ENDMETHOD.

  METHOD log_message.
    application_log->add_message( VALUE #( id         = iv_id
                                           type       = iv_type
                                           number     = iv_nr
                                           message_v1 = iv_v1
                                           message_v2 = iv_v2
                                           message_v3 = iv_v3
                                           message_v4 = iv_v4 ) ).
    application_log->save_log( ).
  ENDMETHOD.

  METHOD log_messages.
    LOOP AT messages INTO DATA(message).
      log_message( iv_id     = message-id
                   iv_type   = message-type
                   iv_nr     = message-number
                   iv_v1     = message-message_v1
                   iv_v2     = message-message_v2
                   iv_v3     = message-message_v3
                   iv_v4     = message-message_v4 ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
