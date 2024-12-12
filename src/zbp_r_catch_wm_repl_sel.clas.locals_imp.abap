CLASS lhc_WatermeterReplacementSelec DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR WatermeterReplacementSelection RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ WatermeterReplacementSelection RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK WatermeterReplacementSelection.

    METHODS createDossiers FOR MODIFY
      IMPORTING keys FOR ACTION WatermeterReplacementSelection~createDossiers.

    METHODS updateWaterMeters FOR MODIFY
      IMPORTING keys FOR ACTION WatermeterReplacementSelection~updateWaterMeters.

    METHODS msg IMPORTING !id           TYPE symsgid DEFAULT zcl_catch_wm_repl_sel_log=>constants-msg-id
                          ty            TYPE symsgty DEFAULT zcl_error=>gcs_message_type-error
                          !nr           TYPE symsgno
                          v1            TYPE any     OPTIONAL
                          v2            TYPE any     OPTIONAL
                          v3            TYPE any     OPTIONAL
                          v4            TYPE any     OPTIONAL
                RETURNING VALUE(result) TYPE REF TO  if_abap_behv_message.
ENDCLASS.

CLASS lhc_WatermeterReplacementSelec IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD createDossiers.
    SELECT equipment, JobName, JobCount
      FROM zc_catch_wm_repl_sel
      FOR ALL ENTRIES IN @keys
      WHERE equipment = @keys-equipment
      INTO TABLE @DATA(job_statuses).

    " Validate inputs
    LOOP AT keys INTO DATA(key).
      DATA(job_status) = VALUE #( job_statuses[ equipment = key-equipment ] OPTIONAL ).
      TRY.
          cl_apj_rt_api=>get_job_status( EXPORTING iv_jobname    = job_status-jobname
                                                   iv_jobcount   = job_status-jobcount
                                         IMPORTING ev_job_status = DATA(jobstatus) ).
          IF    JobStatus = zcl_apj_rt_types=>cs_job_status-running
             OR JobStatus = zcl_apj_rt_types=>cs_job_status-ready
             OR JobStatus = zcl_apj_rt_types=>cs_job_status-scheduled
             OR JobStatus = zcl_apj_rt_types=>cs_job_status-released
             OR JobStatus = zcl_apj_rt_types=>cs_job_status-cancelling.
            APPEND VALUE #( %cid                   = key-%cid_ref
                            equipment              = key-equipment
                            %action-createdossiers = if_abap_behv=>mk-on ) TO failed-watermeterreplacementselection.
            APPEND VALUE #( %cid                   = key-%cid_ref
                            equipment              = key-equipment
                            %msg                   = msg( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-cd_job_active
                                                          v1 = |{ key-Equipment ALPHA = OUT }| )
                            %action-createdossiers = if_abap_behv=>mk-on  ) TO reported-watermeterreplacementselection.
          ENDIF.
        CATCH cx_apj_rt.
          " No job found, so don't validate status
      ENDTRY.

      IF key-%param-NotificationType IS INITIAL.
        APPEND VALUE #( %cid                   = key-%cid_ref
                        equipment              = key-equipment
                        %action-createdossiers = if_abap_behv=>mk-on ) TO failed-watermeterreplacementselection.
        APPEND VALUE #(
            %cid                   = key-%cid_ref
            equipment              = key-equipment
            %msg                   = msg( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-mandatory_parameter
                                          v1 = 'Meldingsoort' )
            %action-createdossiers = if_abap_behv=>mk-on  ) TO reported-watermeterreplacementselection.
      ENDIF.

      IF key-%param-GroupCounter IS INITIAL.
        APPEND VALUE #( %cid                   = key-%cid_ref
                        equipment              = key-equipment
                        %action-createdossiers = if_abap_behv=>mk-on ) TO failed-watermeterreplacementselection.
        APPEND VALUE #(
            %cid                   = key-%cid_ref
            equipment              = key-equipment
            %msg                   = msg( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-mandatory_parameter
                                          v1 = 'Routing groep teller' )
            %action-createdossiers = if_abap_behv=>mk-on  ) TO reported-watermeterreplacementselection.
      ENDIF.

      IF key-%param-RoutingGroup IS INITIAL.
        APPEND VALUE #( %cid                   = key-%cid_ref
                        equipment              = key-equipment
                        %action-createdossiers = if_abap_behv=>mk-on ) TO failed-watermeterreplacementselection.
        APPEND VALUE #(
            %cid                   = key-%cid_ref
            equipment              = key-equipment
            %msg                   = msg( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-mandatory_parameter
                                          v1 = 'Routingnummer van de opvolger' )
            %action-createdossiers = if_abap_behv=>mk-on  ) TO reported-watermeterreplacementselection.
      ENDIF.

      IF key-%param-Priority IS INITIAL.
        APPEND VALUE #( %cid                   = key-%cid_ref
                        equipment              = key-equipment
                        %action-createdossiers = if_abap_behv=>mk-on ) TO failed-watermeterreplacementselection.
        APPEND VALUE #(
            %cid                   = key-%cid_ref
            equipment              = key-equipment
            %msg                   = msg( nr = zcl_catch_wm_repl_sel_log=>constants-msg-nr-mandatory_parameter
                                          v1 = 'Prioriteit' )
            %action-createdossiers = if_abap_behv=>mk-on  ) TO reported-watermeterreplacementselection.
      ENDIF.

      ##TODO " Check notif type to watermeter status via config table
    ENDLOOP.

    IF failed-watermeterreplacementselection IS NOT INITIAL.
      RETURN.
    ENDIF.

    " Validation ok
    " -> mark relevant equipments for job scheduling
    " -> see ZR_CATCH_WRS_JOB=>unmanaged_save, for scheduling of the actual job..
    SELECT uuid,
           equipment
      FROM zr_catch_wrs_job
      FOR ALL ENTRIES IN @keys
      WHERE Equipment = @keys-Equipment
      INTO TABLE @DATA(currentJobs).

    DATA newJobs      TYPE TABLE FOR CREATE zc_catch_wrs_job\\WSRJob.
    DATA existingJobs TYPE TABLE FOR UPDATE zc_catch_wrs_job\\WSRJob.
    LOOP AT keys INTO key.
      DATA(currentJob) = VALUE #( currentJobs[ equipment = key-Equipment ] OPTIONAL ).
      IF currentJob IS INITIAL.
        APPEND VALUE #( %cid             = |Schedule job for { key-Equipment }|
                        %is_draft        = abap_false
                        equipment        = key-Equipment
                        notificationtype = key-%param-NotificationType
                        routinggroup     = key-%param-RoutingGroup
                        groupcounter     = key-%param-GroupCounter
                        priority         = key-%param-Priority
                        scheduleJob      = abap_true
                        %control         = VALUE #( equipment        = if_abap_behv=>mk-on
                                                    notificationtype = if_abap_behv=>mk-on
                                                    routinggroup     = if_abap_behv=>mk-on
                                                    groupcounter     = if_abap_behv=>mk-on
                                                    priority         = if_abap_behv=>mk-on
                                                    scheduleJob      = if_abap_behv=>mk-on ) ) TO newJobs.
      ELSE.
        APPEND VALUE #( %is_draft        = abap_false
                        uuid             = currentJob-Uuid
                        equipment        = key-Equipment
                        notificationtype = key-%param-NotificationType
                        routinggroup     = key-%param-RoutingGroup
                        groupcounter     = key-%param-GroupCounter
                        priority         = key-%param-Priority
                        scheduleJob      = abap_true
                        %control         = VALUE #( equipment        = if_abap_behv=>mk-on
                                                    notificationtype = if_abap_behv=>mk-on
                                                    routinggroup     = if_abap_behv=>mk-on
                                                    groupcounter     = if_abap_behv=>mk-on
                                                    priority         = if_abap_behv=>mk-on
                                                    scheduleJob      = if_abap_behv=>mk-on ) ) TO existingjobs.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zc_catch_wrs_job
           ENTITY WSRJob
           CREATE FROM newJobs
           " TODO: variable is assigned but never used (ABAP cleaner)
           MAPPED DATA(job_create_mapped)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(job_create_reported)
           " TODO: variable is assigned but never used (ABAP cleaner)
           FAILED DATA(job_create_failed).

    MODIFY ENTITIES OF zc_catch_wrs_job
           ENTITY WSRJob
           UPDATE FROM existingJobs
           " TODO: variable is assigned but never used (ABAP cleaner)
           MAPPED DATA(job_update_mapped)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(job_update_reported)
           " TODO: variable is assigned but never used (ABAP cleaner)
           FAILED DATA(job_update_failed).

    ##TODO " Error handling
  ENDMETHOD.

  METHOD updateWaterMeters.
    DATA(log) = NEW zcl_catch_wm_repl_sel_log( ).

    ##TODO " log start processing
    LOOP AT keys INTO DATA(key).
      TRY.
          zcl_catch_wm_repl_sel_equi=>get_equipment_from_id( CONV #( key-Equipment ) )->change_advance_replacement_yea(
                                                                                         key-%param-replacementYear ).
          ##TODO " log success
        CATCH zcx_catch_wm_repl_sel_equi INTO DATA(exception).
          log->log_messages( exception->messages ).
      ENDTRY.
    ENDLOOP.
    ##TODO " log end processing
  ENDMETHOD.

  METHOD msg.
    result = new_message( id       = id
                          number   = nr
                          severity = CONV #( ty )
                          v1       = v1
                          v2       = v2
                          v3       = v3
                          v4       = v4 ).
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zr_catch_wm_repl_sel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save REDEFINITION.

ENDCLASS.

CLASS lsc_zr_catch_wm_repl_sel IMPLEMENTATION.

  METHOD save.
  ENDMETHOD.

ENDCLASS.
