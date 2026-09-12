import 'package:test/test.dart';
import 'package:gym_api/gym_api.dart';


/// tests for DefaultApi
void main() {
  final instance = GymApi().getDefaultApi();

  group(DefaultApi, () {
    // Activity log
    //
    //Future<ActivityListResponse> activityGet() async
    test('test activityGet', () async {
      // TODO
    });

    // Log in
    //
    //Future<AuthSessionResponse> authLoginPost(LoginInput loginInput) async
    test('test authLoginPost', () async {
      // TODO
    });

    // Refresh access token
    //
    //Future<AuthSessionResponse> authRefreshPost(RefreshInput refreshInput) async
    test('test authRefreshPost', () async {
      // TODO
    });

    // Create an account
    //
    //Future<SignupResponse> authSignupPost(SignupInput signupInput) async
    test('test authSignupPost', () async {
      // TODO
    });

    // Gym dashboard summary
    //
    //Future<DashboardResponse> dashboardGet() async
    test('test dashboardGet', () async {
      // TODO
    });

    // List gyms
    //
    //Future<List<GymResponse>> gymsGet() async
    test('test gymsGet', () async {
      // TODO
    });

    // Delete a gym
    //
    //Future<SuccessResponse> gymsIdDelete(String id) async
    test('test gymsIdDelete', () async {
      // TODO
    });

    // Get a gym
    //
    //Future<GymResponse> gymsIdGet(String id) async
    test('test gymsIdGet', () async {
      // TODO
    });

    // Update a gym
    //
    //Future<GymResponse> gymsIdPut(String id, GymUpdateInput gymUpdateInput) async
    test('test gymsIdPut', () async {
      // TODO
    });

    // Create a gym
    //
    //Future<GymResponse> gymsPost(GymCreateInput gymCreateInput) async
    test('test gymsPost', () async {
      // TODO
    });

    // Health check
    //
    //Future<HealthResponse> healthGet() async
    test('test healthGet', () async {
      // TODO
    });

    // List members
    //
    //Future<MemberListResponse> membersGet() async
    test('test membersGet', () async {
      // TODO
    });

    // Soft-delete a member
    //
    //Future<SuccessResponse> membersIdDelete(String id) async
    test('test membersIdDelete', () async {
      // TODO
    });

    // Get a member
    //
    //Future<MemberResponse> membersIdGet(String id) async
    test('test membersIdGet', () async {
      // TODO
    });

    // Update a member
    //
    //Future<MemberResponse> membersIdPut(String id, MemberUpdateInput memberUpdateInput) async
    test('test membersIdPut', () async {
      // TODO
    });

    // Create a member
    //
    //Future<MemberCreateResponse> membersPost(MemberCreateInput memberCreateInput) async
    test('test membersPost', () async {
      // TODO
    });

    // List memberships
    //
    //Future<MembershipListResponse> membershipsGet() async
    test('test membershipsGet', () async {
      // TODO
    });

    // Reverse a plan purchase
    //
    //Future<LifecycleResultResponse> membershipsIdReversePost(String id, PaymentActionInput paymentActionInput) async
    test('test membershipsIdReversePost', () async {
      // TODO
    });

    // List payments
    //
    //Future<PaymentListResponse> paymentsGet() async
    test('test paymentsGet', () async {
      // TODO
    });

    // Delete a payment (rejected — audit record)
    //
    //Future paymentsIdDelete(String id) async
    test('test paymentsIdDelete', () async {
      // TODO
    });

    // Get a payment
    //
    //Future<PaymentResponse> paymentsIdGet(String id) async
    test('test paymentsIdGet', () async {
      // TODO
    });

    // Refund a payment
    //
    //Future<LifecycleResultResponse> paymentsIdRefundPost(String id, PaymentActionInput paymentActionInput) async
    test('test paymentsIdRefundPost', () async {
      // TODO
    });

    // Void a payment
    //
    //Future<LifecycleResultResponse> paymentsIdVoidPost(String id, PaymentActionInput paymentActionInput) async
    test('test paymentsIdVoidPost', () async {
      // TODO
    });

    // Record a payment
    //
    //Future<PaymentCreateResponse> paymentsPost(PaymentCreateInput paymentCreateInput) async
    test('test paymentsPost', () async {
      // TODO
    });

    // List plans
    //
    //Future<PlanListResponse> plansGet() async
    test('test plansGet', () async {
      // TODO
    });

    // Update a plan
    //
    //Future<PlanResponse> plansIdPut(String id, PlanUpdateInput planUpdateInput) async
    test('test plansIdPut', () async {
      // TODO
    });

    // Create a plan
    //
    //Future<PlanResponse> plansPost(PlanCreateInput planCreateInput) async
    test('test plansPost', () async {
      // TODO
    });

    // Annual gym report
    //
    //Future<ReportsResponse> reportsGet() async
    test('test reportsGet', () async {
      // TODO
    });

  });
}
