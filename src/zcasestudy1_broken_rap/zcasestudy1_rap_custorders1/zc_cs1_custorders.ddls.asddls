@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZCS1_CUSTORDERS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_CUSTORDERS
  provider contract transactional_query
  as projection on ZR_CS1_CUSTORDERS
  association [1..1] to ZR_CS1_CUSTORDERS as _BaseEntity on $projection.Orderid = _BaseEntity.Orderid
{
  key Orderid,
  Customerid,
  OrderDate,
  @Semantics: {
    amount.currencyCode: 'Currency'
  }
  OrderTotal,
  Discount,
  Info,
  Status,
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Currency', 
      entity.name: 'I_CurrencyStdVH', 
      useForValidation: true
    } ]
  }
  Currency,
  
///* 1. Hier holen wir das Feld über die Association vom Kunden wieder rein */
//  @EndUserText.label: 'Zielwährung (Kunde)'
//  _Customer.CurrencyTarget as Currency_Target,

//  /* 2. Hier binden wir den Zielbetrag an die Währung vom Kunden */
//  @Semantics.amount.currencyCode: 'Currency_Target'
//  OrderTotalTarget,
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
  
  _Customer : redirected to ZC_CS1_CUSTOMERS,
  
  _BaseEntity
}
