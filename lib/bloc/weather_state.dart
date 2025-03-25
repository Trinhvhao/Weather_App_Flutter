import 'package:equatable/equatable.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart';

// Lớp trừu tượng `WeatherState` đóng vai trò là lớp cha cho tất cả các trạng thái của ứng dụng thời tiết.
// Kế thừa từ `Equatable` giúp so sánh các trạng thái một cách hiệu quả mà không cần override `==` và `hashCode`.
abstract class WeatherState extends Equatable {
  final bool
      isConnected; // Biến này theo dõi trạng thái kết nối mạng (true nếu có mạng, false nếu không).

  const WeatherState(
      {required this.isConnected}); // Constructor bắt buộc phải có giá trị cho `isConnected`.

  @override
  List<Object?> get props => [
        isConnected
      ]; // Cung cấp danh sách các thuộc tính để so sánh khi trạng thái thay đổi.
}

// Trạng thái khởi tạo ban đầu của ứng dụng thời tiết, khi chưa có dữ liệu nào được tải.
class WeatherInitial extends WeatherState {
  const WeatherInitial({bool isConnected = true})
      : super(isConnected: isConnected);
}

// Trạng thái khi ứng dụng đang tải dữ liệu thời tiết từ API hoặc cơ sở dữ liệu.
class WeatherLoading extends WeatherState {
  const WeatherLoading({bool isConnected = true})
      : super(isConnected: isConnected);
}

// Trạng thái khi dữ liệu thời tiết đã được tải thành công.
class WeatherLoaded extends WeatherState {
  final List<WeatherModel>
      weatherList; // Danh sách các dữ liệu thời tiết được tải.
  final int hourIndex; // Chỉ mục giờ hiện tại trong dữ liệu dự báo.
  final bool
      isForecastTab; // Biến xác định xem tab hiển thị có phải là dự báo thời tiết không.
  final bool isDataReady; // Cho biết dữ liệu đã sẵn sàng hiển thị hay chưa.
  final bool
      userSelectedHour; // Xác định xem người dùng có chọn một giờ cụ thể không.
  final String myLocation; // Tên địa điểm mà người dùng đang xem dự báo.
  final int myLocationIndex; // Chỉ mục của địa điểm trong danh sách lưu trữ.

  // Constructor khởi tạo các giá trị mặc định, nếu không có giá trị truyền vào thì dùng mặc định.
  const WeatherLoaded({
    required this.weatherList,
    this.hourIndex =
        0, // Mặc định là 0 (tức là dữ liệu của giờ đầu tiên trong danh sách).
    this.isForecastTab = true, // Mặc định là đang ở tab dự báo.
    this.isDataReady = false, // Ban đầu dữ liệu chưa sẵn sàng.
    this.userSelectedHour =
        false, // Ban đầu người dùng chưa chọn giờ cụ thể nào.
    this.myLocation =
        WeatherUtils.defaultDisplayLocation, // Vị trí mặc định (lấy từ utils).
    this.myLocationIndex = 0, // Mặc định vị trí đầu tiên trong danh sách.
    bool isConnected = true, // Mặc định là có kết nối mạng.
  }) : super(isConnected: isConnected);

  // Phương thức `copyWith` giúp tạo một bản sao của trạng thái hiện tại nhưng có thể thay đổi một số giá trị.
  // Điều này rất hữu ích trong Bloc khi cần cập nhật một phần của trạng thái mà không làm thay đổi toàn bộ dữ liệu.
  WeatherLoaded copyWith({
    List<WeatherModel>? weatherList,
    int? hourIndex,
    bool? isForecastTab,
    bool? isDataReady,
    bool? userSelectedHour,
    String? myLocation,
    int? myLocationIndex,
    bool? isConnected,
  }) {
    return WeatherLoaded(
      weatherList: weatherList ??
          this.weatherList, // Nếu không có giá trị mới, giữ nguyên giá trị cũ.
      hourIndex: hourIndex ?? this.hourIndex,
      isForecastTab: isForecastTab ?? this.isForecastTab,
      isDataReady: isDataReady ?? this.isDataReady,
      userSelectedHour: userSelectedHour ?? this.userSelectedHour,
      myLocation: myLocation ?? this.myLocation,
      myLocationIndex: myLocationIndex ?? this.myLocationIndex,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [
        weatherList,
        hourIndex,
        isForecastTab,
        isDataReady,
        userSelectedHour,
        myLocation,
        myLocationIndex,
        isConnected,
      ];
}

// Trạng thái khi xảy ra lỗi trong quá trình tải dữ liệu thời tiết.
class WeatherError extends WeatherState {
  final String
      message; // Thông báo lỗi (ví dụ: "Không thể kết nối tới máy chủ").

  const WeatherError(this.message, {bool isConnected = true})
      : super(isConnected: isConnected);

  @override
  List<Object?> get props => [
        message,
        isConnected
      ]; // Thêm `message` vào danh sách props để hỗ trợ so sánh.
}
