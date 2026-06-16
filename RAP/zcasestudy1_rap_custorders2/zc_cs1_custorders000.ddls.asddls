@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZCS1_CUSTORDERS000'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_CUSTORDERS000
  provider contract transactional_query
  as projection on ZR_CS1_CUSTORDERS000
//  association [1..1] to ZR_CS1_CUSTORDERS000 as _BaseEntity on $projection.Orderid = _BaseEntity.Orderid
{
  key Orderid,
  @EndUserText.label: 'KdNr'
  Customerid,
  OrderDate,
  @Semantics: {
    amount.currencyCode: 'Currency'
  }
  OrderTotal,
  Discount,
  Info,
    
   @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Status', 
      entity.name: 'zcs1_StatusVH', 
      useForValidation: true
    } ]
  }       
   @ObjectModel.text.element: [ 'StatusText' ] // Text-Verknüpfung weitergeben  
  Status,
  
  _StatusVH.StatusText, // Textfeld in die Projektion aufnehmen
  
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Currency', 
      entity.name: 'I_CurrencyStdVH', 
      useForValidation: true
    } ]
  }
  Currency,
  @Semantics: {
    user.createdBy: true
  }
  CreatedBy,
  @Semantics: {
    systemDateTime.createdAt: true
  }
  CreatedAt,
  @Semantics: {
    user.localInstanceLastChangedBy: true
  }
  LocalLastChangedBy,
  @Semantics: {
    systemDateTime.localInstanceLastChangedAt: true
  }
  LocalLastChangedAt,
  @Semantics: {
    systemDateTime.lastChangedAt: true
  }
  LastChangedAt,
  
  _StatusVH // Association weitergeben
//  _BaseEntity
}
