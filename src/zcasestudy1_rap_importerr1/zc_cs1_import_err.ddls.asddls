@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZCS1_IMPORT_ERR'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_IMPORT_ERR
  provider contract transactional_query
  as projection on ZR_CS1_IMPORT_ERR
  association [1..1] to ZR_CS1_IMPORT_ERR as _BaseEntity on $projection.ID = _BaseEntity.ID
{

  key ID,
      Description,
      @Semantics: { user.createdBy: true }
      CreatedBy,
      @Semantics: { systemDateTime.createdAt: true }
      CreatedAt,
      @Semantics: { user.localInstanceLastChangedBy: true }
      LocalLastChangedBy,
      @Semantics: { systemDateTime.localInstanceLastChangedAt: true }
      LocalLastChangedAt,
      @Semantics: { systemDateTime.lastChangedAt: true }
      LastChangedAt,
      _BaseEntity
}
