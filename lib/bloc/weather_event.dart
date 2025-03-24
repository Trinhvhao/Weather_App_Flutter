abstract class WeatherEvent {}

class FetchWeatherOnStartup extends WeatherEvent {} // Thêm sự kiện này
class FetchWeather extends WeatherEvent {}

class SelectHour extends WeatherEvent {
  final int hourIndex;

  SelectHour(this.hourIndex);
}

class SwitchTab extends WeatherEvent {
  final bool isForecastTab;

  SwitchTab(this.isForecastTab);
}

class InitializeData extends WeatherEvent {}

class UpdateWeatherData extends WeatherEvent {}

class SelectCity extends WeatherEvent {
  final String cityName; // Tên thành phố (tiếng Việt)

  SelectCity(this.cityName);
}
