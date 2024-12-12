@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Watermeter replacement selection priority valuehelp'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZC_CATCH_WRS_PRIORITY_VH 
as select from Z_C_NotifPriorityVH
association[0..*] to I_PMNotificationType as _NotificationType on _NotificationType.MaintPriorityType = $projection.PriorityType
{
    @Search.defaultSearchElement: true
    key Priority,
    @Search.defaultSearchElement: true
    key PriorityType,
    @Search.defaultSearchElement: true
    key _NotificationType.NotificationType,
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.8
    PriorityDesc
}
