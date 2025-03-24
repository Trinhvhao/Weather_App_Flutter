class StaticFile {
  // Danh sách các thành phố (tên tiếng Anh để gọi API và làm tên document)
  static const List<String> apiLocations = [
    "Hanoi",
    "Ho Chi Minh City",
    "Da Nang",
    "Haiphong",
    "Can Tho",
    "Hue",
    "Nha Trang",
    "Quy Nhon",
    "Vinh",
    "Da Lat",
  ];

  // Map ánh xạ tên tiếng Anh sang tiếng Việt (cho trường name)
  static const Map<String, String> locationNameMap = {
    "Hanoi": "Hà Nội",
    "Ho Chi Minh City": "TP. Hồ Chí Minh",
    "Da Nang": "Đà Nẵng",
    "Haiphong": "Hải Phòng",
    "Can Tho": "Cần Thơ",
    "Hue": "Huế",
    "Nha Trang": "Nha Trang",
    "Quy Nhon": "Quy Nhơn",
    "Vinh": "Vĩnh",
    "Da Lat": "Đà Lạt",
  };

  // Map ánh xạ tên tiếng Anh với city ID (dùng cho endpoint /group)
  static const Map<String, String> cityIdMap = {
    "Hanoi": "1581130",
    "Ho Chi Minh City": "1566083",
    "Da Nang": "1583992",
    "Haiphong": "1581298",
    "Can Tho": "1586203",
    "Hue": "1580240",
    "Nha Trang": "1572151",
    "Quy Nhon": "1568574",
    "Vinh": "1562798",
    "Da Lat": "1584071",
  };

  // Map ánh xạ tên tiếng Anh với tọa độ (lat, lon)
  static const Map<String, Map<String, double>> cityCoordinates = {
    "Hanoi": {"lat": 21.0285, "lon": 105.8542},
    "Ho Chi Minh City": {"lat": 10.7769, "lon": 106.7009},
    "Da Nang": {"lat": 16.0544, "lon": 108.2022},
    "Haiphong": {"lat": 20.8449, "lon": 106.6881},
    "Can Tho": {"lat": 10.0452, "lon": 105.7469},
    "Hue": {"lat": 16.4637, "lon": 107.5909},
    "Nha Trang": {"lat": 12.2388, "lon": 109.1967},
    "Quy Nhon": {"lat": 13.7820, "lon": 109.2196},
    "Vinh": {"lat": 18.6796, "lon": 105.6813},
    "Da Lat": {"lat": 11.9404, "lon": 108.4583},
  };

  // Thành phố mặc định để hiển thị
  static const String defaultDisplayLocation = "Hà Nội";

  // Chỉ số của thành phố được chọn trong danh sách apiLocations
  static int myLocationIndex = 0;
}
