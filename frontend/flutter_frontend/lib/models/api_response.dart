class ApiResponse<T> {
  final T? data;
  final String? error;

  ApiResponse({this.data, this.error});

  /// Factory constructor for a successful response.
  factory ApiResponse.success(T data) {
    return ApiResponse(data: data, error: null);
  }

  /// Factory constructor for a failed response.
  factory ApiResponse.error(String error) {
    return ApiResponse(data: null, error: error);
  }

  /// Check if the response was successful.
  bool get isSuccess => error == null;
}