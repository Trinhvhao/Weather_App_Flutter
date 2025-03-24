// lib/utils/weather_utils.dart

/// Kiểm tra thời gian hiện tại (ban ngày hay ban đêm)
bool isDayTime() {
  final now = DateTime.now();
  final hour = now.hour;
  return hour >= 6 && hour < 18; // Ban ngày từ 6h sáng đến 18h
}

/// Ánh xạ description với icon thời tiết, có phân biệt ngày/đêm
String getWeatherIcon(String description) {
  final bool isDay = isDayTime();
  switch (description.toLowerCase()) {
    case 'clear sky':
      return isDay ? 'assets/img/13.png' : 'assets/img/14.png';
    case 'few clouds':
      return isDay ? 'assets/img/1.png' : 'assets/img/10.png';
    case 'scattered clouds':
      return 'assets/img/4.png';
    case 'broken clouds':
      return isDay ? 'assets/img/4.png' : 'assets/img/10.png';
    case 'overcast clouds':
      return 'assets/img/4.png';
    case 'light rain':
      return isDay ? 'assets/img/2.png' : 'assets/img/11.png';
    case 'moderate rain':
    case 'heavy rain':
      return isDay ? 'assets/img/5.png' : 'assets/img/11.png';
    case 'thunderstorm':
      return 'assets/img/7.png';
    case 'snow':
      return isDay ? 'assets/img/3.png' : 'assets/img/12.png';
    case 'mist':
    case 'fog':
      return 'assets/img/4.png';
    default:
      return 'assets/img/4.png'; // Icon mặc định
  }
}
