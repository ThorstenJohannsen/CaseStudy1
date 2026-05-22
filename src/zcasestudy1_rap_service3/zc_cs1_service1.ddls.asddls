@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: { label: 'Service Config' }
@ObjectModel.sapObjectNodeType.name: 'ZCS1_SERVICE1'
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_SERVICE1
  provider contract transactional_query
  as projection on ZR_CS1_SERVICE1
{
      @UI.facet: [{ id: 'General', type: #IDENTIFICATION_REFERENCE, label: 'General' }]
      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key ID,
  
      @UI.identification: [{ position: 20 }]  // Active
      @UI.lineItem: [{ position: 20 }]
      Active,
      
      @UI.identification: [{ position: 30 }]  // UserValue
      @UI.lineItem: [{ position: 30 }]
      @Semantics.text: true
      UserValue,
      
      @UI.identification: [{ position: 40 }]  // DefaultValue
      @UI.lineItem: [{ position: 40 }]
      @Semantics.text: true
      DefaultValue,
      
      @UI.identification: [{ position: 50 }]
      CreatedBy,
      
      @UI.identification: [{ position: 60 }]
      @Semantics.systemDateTime.createdAt: true
      CreatedAt,
      
      @UI.identification: [{ position: 70 }]
      LocalLastChangedBy,
      
      @UI.identification: [{ position: 80 }]
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      
      @UI.hidden: true
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt
}
