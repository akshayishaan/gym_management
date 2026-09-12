# gym_api.api.DefaultApi

## Load the API package
```dart
import 'package:gym_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**activityGet**](DefaultApi.md#activityget) | **GET** /activity | Activity log
[**authLoginPost**](DefaultApi.md#authloginpost) | **POST** /auth/login | Log in
[**authRefreshPost**](DefaultApi.md#authrefreshpost) | **POST** /auth/refresh | Refresh access token
[**authSignupPost**](DefaultApi.md#authsignuppost) | **POST** /auth/signup | Create an account
[**dashboardGet**](DefaultApi.md#dashboardget) | **GET** /dashboard | Gym dashboard summary
[**gymsGet**](DefaultApi.md#gymsget) | **GET** /gyms | List gyms
[**gymsIdDelete**](DefaultApi.md#gymsiddelete) | **DELETE** /gyms/{id} | Delete a gym
[**gymsIdGet**](DefaultApi.md#gymsidget) | **GET** /gyms/{id} | Get a gym
[**gymsIdPut**](DefaultApi.md#gymsidput) | **PUT** /gyms/{id} | Update a gym
[**gymsPost**](DefaultApi.md#gymspost) | **POST** /gyms | Create a gym
[**healthGet**](DefaultApi.md#healthget) | **GET** /health | Health check
[**membersGet**](DefaultApi.md#membersget) | **GET** /members | List members
[**membersIdDelete**](DefaultApi.md#membersiddelete) | **DELETE** /members/{id} | Soft-delete a member
[**membersIdGet**](DefaultApi.md#membersidget) | **GET** /members/{id} | Get a member
[**membersIdPut**](DefaultApi.md#membersidput) | **PUT** /members/{id} | Update a member
[**membersPost**](DefaultApi.md#memberspost) | **POST** /members | Create a member
[**membershipsGet**](DefaultApi.md#membershipsget) | **GET** /memberships | List memberships
[**membershipsIdReversePost**](DefaultApi.md#membershipsidreversepost) | **POST** /memberships/{id}/reverse | Reverse a plan purchase
[**paymentsGet**](DefaultApi.md#paymentsget) | **GET** /payments | List payments
[**paymentsIdDelete**](DefaultApi.md#paymentsiddelete) | **DELETE** /payments/{id} | Delete a payment (rejected — audit record)
[**paymentsIdGet**](DefaultApi.md#paymentsidget) | **GET** /payments/{id} | Get a payment
[**paymentsIdRefundPost**](DefaultApi.md#paymentsidrefundpost) | **POST** /payments/{id}/refund | Refund a payment
[**paymentsIdVoidPost**](DefaultApi.md#paymentsidvoidpost) | **POST** /payments/{id}/void | Void a payment
[**paymentsPost**](DefaultApi.md#paymentspost) | **POST** /payments | Record a payment
[**plansGet**](DefaultApi.md#plansget) | **GET** /plans | List plans
[**plansIdPut**](DefaultApi.md#plansidput) | **PUT** /plans/{id} | Update a plan
[**plansPost**](DefaultApi.md#planspost) | **POST** /plans | Create a plan
[**reportsGet**](DefaultApi.md#reportsget) | **GET** /reports | Annual gym report


# **activityGet**
> ActivityListResponse activityGet()

Activity log

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.activityGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->activityGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ActivityListResponse**](ActivityListResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authLoginPost**
> AuthSessionResponse authLoginPost(loginInput)

Log in

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final LoginInput loginInput = ; // LoginInput | Credentials

try {
    final response = api.authLoginPost(loginInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->authLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginInput** | [**LoginInput**](LoginInput.md)| Credentials | 

### Return type

[**AuthSessionResponse**](AuthSessionResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authRefreshPost**
> AuthSessionResponse authRefreshPost(refreshInput)

Refresh access token

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final RefreshInput refreshInput = ; // RefreshInput | Refresh token

try {
    final response = api.authRefreshPost(refreshInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->authRefreshPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshInput** | [**RefreshInput**](RefreshInput.md)| Refresh token | 

### Return type

[**AuthSessionResponse**](AuthSessionResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authSignupPost**
> SignupResponse authSignupPost(signupInput)

Create an account

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final SignupInput signupInput = ; // SignupInput | New account

try {
    final response = api.authSignupPost(signupInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->authSignupPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **signupInput** | [**SignupInput**](SignupInput.md)| New account | 

### Return type

[**SignupResponse**](SignupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **dashboardGet**
> DashboardResponse dashboardGet()

Gym dashboard summary

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.dashboardGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->dashboardGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DashboardResponse**](DashboardResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gymsGet**
> List<GymResponse> gymsGet()

List gyms

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.gymsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->gymsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;GymResponse&gt;**](GymResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gymsIdDelete**
> SuccessResponse gymsIdDelete(id)

Delete a gym

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.gymsIdDelete(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->gymsIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gymsIdGet**
> GymResponse gymsIdGet(id)

Get a gym

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.gymsIdGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->gymsIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**GymResponse**](GymResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gymsIdPut**
> GymResponse gymsIdPut(id, gymUpdateInput)

Update a gym

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 
final GymUpdateInput gymUpdateInput = ; // GymUpdateInput | Gym changes

try {
    final response = api.gymsIdPut(id, gymUpdateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->gymsIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **gymUpdateInput** | [**GymUpdateInput**](GymUpdateInput.md)| Gym changes | 

### Return type

[**GymResponse**](GymResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gymsPost**
> GymResponse gymsPost(gymCreateInput)

Create a gym

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final GymCreateInput gymCreateInput = ; // GymCreateInput | New gym

try {
    final response = api.gymsPost(gymCreateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->gymsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gymCreateInput** | [**GymCreateInput**](GymCreateInput.md)| New gym | 

### Return type

[**GymResponse**](GymResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthGet**
> HealthResponse healthGet()

Health check

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.healthGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->healthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membersGet**
> MemberListResponse membersGet()

List members

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.membersGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membersGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MemberListResponse**](MemberListResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membersIdDelete**
> SuccessResponse membersIdDelete(id)

Soft-delete a member

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.membersIdDelete(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membersIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membersIdGet**
> MemberResponse membersIdGet(id)

Get a member

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.membersIdGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membersIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**MemberResponse**](MemberResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membersIdPut**
> MemberResponse membersIdPut(id, memberUpdateInput)

Update a member

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 
final MemberUpdateInput memberUpdateInput = ; // MemberUpdateInput | Member changes

try {
    final response = api.membersIdPut(id, memberUpdateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membersIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **memberUpdateInput** | [**MemberUpdateInput**](MemberUpdateInput.md)| Member changes | 

### Return type

[**MemberResponse**](MemberResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membersPost**
> MemberCreateResponse membersPost(memberCreateInput)

Create a member

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final MemberCreateInput memberCreateInput = ; // MemberCreateInput | New member

try {
    final response = api.membersPost(memberCreateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membersPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **memberCreateInput** | [**MemberCreateInput**](MemberCreateInput.md)| New member | 

### Return type

[**MemberCreateResponse**](MemberCreateResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membershipsGet**
> MembershipListResponse membershipsGet()

List memberships

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.membershipsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membershipsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MembershipListResponse**](MembershipListResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **membershipsIdReversePost**
> LifecycleResultResponse membershipsIdReversePost(id, paymentActionInput)

Reverse a plan purchase

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 
final PaymentActionInput paymentActionInput = ; // PaymentActionInput | Reversal request

try {
    final response = api.membershipsIdReversePost(id, paymentActionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->membershipsIdReversePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **paymentActionInput** | [**PaymentActionInput**](PaymentActionInput.md)| Reversal request | 

### Return type

[**LifecycleResultResponse**](LifecycleResultResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsGet**
> PaymentListResponse paymentsGet()

List payments

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.paymentsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->paymentsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PaymentListResponse**](PaymentListResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsIdDelete**
> paymentsIdDelete(id)

Delete a payment (rejected — audit record)

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 

try {
    api.paymentsIdDelete(id);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->paymentsIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsIdGet**
> PaymentResponse paymentsIdGet(id)

Get a payment

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 

try {
    final response = api.paymentsIdGet(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->paymentsIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**PaymentResponse**](PaymentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsIdRefundPost**
> LifecycleResultResponse paymentsIdRefundPost(id, paymentActionInput)

Refund a payment

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 
final PaymentActionInput paymentActionInput = ; // PaymentActionInput | Refund request

try {
    final response = api.paymentsIdRefundPost(id, paymentActionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->paymentsIdRefundPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **paymentActionInput** | [**PaymentActionInput**](PaymentActionInput.md)| Refund request | 

### Return type

[**LifecycleResultResponse**](LifecycleResultResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsIdVoidPost**
> LifecycleResultResponse paymentsIdVoidPost(id, paymentActionInput)

Void a payment

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 
final PaymentActionInput paymentActionInput = ; // PaymentActionInput | Void request

try {
    final response = api.paymentsIdVoidPost(id, paymentActionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->paymentsIdVoidPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **paymentActionInput** | [**PaymentActionInput**](PaymentActionInput.md)| Void request | 

### Return type

[**LifecycleResultResponse**](LifecycleResultResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsPost**
> PaymentCreateResponse paymentsPost(paymentCreateInput)

Record a payment

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final PaymentCreateInput paymentCreateInput = ; // PaymentCreateInput | New payment

try {
    final response = api.paymentsPost(paymentCreateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->paymentsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **paymentCreateInput** | [**PaymentCreateInput**](PaymentCreateInput.md)| New payment | 

### Return type

[**PaymentCreateResponse**](PaymentCreateResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **plansGet**
> PlanListResponse plansGet()

List plans

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.plansGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->plansGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PlanListResponse**](PlanListResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **plansIdPut**
> PlanResponse plansIdPut(id, planUpdateInput)

Update a plan

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final String id = id_example; // String | 
final PlanUpdateInput planUpdateInput = ; // PlanUpdateInput | Plan changes

try {
    final response = api.plansIdPut(id, planUpdateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->plansIdPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **planUpdateInput** | [**PlanUpdateInput**](PlanUpdateInput.md)| Plan changes | 

### Return type

[**PlanResponse**](PlanResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **plansPost**
> PlanResponse plansPost(planCreateInput)

Create a plan

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();
final PlanCreateInput planCreateInput = ; // PlanCreateInput | New plan

try {
    final response = api.plansPost(planCreateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->plansPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **planCreateInput** | [**PlanCreateInput**](PlanCreateInput.md)| New plan | 

### Return type

[**PlanResponse**](PlanResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportsGet**
> ReportsResponse reportsGet()

Annual gym report

### Example
```dart
import 'package:gym_api/api.dart';

final api = GymApi().getDefaultApi();

try {
    final response = api.reportsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->reportsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ReportsResponse**](ReportsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

