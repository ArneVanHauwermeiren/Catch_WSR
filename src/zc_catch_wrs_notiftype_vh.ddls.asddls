@EndUserText.label: 'Watermeter replacement selection notif type valuehelp'
@AccessControl.authorizationCheck: #NOT_REQUIRED
//Wrapper to make dropdown
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZC_CATCH_WRS_NOTIFTYPE_VH 
 as select distinct from Z_C_NOTIFTYPEVH
{
    @Search.defaultSearchElement: true
    key NotificationType,
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.8
    NotificationTypeText
}
