@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Watermeter replacement selection app'

@Metadata.allowExtensions: true

define root view entity ZC_CATCH_WM_REPL_SEL
provider contract transactional_query
  as projection on ZR_CATCH_WM_REPL_SEL

{
  key     Equipment,

          FunctionalLocationDesc,
          DeviceLocationAddition,
          DeviceDescription,
          DigitalMeterID,
          DigitalMeterStatus,
          DigitalMeterStatusDesc,
          ConnectionObject,
          EquipmentDescription,
          ConstructionYear,
          MaterialNumber,
          SerialNumber,
          Street,
          PostalCode,
          District,
          City,
          HouseNumber,
          FunctionalLocation,
          AdvancedReplacementYear,
          MeterReadingUnit,
          Portion,
          SystemStatus,
          Notification,
          NotificationType,
          Priority,
          OrderID,


          // Fields for create dossiers
          _JobStatus.JobStartTimestamp,
          _JobStatus.ScheduleJob,
          _JobStatus.JobCount,
          _JobStatus.JobName,
          @EndUserText.label: 'Job Status'
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_CATCH_WRS_GET_JOB_STATUS'
  virtual JobStatus            : abap.char(1),

          @EndUserText.label: 'Generation'
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_CATCH_WRS_GET_JOB_STATUS'
  virtual JobStatusText        : abap.char(20),

          @EndUserText.label: 'Criticality'
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_CATCH_WRS_GET_JOB_STATUS'
  virtual JobStatusCriticality : abap.int1,
          
          LogHandle,
          _ApplicationLog
}
