enum Status { initial, loading, success, error }

class FutureData<T> {
  Status? status;
  T? data;
  String? message;

  FutureData(this.status, this.data, this.message);

  FutureData.initial() : status = Status.initial;
  FutureData.loading() : status = Status.loading;
  FutureData.completed([this.data]) : status = Status.success;
  FutureData.error([this.message]) : status = Status.error;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}
