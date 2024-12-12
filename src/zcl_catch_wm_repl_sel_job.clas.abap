CLASS zcl_catch_wm_repl_sel_job DEFINITION
  PUBLIC

  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS:
        BEGIN OF constants,
            job_template TYPE cl_apj_rt_api=>ty_template_name VALUE 'ZJT_CATCH_WRS_CREATE_DOSSIER',
            BEGIN OF application_log,
                object TYPE if_bali_object_handler=>ty_object VALUE zcl_catch_wm_repl_sel_log=>constants-object,
                subobject TYPE if_bali_object_handler=>ty_object VALUE zcl_catch_wm_repl_sel_log=>constants-sub_object,
            END OF application_log,
            BEGIN OF parameter,
                input TYPE string VALUE 'INPUT',
            END OF parameter,
        END OF constants.

    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES if_oo_adt_classrun.

    METHODS constructor.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS create_order IMPORTING !parameter    TYPE zr_catch_wrs_job
                                    notification_id TYPE zr_catch_wm_repl_sel-Notification
                         RETURNING VALUE(result) TYPE zr_catch_wm_repl_sel-OrderID
                         RAISING cx_apj_rt_content.

    METHODS create_notification IMPORTING !parameter    TYPE zr_catch_wrs_job
                                RETURNING VALUE(result) TYPE zr_catch_wm_repl_sel-Notification
                                RAISING cx_apj_rt_content.

    METHODS valid_inputs IMPORTING !parameter    TYPE zr_catch_wrs_job
                         RETURNING VALUE(result) TYPE abap_boolean
                         RAISING cx_apj_rt_content.

    METHODS: log_message IMPORTING !id TYPE symsgid DEFAULT zcl_catch_wm_repl_sel_log=>constants-msg-id
                                  !nr TYPE symsgno
                                  ty  TYPE symsgty DEFAULT zcl_error=>gcs_message_type-info
                                  v1  TYPE any     OPTIONAL
                                  v2  TYPE any     OPTIONAL
                                  v3  TYPE any     OPTIONAL
                                  v4  TYPE any     OPTIONAL,
            log_behv_message IMPORTING message TYPE REF TO if_abap_behv_message,
            log_messages IMPORTING messages TYPE BAPIRETTAB.

    METHODS update_watermeter_status IMPORTING !parameter TYPE zr_catch_wrs_job
                                     RAISING cx_apj_rt_content.

    METHODS update_job_log IMPORTING !parameter TYPE zr_catch_wrs_job
                           RAISING cx_apj_rt_content.

    DATA out TYPE REF TO if_oo_adt_classrun_out.
    DATA log TYPE REF TO zcl_application_log.
    DATA log_handle TYPE balloghndl.

ENDCLASS.



CLASS ZCL_CATCH_WM_REPL_SEL_JOB IMPLEMENTATION.


  METHOD constructor.
    me->log = NEW zcl_application_log( iv_object     = constants-application_log-object
                                       iv_subobject  = constants-application_log-subobject ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.

    " Return the supported selection parameters here
    et_parameter_def = VALUE #(
    ( selname = constants-parameter-input
        kind = if_apj_dt_exec_object=>parameter
        datatype = 'C'
        length =  32
        param_text = 'Input job parameter'
        changeable_ind = abap_true ) ).

    " Return the default parameters values here
    et_parameter_val = VALUE #(
      ( selname = constants-parameter-input
        kind = if_apj_dt_exec_object=>select_option
        sign = 'I'
        option = 'EQ'
        low = 'DEFAULT_EQUI' )
    ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    "For manual testing only
    me->out = out.

    "test run of application job
    "since application job cannot be debugged we test it via F9
    DATA  et_parameters TYPE if_apj_rt_exec_object=>tt_templ_val  .

    et_parameters = VALUE #(
        ( selname = constants-parameter-input
          kind = if_apj_dt_exec_object=>parameter
          sign = 'I'
          option = 'EQ'
          low = '000000000010000000' )
      ).

    TRY.
        if_apj_rt_exec_object~execute( et_parameters ).
        out->write( |Finished| ).

      CATCH cx_root INTO DATA(job_scheduling_exception).
        out->write( |Exception has occured: { job_scheduling_exception->get_text(  ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    DATA(equipment) = CONV zr_catch_wrs_job-equipment( VALUE #( it_parameters[ 1 ]-low OPTIONAL ) ).
    IF equipment IS INITIAL.
      RETURN.
    ENDIF.

    me->log_handle = log->create_log( CONV #( |{ equipment }| ) ).

    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_start
                 v1 = |{ equipment ALPHA = OUT }| ).

    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_log_handle
                 v1 = log_handle ).

    SELECT SINGLE * FROM zr_catch_wrs_job
      WHERE equipment = @equipment
      INTO @DATA(job_details).

    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_parameters
                 v1 = job_details-notificationtype
                 v2 = job_details-routinggroup
                 v3 = job_details-groupcounter
                 v4 = job_details-priority ).

    update_job_log( job_details ).

    IF valid_inputs( job_details ) = abap_false.
      log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_input_invalid ).
      RAISE EXCEPTION NEW cx_apj_rt_content( ).
    ENDIF.

    DATA(notification_id) = create_notification( job_details ).

    create_order( parameter       = job_details
                  notification_id = notification_id ).

    update_watermeter_status( job_details ).

    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_stop
                 v1 = |{ equipment ALPHA = OUT }| ).
  ENDMETHOD.

  METHOD update_job_log.
    "Link log handle to job to show it in the UI
    DATA update_job TYPE TABLE FOR UPDATE zr_catch_wrs_job\\WRSJob.

    APPEND VALUE #( uuid      = parameter-Uuid
                    logHandle = log_handle
                    %control  = VALUE #( logHandle = if_abap_behv=>mk-on ) ) TO update_job.

    MODIFY ENTITIES OF zr_catch_wrs_job
           ENTITY WRSJob
           UPDATE FIELDS ( LogHandle ) WITH update_job
           FAILED DATA(failed)
           REPORTED DATA(reported).

    IF failed IS NOT INITIAL.
      LOOP AT reported-wrsjob INTO DATA(report).
        log_behv_message( report-%msg ).
      ENDLOOP.
      log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_update_log_handle
                   v1 = parameter-JobName
                   v2 = parameter-JobCount ).
      RAISE EXCEPTION NEW cx_apj_rt_content( ). "Note that this is a logging error, as a result the log will not be linked in the ui, only ZSLG1
    ENDIF.

    COMMIT ENTITIES RESPONSE OF zr_catch_wrs_job
           FAILED DATA(commit_failed)
           REPORTED DATA(commit_reported).

    IF commit_failed-wrsjob IS NOT INITIAL.
      LOOP AT commit_reported-wrsjob INTO DATA(commit_report).
        log_behv_message( commit_report-%msg ).
      ENDLOOP.
      log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_update_log_handle
                   v1 = parameter-JobName
                   v2 = parameter-JobCount ).
      RAISE EXCEPTION NEW cx_apj_rt_content( ). "Note that this is a logging error, as a result the log will not be linked in the ui, only ZSLG1
    ENDIF.
  ENDMETHOD.

  METHOD update_watermeter_status.
    SELECT SINGLE Equipment,
                  DigitalMeterID
      FROM zr_catch_wm_repl_sel
      WHERE Equipment = @parameter-equipment
      INTO @DATA(watermeter).

    " ZSMV:  from status 13, 14 or 84 to  status 18
    " ZIHD: from status 23, 24 to status 28
    DATA update_watermeter_Status TYPE TABLE FOR UPDATE ZR_DigitalMeterStatus\\ZR_DigitalMeterStatus.
    APPEND VALUE #( meterid         = watermeter-equipment
                    status          = 'TEMP' ##TODO
                    %control-status = if_abap_behv=>mk-on ) TO update_watermeter_status.

    MODIFY ENTITIES OF ZR_DigitalMeterStatus
           ENTITY ZR_DigitalMeterStatus
           UPDATE FIELDS ( Status ) WITH update_watermeter_Status
           FAILED DATA(failed)
           REPORTED DATA(reported).
    IF failed-zr_digitalmeterstatus IS NOT INITIAL.
      LOOP AT reported-zr_digitalmeterstatus INTO DATA(report).
        log_behv_message( report-%msg ).
      ENDLOOP.
      log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_update_watermeter ).
      RAISE EXCEPTION NEW cx_apj_rt_content( ).
    ENDIF.

    COMMIT ENTITIES RESPONSE OF ZR_DigitalMeterStatus
           FAILED DATA(commit_failed)
           REPORTED DATA(commit_reported).
    IF commit_failed-zr_digitalmeterstatus IS NOT INITIAL.
      LOOP AT commit_reported-zr_digitalmeterstatus INTO DATA(commit_report).
        log_behv_message( commit_report-%msg ).
      ENDLOOP.
      log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_update_watermeter ).
      RAISE EXCEPTION NEW cx_apj_rt_content( ).
    ENDIF.
  ENDMETHOD.

  METHOD log_message.
    DATA(msg) = zcl_message_factory=>factory->create_from_variables( id = id
                                                                     nr = nr
                                                                     ty = ty
                                                                     v1 = CONV #( v1 )
                                                                     v2 = CONV #( v2 )
                                                                     v3 = CONV #( v3 )
                                                                     v4 = CONV #( v4 ) ).
    log->add_message( msg->bapiret2 ).
    log->save_log( ).

    IF sy-batch = abap_false.
      out->write( msg->get_text( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD log_behv_message.
    log_message( id = message->if_t100_message~t100key-msgid
                 nr = message->if_t100_message~t100key-msgno
                 ty = message->if_t100_dyn_msg~msgty
                 v1 = message->if_t100_dyn_msg~msgv1
                 v2 = message->if_t100_dyn_msg~msgv2
                 v3 = message->if_t100_dyn_msg~msgv3
                 v4 = message->if_t100_dyn_msg~msgv4 ).
  ENDMETHOD.

  METHOD create_notification.
    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_start_notif ).
    TRY.
        zcl_notification=>create( EXPORTING is_notification = VALUE #( )
*                                            iv_commit       = 'X'
*                                            iv_task_determination =
*                                            iv_orderid      =
*                                            it_notif_partner =
*                                            iv_put_in_progress = abap_true
*                                            iv_release_first_task =
*                                            it_extensionin  =
                                  IMPORTING
                                            et_return       = DATA(return)
                                            ev_number       = DATA(notification_id) ).

        log_messages( return ).
        IF zcl_message_collection_factory=>factory->create_from_bapiret2_t( return )->has_errors( ).
            RAISE EXCEPTION NEW cx_apj_rt_content( ).
        ENDIF.
        log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_created_notif
                     v1 = |{ notification_id }| ).

      CATCH zcx_application_fault_with_msg INTO DATA(exception).
        log_messages( exception->get_messages( ) ).
        RAISE EXCEPTION NEW cx_apj_rt_content( ).
    ENDTRY.
  ENDMETHOD.

  METHOD create_order.
    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_start_order ).
    zcl_pm_order=>create( EXPORTING is_header          = VALUE #( )
*                                    is_operation       =
*                                    is_partner         =
*                                    is_userstatus      =
*                                    is_extention       =
                                    iv_notification_nr = notification_id
*                                    iv_header_longtext =
*                                    it_settlement_rule_lines =
*                                    iv_release         = abap_false
*                                    iv_commit          = abap_false
*                                    it_partners        =
*                                    it_operation       =
*                                    it_header_srv      =
*                                    it_tasklist        =
                          IMPORTING ev_number          = DATA(order_id)
                          RECEIVING rt_return          = DATA(return) ).

    log_messages( return ).
    IF zcl_message_collection_factory=>factory->create_from_bapiret2_t( return )->has_errors( ).
      RAISE EXCEPTION NEW cx_apj_rt_content( ).
    ENDIF.

    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_created_order
                 v1 = |{ order_id }| ).
  ENDMETHOD.

  METHOD VALID_INPUTS.
    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_start_input_valid ).

    result = abap_false.

    SELECT SINGLE *
        FROM zr_catch_wm_repl_sel
        WHERE Equipment = @parameter-Equipment
        INTO @DATA(wrs).

    IF wrs-Notification IS NOT INITIAL.
        log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_has_notif
                     v1 = wrs-Notification ).
        RETURN. "Invalid
    ELSE.
        log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_has_no_notif ).
    ENDIF.

    IF wrs-OrderID IS NOT INITIAL.
        log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_has_order
                     v1 = wrs-OrderID ).
        RETURN. "Invalid
    ELSE.
        log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_has_no_order ).
    ENDIF.

    result = abap_true. "Valid
    log_message( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_input_valid ).
  ENDMETHOD.

  METHOD log_messages.
    LOOP AT messages INTO DATA(message).
      log_message( id = message-id
                   nr = message-number
                   ty = message-type
                   v1 = message-message_v1
                   v2 = message-message_v2
                   v3 = message-message_v3
                   v4 = message-message_v4 ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
