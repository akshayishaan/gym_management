# gym_api.model.PaymentListItemResponse

## Load the model package
```dart
import 'package:gym_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Mongo ObjectId serialized as a string | 
**gymId** | **String** | Mongo ObjectId serialized as a string | 
**memberId** | **String** | Mongo ObjectId serialized as a string | 
**memberName** | **String** |  | 
**planId** | **String** | Mongo ObjectId serialized as a string | [optional] 
**planName** | **String** |  | [optional] 
**amount** | **num** |  | 
**kind** | **String** |  | 
**method** | **String** |  | 
**status** | **String** |  | 
**invoiceNumber** | **String** |  | 
**notes** | **String** |  | [optional] 
**paidAt** | **String** | ISO 8601 date-time string | 
**createdBy** | **String** | Mongo ObjectId serialized as a string | [optional] 
**voidedAt** | **String** | ISO 8601 date-time string | [optional] 
**voidedBy** | **String** | Mongo ObjectId serialized as a string | [optional] 
**voidReason** | **String** |  | [optional] 
**refundedAt** | **String** | ISO 8601 date-time string | [optional] 
**refundedBy** | **String** | Mongo ObjectId serialized as a string | [optional] 
**refundReason** | **String** |  | [optional] 
**createdAt** | **String** | ISO 8601 date-time string | 
**updatedAt** | **String** | ISO 8601 date-time string | 
**membershipId** | **String** | Mongo ObjectId serialized as a string | [optional] 
**membershipStatus** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


