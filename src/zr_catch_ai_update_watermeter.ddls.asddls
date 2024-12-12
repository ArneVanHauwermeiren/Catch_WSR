@EndUserText.label: 'Watermeter replace sel app - action input updateWaterMeter'
define abstract entity ZR_CATCH_AI_UPDATE_WATERMETER
{
   @Consumption.valueHelpDefinition: [ { entity: { name: 'ZC_AdvReplYear_VH', element: 'UtilsDeviceAdvncRplcmtYear' }, distinctValues: true } ]
   @EndUserText.label: 'Vervroegd vervangingsjaar'
   replacementYear : abap.numc( 4 );
    
}
