import 'package:chat_app/models/call_model.dart';
import 'package:chat_app/services/api_service.dart';
import 'package:get/get.dart';

class StatsController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<CallModel> _callHistory = <CallModel>[].obs;
  final RxBool _isFetchingHistory = false.obs;

  // Pagination vars
  final RxInt _page = 1.obs;
  final RxBool _hasMore = true.obs;
  final int _limit = 20;

  List<CallModel> get callHistory => _callHistory;
  bool get isFetchingHistory => _isFetchingHistory.value;
  bool get hasMore => _hasMore.value;

  set setCallHistory(List<CallModel> calls) => _callHistory.value = calls;

  @override
  void onInit() {
    super.onInit();
    fetchCallHistory();
  }

  void add(CallModel call) {
    _callHistory.insert(0, call);
  }

  void edit(String id,
      {CallStatus? status, DateTime? startDate, DateTime? endDate}) {
    final index = _callHistory.indexWhere((call) => call.callId == id);

    if (index != -1) {
      CallModel currentCall = _callHistory[index];
      CallModel updatedCall = currentCall.copyWith(
        status: status,
        startTime: startDate,
        endTime: endDate,
      );
      _callHistory[index] = updatedCall;
      _callHistory.refresh();
    }
  }

  Future<void> refreshHistory() async {
    _page.value = 1;
    _hasMore.value = true;
    await fetchCallHistory(isRefresh: true);
  }

  Future<void> fetchCallHistory({bool isRefresh = false}) async {
    if (_isFetchingHistory.value) return;
    if (!_hasMore.value && !isRefresh) return;

    _isFetchingHistory.value = true;

    try {
      await _fetchCallHistoryFromAPI(page: _page.value, limit: _limit);
    } catch (e) {
      print("Error fetching call history: $e");
    } finally {
      _isFetchingHistory.value = false;
    }
  }

  Future<void> _fetchCallHistoryFromAPI(
      {required int page, required int limit}) async {
    try {
      final response =
          await _apiService.fetchCallHistory(page: page, limit: limit);

      List<dynamic> data = response.data['data'] ?? response.data;
      final calls = data.map((e) => CallModel.fromJson(e)).toList();

      if (calls.length < limit) {
        _hasMore.value = false;
      }

      if (page == 1) {
        _callHistory.assignAll(calls);
      } else {
        _callHistory.addAll(calls);
      }

      if (_hasMore.value) {
        _page.value++;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCallHistory() async {
    try {
      await _apiService.clearCallHistory();
      clear();
      Get.snackbar("Success", "Call history cleared");
    } catch (e) {
      print("Error clearing history: $e");
      Get.snackbar("Error", "Failed to clear history");
    }
  }

  void clear() {
    _callHistory.clear();
    _isFetchingHistory.value = false;
    _page.value = 1;
    _hasMore.value = true;
  }
}
