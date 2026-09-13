# gym_api.model.MemberResponse

## Load the model package
```dart
import 'package:gym_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Mongo ObjectId serialized as a string | 
**gymId** | **String** | Mongo ObjectId serialized as a string | 
**name** | **String** |  | 
**email** | **String** |  | [optional] 
**phone** | **String** |  | 
**address** | **String** |  | [optional] 
**photo** | **String** |  | [optional] 
**dateOfBirth** | **String** | ISO 8601 date-time string | [optional] 
**gender** | **String** |  | [optional] 
**planId** | **String** | Mongo ObjectId serialized as a string | [optional] 
**planName** | **String** |  | [optional] 
**membershipStart** | **String** | Calendar date in YYYY-MM-DD format | [optional] 
**membershipExpiry** | **String** | Calendar date in YYYY-MM-DD format | [optional] 
**notes** | **String** |  | [optional] 
**emergencyContact** | **String** |  | [optional] 
**dueAmount** | **num** |  | 
**isActive** | **bool** |  | 
**status** | [**MemberDisplayStatus**](MemberDisplayStatus.md) |  | [optional] 
**daysUntilExpiry** | **int** |  | [optional] 
**createdAt** | **String** | ISO 8601 date-time string | 
**updatedAt** | **String** | ISO 8601 date-time string | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


