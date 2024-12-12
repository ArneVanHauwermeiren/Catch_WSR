@EndUserText.label: 'Watermeter replacement selection app - job'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_CATCH_WRS_JOB
  provider contract transactional_query
  as projection on ZR_CATCH_WRS_JOB
{
  key Uuid,
      Equipment,
      notificationtype,
      routinggroup,
      groupcounter,
      priority,
      ScheduleJob,
      JobStartTimestamp,
      JobCount,
      JobName,
      CreatedAt,
      CreatedBy,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
