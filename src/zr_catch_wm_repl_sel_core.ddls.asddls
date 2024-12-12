@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Watermeter replacement selection app'
define root view entity ZR_CATCH_WM_REPL_SEL_CORE 
as select from Z_I_Equipment
  association [0..1] to Z_I_Device_Loc_Details      as _DevLocDetails            on  $projection.functionallocation = _DevLocDetails.DeviceLocation
                                                                                 and _DevLocDetails.Language        = $session.system_language
  association [0..*] to ZI_Notification_YF_ZV_Types as _Notification_YF_ZV_Types on  $projection.DigitalMeterID               = _Notification_YF_ZV_Types.CustomerReference
                                                                                 and (
                                                                                    _Notification_YF_ZV_Types.ObjectStatus    = 'I0068'
                                                                                    or _Notification_YF_ZV_Types.ObjectStatus = 'I0070'
                                                                                  )
  association [0..*] to ZI_PMOrganisationalData     as _PMOrganisationalData     on  $projection.DigitalMeterID = _PMOrganisationalData.CustomerReference
  association [0..1] to ZI_AggregatedEquiStatusText as _AggregatedEquiStatusText on  $projection.Equipment = _AggregatedEquiStatusText.Equipment

{
  key Equipment,
      _UtilitiesDevice._InstallationDeviceSlice._ISU_DM_STATUS[1:inner].Meterid as DigitalMeterID,
      ConstructionYear,
      MaterialNumber,
      SerialNumber,
      MaintObjectInternalID,
      _EquipmentTimeSegValidDate._LocationAccountAssignment._FunctionalLocation.FunctionalLocation,

      _DevLocDetails,
      _EquipmentText,
      _EquipmentTimeSeg,
      _EquipmentTimeSegValidDate,
      _UtilitiesDevice,
      _ObjectStatus,
      _Notification_YF_ZV_Types,
      _PMOrganisationalData,
      _AggregatedEquiStatusText


}
