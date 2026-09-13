// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_response_expiring_list_inner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResponseExpiringListInner _$DashboardResponseExpiringListInnerFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'DashboardResponseExpiringListInner',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            '_id',
            'name',
            'phone',
            'membershipExpiry',
            'daysUntilExpiry'
          ],
        );
        final val = DashboardResponseExpiringListInner(
          id: $checkedConvert('_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          phone: $checkedConvert('phone', (v) => v as String),
          membershipExpiry:
              $checkedConvert('membershipExpiry', (v) => v as String),
          planName: $checkedConvert('planName', (v) => v as String?),
          daysUntilExpiry:
              $checkedConvert('daysUntilExpiry', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'id': '_id'},
    );

Map<String, dynamic> _$DashboardResponseExpiringListInnerToJson(
    DashboardResponseExpiringListInner instance) {
  final val = <String, dynamic>{
    '_id': instance.id,
    'name': instance.name,
    'phone': instance.phone,
    'membershipExpiry': instance.membershipExpiry,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('planName', instance.planName);
  val['daysUntilExpiry'] = instance.daysUntilExpiry;
  return val;
}
