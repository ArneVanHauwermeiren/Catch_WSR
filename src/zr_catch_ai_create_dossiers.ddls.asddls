@EndUserText.label: 'Watermeter replace sel app - action input createDossiers'
define abstract entity ZR_CATCH_AI_CREATE_DOSSIERS

{
  
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_CATCH_WRS_NOTIFTYPE_VH', element: 'NotificationType' } }]
  @EndUserText.label: 'Meldingssoort'
  NotificationType           : abap.char(2);
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_CATCH_WRS_PRIORITY_VH', element: 'Priority' },
                                       additionalBinding: [{ element: 'NotificationType', localElement: 'NotificationType' }] }]
  @EndUserText.label: 'Prioriteit'
  Priority                   : abap.char(1);
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_BillOfOperationsStdVH', element: 'BillOfOperationsGroup' } }]
  @EndUserText.label: 'Routingnummer van de opvolger'
  RoutingGroup               : abap.char(8);
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_BillOfOperationsStdVH', element: 'BillOfOperationsVariant' } }]
  @EndUserText.label: 'Routinggroepteller'
  GroupCounter               : abap.char(2);

}
