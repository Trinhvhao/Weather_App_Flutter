import requests

def get_all_weather_icons():
    base_url = "https://openweathermap.org/img/wn/"
    icon_codes = [
        "01d", "01n", "02d", "02n", "03d", "03n", "04d", "04n",
        "09d", "09n", "10d", "10n", "11d", "11n", "13d", "13n", "50d", "50n"
    ]
    
    icon_urls = {code: f"{base_url}{code}@2x.png" for code in icon_codes}
    return icon_urls

# Example usage
icons = get_all_weather_icons()
for code, url in icons.items():
    print(f"{code}: {url}")
