# trinh_van_hao

# TỔNG QUAN CẤU TRÚC DỰ ÁN
- Dựa trên thư mục lib, dự án có cấu trúc như sau: 
## Thư mục bloc: chứa các file liên quan đến quản lý trạng thái bằng flutter_bloc.
+ weather_bloc.dart: xử lý logic chính (lấy dữ liệu, chọn thành phố, chuyển tab.vv.v)
+ weather_event.dart: Định nghĩa các sự kiện (event) như chọn thành phố, chọn giờ, lấy dữ liệu.
+ weather_state.dart: định nghĩa các trạng thái (state) như đang tải, đã tải, lỗi.
## Thư mục model: Chứa các file liên quan đến định nghĩa mô hình dữ liệu.
- weatherModel.dart: Định nghĩa cấu trúc dữ liệu thời tiết (nhiệt độ, độ ẩm, tốc độ gió, v.v.v).
## Thư mục services: Chứa các file xử lý logic liên quan đến dữ liệu và dịch vụ.
- database_service.dart: Quản lý tương tác với Firestore (lưu trữ và đồng bộ dữ liệu).
- network_service.dart: Để kiểm tra kết nối mạng trong ứng dụng Flutter
- notification_service.dart: Xử lý thông báo
- weather_service.dart: Kết hợp API và Firestore để cung cấp dữ liệu thời tiết.
## Thư mục utils: Chứa các tiện ích hỗ trợ.
- weather_utils.dart: Lưu trữ dữ liệu tĩnh, các hàm tiện ích như lấy biểu tượng thời tiết (danh sách thành phố, ánh xạ tên thành phố).
## Thư mục views: Chứa các file giao diện người dùng.
- pages: các màn hình chính
+ bottomNavigationBar.dart: Thanh điều hướng dưới cùng (có thể chuyển giữa các trang).
+ forecast.dart: Trang dự báo thời tiết 7 ngày.
+ home.dart: Trang chính, hiển thị thời tiết hiện tại và theo giờ.
+ search.dart: Trang tìm kiếm thành phố.
+ setting.dart: Trang cài đặt (cập nhật dữ liệu, bật/tắt thông báo).
## Thư mục widgets: Các widgets tái sử dụng.
- air_quality_widget.dart: Widget hiển thị chất lượng không khí.
- item.dart: Widget hiển thị từng mục 

# Luồng hoạt động tổng quan
1. __Bắt đầu từ main.dart__
- Lí do: Đây là file khởi động của ứng dụng flutter, nơi ứng dụng được khởi tạo và các thành phần chính (như BlocProvider, định tuyến) được thiết lập. Bắt đầu từ đây giúp bạn hiểu cách ứng dụng khởi động và cách các thành phần khác được kết nối.
- File main.dart có ba phần chính:
+ Phần khởi tạo ứng dụng (main): Thiết lập các dịch vụ cần thiết (Firebase, Firestore, thông báo, locale) trước khi chạy ứng dụng.
+ Phần định nghĩa ứng dụng (MyApp): Thiết lập BlocProvider để quản lý trạng thái và định nghĩa các tuyến đường (routes) để điều hướng.
+ Phần màn hình splash (SplashScreen): Hiển thị giao diện khởi động trong khi dữ liệu thời tiết được tải.

2. __firebase_options.dart__
- Lý do: File này được sử dụng trong main.dart để khởi tạo Firebase. Giải thích file này ngay sau main.dart giúp bạn hiểu cách ứng dụng kết nối với Firebase, một phần quan trọng để lưu trữ và đồng bộ dữ liệu thời tiết.
- Nội dung cần giải thích:
Cấu hình Firebase (API key, project ID, v.v.).
Vai trò của file này trong việc hỗ trợ Firestore (được sử dụng bởi database_service.dart).

3. __Chuyển sang bloc (quản lý trạng thái)__
- Lý do: Sau khi khởi động ứng dụng, WeatherBloc được tạo trong main.dart. Đây là "trái tim" của ứng dụng, quản lý trạng thái và xử lý các sự kiện. Giải thích các file trong thư mục bloc sẽ giúp hiểu cách dữ liệu được quản lý.
- Trình tự trong thư mục bloc:
+ weather_event.dart: Định nghĩa các sự kiện (event) như FetchWeatherData, SelectCity, SelectHour, v.v. Giải thích trước để bạn hiểu các hành động mà ứng dụng có thể thực hiện.
+ weather_state.dart: Định nghĩa các trạng thái (state) như WeatherLoading, WeatherLoaded, WeatherError. Giải thích sau weather_event.dart để bạn hiểu kết quả của các sự kiện.
+ weather_bloc.dart: Kết hợp event và state, xử lý logic chính (lấy dữ liệu, cập nhật trạng thái). Giải thích cuối cùng trong thư mục bloc để bạn thấy cách các sự kiện được xử lý và trạng thái được cập nhật.

4. __Chuyển sang model (weatherModel.dart)__
- Lý do: WeatherBloc sử dụng WeatherModel để lưu trữ dữ liệu thời tiết. Giải thích file này ngay sau bloc giúp hiểu cấu trúc dữ liệu mà ứng dụng sử dụng.
- Nội dung cần giải thích: 
+ Cấu trúc của weathermodel( các thuộc tính)
+ Cách dữ liệu từ API được chuyển thành weatherModel

5. __Chuyển sang services (xử lý dữ liệu)__
- Lý do: WeatherBloc gọi các dịch vụ trong thư mục services để lấy dữ liệu thời tiết. Giải thích các file này sau model để bạn hiểu cách dữ liệu được lấy và lưu trữ.
- Trình tự trong thư mục services:
+ network_service.dart: Kiểm tra kết nối mạng của app flutter
database_service.dart: Lưu trữ và đồng bộ dữ liệu với Firestore.
+ weather_service.dart: Kết hợp network_service.dart và database_service.dart để cung cấp dữ liệu cho WeatherBloc. Giải thích sau cùng để bạn thấy cách hai dịch vụ trên được phối hợp.
+ notification_service.dart: Xử lý thông báo (có thể chưa triển khai đầy đủ). Giải thích cuối cùng vì tính năng này không phải là cốt lõi.

6. __Chuyển sang utils (weather_utils.dart)__
- Lý do: Sau khi hiểu cách dữ liệu được lấy và lưu trữ, bạn cần biết các tiện ích hỗ trợ (danh sách thành phố, ánh xạ biểu tượng thời tiết) được sử dụng trong ứng dụng. File - - - weather_utils.dart (đã tích hợp từ static_file.dart và weather_utils.dart) được sử dụng bởi nhiều thành phần khác, nên giải thích ở đây.
- Nội dung cần giải thích:
+ Dữ liệu tĩnh: Danh sách thành phố (apiLocations), ánh xạ tên (locationNameMap), tọa độ (cityCoordinates).
+ Hàm tiện ích: isDayTime, getWeatherIcon

7. __Chuyển sang view/pages (giao diện người dùng)__
- Lý do: Sau khi hiểu cách dữ liệu được lấy và xử lý, bạn cần biết cách dữ liệu được hiển thị cho người dùng. Thư mục view/pages chứa các màn hình chính, và giải thích ở đây giúp bạn thấy cách trạng thái từ WeatherBloc được sử dụng.
- Trình tự trong thư mục view/pages:
bottomNavigationBar.dart: Thanh điều hướng dưới cùng, cho phép chuyển đổi giữa các trang. Giải thích trước để bạn hiểu cách điều hướng trong ứng dụng.
- home.dart: Trang chính, hiển thị thời tiết hiện tại và theo giờ. Giải thích sau - bottomNavigationBar.dart vì đây là trang mặc định.
- search.dart: Trang tìm kiếm thành phố. Giải thích sau home.dart vì người dùng có thể chuyển từ home.dart sang đây để chọn thành phố.
- forecast.dart: Trang dự báo 7 ngày. Giải thích sau search.dart vì người dùng có thể vào từ home.dart.
- setting.dart: Trang cài đặt (cập nhật dữ liệu, bật/tắt thông báo). Giải thích cuối cùng vì đây là trang phụ.

8. __Chuyển sang view/widgets (các widget tái sử dụng)__
- Lý do: Các widget trong thư mục này được sử dụng bởi các trang trong view/pages. Giải thích sau cùng để bạn hiểu cách các thành phần giao diện được tái sử dụng.
- Trình tự trong thư mục view/widgets:
+ air_quality_widget.dart: Widget hiển thị chất lượng không khí, được sử dụng trong home.dart.
+ item.dart: Widget hiển thị từng mục (có thể dùng trong danh sách thời tiết theo giờ).