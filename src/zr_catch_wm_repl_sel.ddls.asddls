@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Watermeter replacement selection app'
define root view entity ZR_CATCH_WM_REPL_SEL 
as select from ZR_CATCH_WM_REPL_SEL_CORE

association[0..1] to ZR_CATCH_WRS_JOB as _JobStatus on _JobStatus.Equipment = $projection.Equipment
association [0..*] to ZI_APPLICATION_LOG as _ApplicationLog on $projection.loghandle = _ApplicationLog.Log_handle
{
  key Equipment,

      _EquipmentTimeSegValidDate._LocationAccountAssignment._FunctionalLocation._FunctionalLocationtext[Language = $session.system_language].FunctionalLocationName as FunctionalLocationDesc,
      _DevLocDetails[ Language = $session.system_language ].DeviceLocationAddition,
      _UtilitiesDevice._EquipmentText.EquipmentName                                                                                                                 as DeviceDescription,

      _UtilitiesDevice._InstallationDeviceSlice._ISU_DM_STATUS.Meterid                                                                                              as DigitalMeterID,
      _UtilitiesDevice._InstallationDeviceSlice._ISU_DM_STATUS.Status                                                                                               as DigitalMeterStatus,
      _UtilitiesDevice._InstallationDeviceSlice._ISU_DM_STATUS._StatusDescription.Description                                                                       as DigitalMeterStatusDesc,

      cast(_UtilitiesDevice._FunctionalLocation._FunctionalLocation[FunctionalLocationType = 'A'].FunctionalLocation as abap.char( 30 ) )                           as ConnectionObject,

      _EquipmentText[Language = $session.system_language].EquipmentName                                                                                             as EquipmentDescription,
      ConstructionYear,
      MaterialNumber,
      SerialNumber,
      _UtilitiesDevice._FunctionalLocation._LocationAccountAssgnmntFiltrd._Address.StreetName                                                                       as Street,
      _UtilitiesDevice._FunctionalLocation._LocationAccountAssgnmntFiltrd._Address.PostalCode,
      _UtilitiesDevice._FunctionalLocation._LocationAccountAssgnmntFiltrd._Address.District,
      _UtilitiesDevice._FunctionalLocation._LocationAccountAssgnmntFiltrd._Address.CityName                                                                         as City,
      _UtilitiesDevice._FunctionalLocation._LocationAccountAssgnmntFiltrd._Address.HouseNumber,

      cast(FunctionalLocation as abap.char( 30 ))                                                                                                                   as FunctionalLocation,

      //o   next replacement year => TE683-BGLBIS Charlotte will provide more info
      _UtilitiesDevice._UtilitiesDeviceHeader.UtilsDeviceAdvncRplcmtYear                                                                                            as AdvancedReplacementYear,
      _UtilitiesDevice._InstallationDeviceSlice._Installation._UtilitiesInstallationHist.MeterReadingUnit,
      _UtilitiesDevice._InstallationDeviceSlice._Installation._UtilitiesInstallationHist._MeterReadingUnit.UtilitiesPortion                                         as Portion,

      _AggregatedEquiStatusText.AggregatedStatus                                                                                                                    as SystemStatus,

      _Notification_YF_ZV_Types.Notification,
      _Notification_YF_ZV_Types.NotificationType,
      _Notification_YF_ZV_Types.Priority,
      _PMOrganisationalData._Order_ZSMV_ZIHD_Types.OrderID,
      
      _JobStatus,
      _JobStatus.LogHandle,
      _ApplicationLog
}
