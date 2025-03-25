abstract class WeatherEvent {}

// FetchWeather: Yêu cầu lấy dữ liệu thời tiết (từ API hoặc Firestore).
class FetchWeather extends WeatherEvent {}

// Chọn một giờ cụ thể trong danh sách thời tiết theo giờ (ví dụ: trong home.dart, khi người dùng nhấn vào một giờ). Sự kiện này mang theo hourIndex (chỉ số của giờ được chọn).
class SelectHour extends WeatherEvent {
  final int hourIndex;

  SelectHour(this.hourIndex);
}

// Chuyển đổi giữa các tab trong home.dart (tab "Dự báo" và tab "Không khí"). Sự kiện này mang theo isForecastTab (true nếu là tab dự báo, false nếu là tab không khí).
class SwitchTab extends WeatherEvent {
  final bool isForecastTab;

  SwitchTab(this.isForecastTab);
}

// Khởi tạo dữ liệu sau khi lấy thành công, ví dụ: tìm giờ gần nhất để hiển thị.
class InitializeData extends WeatherEvent {}

// Cập nhật dữ liệu thời tiết (tự động hoặc thủ công). Đây là sự kiện chính được gửi từ main.dart khi ứng dụng khởi động.
class UpdateWeatherData extends WeatherEvent {}

// SelectCity: Chọn một thành phố để hiển thị thời tiết
class SelectCity extends WeatherEvent {
  final String cityName; // Tên thành phố (tiếng Việt)

  SelectCity(this.cityName);
}
