@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_STATISTIC'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_CS1_STATISTIC
  as select from ZCS1_STATISTIC
{
  key stat_id as StatID,
  interface_name as InterfaceName,
  class_name as ClassName,
  active as Active,
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
