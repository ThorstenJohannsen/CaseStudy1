@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZCS1_CUSTOMERS000'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_CUSTOMERS000
  provider contract transactional_query
  as projection on ZR_CS1_CUSTOMERS000
  association [1..1] to ZR_CS1_CUSTOMERS000 as _BaseEntity on $projection.Customerid = _BaseEntity.Customerid
{
  key Customerid,
  Salutation,
  LastName,
  FirstName,
  Company,
  Street,
  City,
  @EndUserText.label: 'Anzahl Bestellungen'
  _OrderCount.OrderCount,
  Country,
  Postcode,
  AccLock,
  LastDate,
  @Semantics: {
    amount.currencyCode: 'Currency'
  }
  SalesVolume,
  @Semantics: {
    amount.currencyCode: 'CurrencyTarget'
  }
  SalesVolumeTarget,
  ChangeRateDate,
  Fax,
  Phone,
  Email,
  Url,
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Currency', 
      entity.name: 'I_CurrencyStdVH', 
      useForValidation: true
    } ]
  }
  Currency,
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Currency', 
      entity.name: 'I_CurrencyStdVH', 
      useForValidation: true
    } ]
  }
  CurrencyTarget,
  Language,
  Weblogin,
  Webpw,
  Memo,
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
  ZzvipZem,
  _BaseEntity
}
