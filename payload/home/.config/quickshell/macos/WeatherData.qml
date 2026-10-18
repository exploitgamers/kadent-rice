pragma Singleton

import QtQuick
import Quickshell

// Weather for the desktop widget, from Open-Meteo (free, no key). Location is
// ~/.config/caelestia/macos.json widgets.weatherLocation ("City" or "lat,lon"),
// or, when empty, approximated from your IP address like Caelestia does.
// Only fetches while a weather widget exists (or the widget gallery is open).
Singleton {
    id: root

    readonly property bool active: Config.widgetItems.some(w => w.type === "weather" || w.type === "conditions") || Shared.widgetEdit

    property string city: ""
    property bool loaded: false
    property bool failed: false
    property real temp: 0
    property real feelsLike: 0
    property int code: 0
    property bool isDay: true
    property real high: 0
    property real low: 0
    property var hourly: [] // [{ hour: "14", temp, code, isDay }]
    property var daily: []  // [{ day: "Mon", high, low, code }]
    property real humidity: 0
    property real wind: 0       // km/h
    property real uv: 0
    property string sunrise: ""
    property string sunset: ""
    property real lat: 0
    property real lon: 0

    readonly property string unitSymbol: Config.tempUnit === "F" ? "°F" : "°C"
    readonly property string condition: describe(code)
    readonly property string icon: iconFor(code, isDay)

    function describe(c: int): string {
        if (c === 0) return "Clear";
        if (c === 1) return "Mostly Clear";
        if (c === 2) return "Partly Cloudy";
        if (c === 3) return "Cloudy";
        if (c === 45 || c === 48) return "Fog";
        if (c >= 51 && c <= 57) return "Drizzle";
        if (c >= 61 && c <= 67) return c >= 65 ? "Heavy Rain" : "Rain";
        if (c >= 71 && c <= 77) return "Snow";
        if (c >= 80 && c <= 82) return "Showers";
        if (c === 85 || c === 86) return "Snow Showers";
        if (c >= 95) return "Thunderstorms";
        return "—";
    }

    // Material Symbols names
    function iconFor(c: int, day: bool): string {
        if (c === 0) return day ? "clear_day" : "clear_night";
        if (c === 1 || c === 2) return day ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 3) return "cloud";
        if (c === 45 || c === 48) return "foggy";
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rainy";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "weather_snowy";
        if (c >= 95) return "thunderstorm";
        return "cloud";
    }

    // Weather widgets' click: the full forecast for this place in your browser
    function openForecast(): void {
        Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent("weather " + (city || ""))]);
    }

    function get(url: string, done: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let data = null;
            try {
                if (xhr.status === 200)
                    data = JSON.parse(xhr.responseText);
            } catch (e) {}
            done(data);
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fail(): void {
        failed = !loaded;
        retry.restart();
    }

    function refresh(): void {
        const loc = Config.weatherLocation.trim();
        const parts = loc.split(",");
        if (loc && parts.length === 2 && !isNaN(parseFloat(parts[0])) && !isNaN(parseFloat(parts[1]))) {
            fetchForecast(parseFloat(parts[0]), parseFloat(parts[1]), city || "My Location");
        } else if (loc) {
            get(`https://geocoding-api.open-meteo.com/v1/search?count=1&name=${encodeURIComponent(loc)}`, d => {
                const r = d?.results?.[0];
                r ? fetchForecast(r.latitude, r.longitude, r.name) : fail();
            });
        } else {
            get("http://ip-api.com/json?fields=status,city,lat,lon", d => {
                d?.status === "success" ? fetchForecast(d.lat, d.lon, d.city) : fail();
            });
        }
    }

    function fetchForecast(lat: real, lon: real, place: string): void {
        const unit = Config.tempUnit === "F" ? "&temperature_unit=fahrenheit" : "";
        get(`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&timezone=auto&forecast_days=6${unit}`
            + "&current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max", d => {
            if (!d?.current)
                return fail();
            city = place;
            temp = d.current.temperature_2m;
            feelsLike = d.current.apparent_temperature;
            code = d.current.weather_code;
            isDay = d.current.is_day === 1;
            high = d.daily.temperature_2m_max[0];
            low = d.daily.temperature_2m_min[0];
            humidity = d.current.relative_humidity_2m ?? 0;
            wind = d.current.wind_speed_10m ?? 0;
            uv = d.daily.uv_index_max?.[0] ?? 0;
            sunrise = (d.daily.sunrise?.[0] ?? "").slice(11, 16);
            sunset = (d.daily.sunset?.[0] ?? "").slice(11, 16);
            root.lat = lat;
            root.lon = lon;

            // next 6 hours, starting with the current one (times are local, "YYYY-MM-DDTHH:MM")
            const nowKey = d.current.time.slice(0, 13);
            const start = Math.max(0, d.hourly.time.findIndex(t => t.slice(0, 13) === nowKey));
            const hrs = [];
            for (let i = start; i < Math.min(start + 6, d.hourly.time.length); i++)
                hrs.push({ hour: i === start ? "Now" : d.hourly.time[i].slice(11, 13), temp: d.hourly.temperature_2m[i],
                           code: d.hourly.weather_code[i], isDay: d.hourly.is_day[i] === 1 });
            hourly = hrs;

            const days = [];
            for (let i = 0; i < d.daily.time.length; i++) {
                const date = new Date(d.daily.time[i] + "T12:00:00");
                days.push({ day: i === 0 ? "Today" : Qt.locale().dayName(date.getDay(), Locale.ShortFormat),
                            high: d.daily.temperature_2m_max[i], low: d.daily.temperature_2m_min[i], code: d.daily.weather_code[i] });
            }
            daily = days;
            loaded = true;
            failed = false;
        });
    }

    onActiveChanged: if (active && !loaded) refresh()
    Component.onCompleted: if (active) refresh()

    Connections {
        target: Config

        function onWeatherLocationChanged(): void { if (root.active) root.refresh(); }
        function onTempUnitChanged(): void { if (root.active) root.refresh(); }
    }

    Timer {
        running: root.active
        interval: 20 * 60 * 1000
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: retry

        interval: 60 * 1000
        onTriggered: if (root.active) root.refresh()
    }
}
