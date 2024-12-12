CLASS lsc_zr_catch_wrs_job DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

  PRIVATE SECTION.
    DATA: nr_of_jobs TYPE i.

    METHODS:
        schedule_job IMPORTING equipment TYPE zr_catch_wrs_job-Equipment
                     EXPORTING job_start_timestamp TYPE timestamp
                               job_name TYPE cl_apj_rt_api=>ty_jobname
                               job_count TYPE cl_apj_rt_api=>ty_jobcount,
        determine_job_start RETURNING VALUE(result) TYPE timestamp.
ENDCLASS.

CLASS lsc_zr_catch_wrs_job IMPLEMENTATION.
  METHOD schedule_job.
    DATA(job_parameters) = VALUE cl_apj_rt_api=>tt_job_parameter_value(
                                     ( name    = zcl_catch_wm_repl_sel_job=>constants-parameter-input
                                       t_value = VALUE #( ( sign   = 'I'
                                                            option = 'EQ'
                                                            low    = equipment ) ) ) ).

    job_start_timestamp = determine_job_start( ).

    cl_apj_rt_api=>schedule_job( EXPORTING iv_job_template_name   = zcl_catch_wm_repl_sel_job=>constants-job_template
                                           iv_job_text            = |Inhaalbeweging: Create dossiers { equipment }|
                                           is_start_info          = VALUE #( timestamp = job_start_timestamp )
                                           it_job_parameter_value = job_parameters
                                 IMPORTING ev_jobname             = job_name
                                           ev_jobcount            = job_count ).
  ENDMETHOD.

  METHOD determine_job_start.
    DATA(timestamp) = zcl_timestamp_factory=>factory->get_current_timestamp( ).

    DATA: night_time TYPE timn.
    night_time = zcl_tvar=>read( zcl_tvar=>constants-catchup-cd_job_night_start ).
    IF night_time IS INITIAL.
        night_time = 22000000. "Default to 22:00:00
    ENDIF.

    DATA(night_cutoff) = zcl_tvar=>read( zcl_tvar=>constants-catchup-cd_job_nr_cutoff ).
    IF nr_of_jobs > night_cutoff OR night_cutoff IS INITIAL.
        timestamp->set_time( night_time ).
    ENDIF.

    result = timestamp->timestamp.
  ENDMETHOD.

  METHOD save_modified.
    " We are forced to use an unmanaged save because we want to update
    " the CREATED entries with job count and name - these are not in
    " the DB table yet so they have to be changed before the insert
    " occurs, which cannot be done in managed save anymore..

    DATA job_start_timestamp TYPE timestamp.
    DATA job_name            TYPE cl_apj_rt_api=>ty_jobname.
    DATA job_count           TYPE cl_apj_rt_api=>ty_jobcount.
    DATA db_table_line       TYPE zcatch_wrs_job.

    " Determine number of jobs we may startup to see if we delay until evening...
    me->nr_of_jobs  = lines( create-wrsjob ).
    me->nr_of_jobs += lines( update-wrsjob ).

    LOOP AT create-wrsjob INTO DATA(create_job) WHERE %control-ScheduleJob = if_abap_behv=>mk-on AND ScheduleJob = abap_true.
      schedule_job( EXPORTING equipment           = create_job-Equipment
                    IMPORTING job_start_timestamp = job_start_timestamp
                              job_name            = job_name
                              job_count           = job_count ).

      db_table_line = CORRESPONDING #( create_job MAPPING FROM ENTITY ).
      db_table_line-job_start_timestamp = job_start_timestamp.
      db_table_line-job_name            = job_name.
      db_table_line-job_count           = job_count.
      INSERT zcatch_wrs_job FROM @db_table_line.

      CLEAR: job_name,
             job_count.
    ENDLOOP.

    LOOP AT update-wrsjob INTO DATA(update_job) WHERE %control-ScheduleJob = if_abap_behv=>mk-on AND ScheduleJob = abap_true.
      schedule_job( EXPORTING equipment           = update_job-Equipment
                    IMPORTING job_start_timestamp = job_start_timestamp
                              job_name            = job_name
                              job_count           = job_count ).

      UPDATE zcatch_wrs_job
        SET job_start_timestamp = @job_start_timestamp,
            job_name = @job_name,
            job_count = @job_count
        WHERE uuid = @update_job-Uuid.

      CLEAR: job_name,
             job_count.
    ENDLOOP.

    " Normal create
    " Not needed, will always happen together with scheduling of a job...

    " Normal update
    DATA update_set TYPE TABLE OF string.
    DATA(structdescr) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( db_table_line ) ).
    LOOP AT update-wrsjob INTO update_job.
      db_table_line = CORRESPONDING #( update_job MAPPING FROM ENTITY ).

      LOOP AT structdescr->get_components( ) INTO DATA(component).
        ASSIGN COMPONENT component-name OF STRUCTURE db_table_line TO FIELD-SYMBOL(<component_value>).
        IF     <component_value> IS ASSIGNED
           AND <component_value> IS NOT INITIAL
           AND component-name    <> 'UUID'.
          APPEND |{ component-name } = @db_table_line-{ component-name },| TO update_set.
        ENDIF.
      ENDLOOP.

      ASSIGN update_set[ lines( update_set ) ] TO FIELD-SYMBOL(<update_set>).
      REPLACE ',' IN <update_set> WITH ''.

      UPDATE zcatch_wrs_job
        SET (update_set)
        WHERE uuid = @update_job-Uuid.

      CLEAR update_set.
    ENDLOOP.

    " Normal delete
    DATA db_table TYPE TABLE OF zcatch_wrs_job.
    db_table = CORRESPONDING #( delete-wrsjob MAPPING FROM ENTITY ).
    DELETE zcatch_wrs_job FROM TABLE @db_table.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_WRSJob DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR WRSJob RESULT result.
    METHODS checkEquipmentUnique FOR VALIDATE ON SAVE
      IMPORTING keys FOR WRSJob~checkEquipmentUnique.

ENDCLASS.

CLASS lhc_WRSJob IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD checkEquipmentUnique.
    READ ENTITIES OF zc_catch_wrs_job
        ENTITY WSRJob
        FIELDS ( equipment ) WITH CORRESPONDING #( keys )
        RESULT DATA(newJobs).

    SORT newJobs BY Equipment.
    DELETE ADJACENT DUPLICATES FROM newJobs COMPARING Equipment.

    SELECT *
        FROM zc_catch_wrs_job
        FOR ALL ENTRIES IN @newJobs
        WHERE equipment = @newJobs-Equipment
        INTO TABLE @DATA(existingJobs).

    LOOP AT keys INTO DATA(key).
        DATA(equipment) = newJobs[ uuid = key-Uuid ]-Equipment.
        IF line_exists( existingjobs[ Equipment = equipment ] ).
            APPEND VALUE #( uuid      = key-Uuid
                            %is_draft = key-%is_draft ) TO failed-wrsjob.
            APPEND VALUE #( uuid      = key-Uuid
                            %is_draft = key-%is_draft
                            ##TODO "Proper error handling
                            %msg      = new_message_with_text( text = |Equipment { equipment } bestaat al in ZCATCH_WRS_JOB| ) ) TO reported-wrsjob.
        ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
