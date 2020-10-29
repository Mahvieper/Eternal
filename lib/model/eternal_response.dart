class EternalResponse {
  String transactionId;

  EternalResponse({this.transactionId});

  EternalResponse.fromJson(Map<String, dynamic> json) {
    transactionId = json['transaction_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transaction_id'] = this.transactionId;
    return data;
  }
}