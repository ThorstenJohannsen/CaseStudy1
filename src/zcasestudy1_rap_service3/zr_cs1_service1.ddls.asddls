@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_SERVICE1'
@EndUserText.label: 'Service Config Entity'
define root view entity ZR_CS1_SERVICE1
  as select from zcs1_service1
{
  key id as ID,
      active as Active,
      cast( user_value as abap.char(255) ) as UserValue,      // 255
      cast( default_value as abap.char(255) ) as DefaultValue, // 255
      @Semantics.user.createdBy: true
      created_by as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt
}
