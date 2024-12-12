@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Watermeter replacement selection app - job status'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define root view entity ZR_CATCH_WRS_JOB
  as select from zcatch_wrs_job

{
  key uuid                  as Uuid,

      equipment             as Equipment,
      schedule_job          as ScheduleJob,
      notificationtype,
      routinggroup,
      groupcounter,
      priority,
      job_start_timestamp  as JobStartTimestamp,
      job_count             as JobCount,

      job_name              as JobName,
      log_handle            as LogHandle,
      
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
