@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T128 Suchhilfe für Status aus Domäne'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS 
@Search.searchable: true
define view entity zcs1_StatusVH as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T ( p_domain_name: 'ZDSTATUS1' )
{
     @UI.hidden: true
    key domain_name,
    @UI.hidden: true
    key value_position,
    @UI.hidden: true
    key language,

    @EndUserText.label: 'Status'
    @UI.lineItem: [{ position: 10 }]
    @Search.defaultSearchElement: true
    value_low as Status,
    
    @EndUserText.label: 'Bezeichnung'
    @UI.lineItem: [{ position: 20 }]
    @Semantics.text: true
    @Search.defaultSearchElement: true
    text      as StatusText
}
where language = $session.system_language
