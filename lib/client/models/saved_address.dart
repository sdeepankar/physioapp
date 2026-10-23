class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.addressType,
    required this.address,
    required this.area,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.landmark,
  });

  final String id;
  final String label;
  final String addressType;
  final String address;
  final String area;
  final String city;
  final String state;
  final String pinCode;
  final String landmark;

  String get localitySummary =>
      [area, city, state, pinCode].where((part) => part.isNotEmpty).join(', ');

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String,
    label: json['label'] as String,
    addressType: json['addressType'] as String,
    address: json['address'] as String,
    area: json['area'] as String,
    city: json['city'] as String,
    state: json['state'] as String,
    pinCode: json['pinCode'] as String,
    landmark: json['landmark'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'addressType': addressType,
    'address': address,
    'area': area,
    'city': city,
    'state': state,
    'pinCode': pinCode,
    'landmark': landmark,
  };
}
