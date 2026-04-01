# VPNeo — Статус реализации

## Что реализовано

### Архитектура
- MVVM, SwiftUI, async/await, iOS 17+
- 3 таргета: Main App, VPNTunnelExtension, VPNordWidget
- App Groups (`group.com.vpnord.app`) для IPC между таргетами
- URL Scheme `vpnord://` для deep link из виджета
- SwiftyXrayKit подключён через SPM

### Таб 1: VPN (главный экран)
- Большая кнопка connect с кольцевой анимацией
- Состояния: Disconnected / Connecting / Connected / Error
- Таймер подключения (00:00:00)
- Карточка активного сервера (имя, адрес, протокол)
- Список серверов (swipe-to-delete, выбор активного)
- Добавление сервера: вставка vless:// URI
- Добавление сервера: QR-код сканер (AVFoundation)
- Добавление сервера: вставка из буфера обмена
- Парсер VLESS URI (TLS, Reality, WebSocket, gRPC, HTTP/2)
- Проверка дубликатов при импорте

### Таб 2: Speed Test (без изменений)
- Тест скорости: Ping → Download → Upload
- Круговой gauge с анимацией
- Метрики: ping, jitter, download, upload
- История результатов (до 50, UserDefaults)

### Таб 3: DNS Leak Test (новый)
- Тест через bash.ws API
- Визуальный щит: зелёный (safe) / красный (leak) / серый (idle)
- Анимация при тестировании (symbolEffect pulse)
- Список обнаруженных DNS-серверов (IP, страна, флаг, ISP)
- Предупреждение если VPN не подключён
- Информационная карточка "What is DNS Leak?"

### Таб 4: Settings
- CTA карточка (Protect Your Connection → Telegram)
- VPN Settings: Auto-Connect toggle, Kill Switch toggle
- История Speed Test
- Ссылки: Support, Telegram, Privacy, Terms
- Версия приложения

### VPN Core
- VPNManager — обёртка NEVPNManager/NETunnelProviderManager
- Connect/Disconnect с наблюдением NEVPNStatus
- Kill Switch через `includeAllNetworks`
- PacketTunnelProvider с интеграцией SwiftyXrayKit (XRayTunnel)
- XrayConfigBuilder — генерация Xray JSON из VLESSConfig
- Поддержка: VLESS + TLS/Reality + TCP/WS/gRPC/H2

### Widget
- Small widget: статус VPN (connected/disconnected)
- Имя сервера
- Tap открывает приложение через URL scheme

### Хранение данных
- SharedDefaults — App Group UserDefaults (vpnState, servers, settings)
- ServerStore — CRUD серверов с персистентностью
- TestHistoryStore — история speed test (без изменений)

### Дизайн система (без изменений)
- Тёмная тема: #0A0E14 фон, #00D4AA акцент, #6C63FF вторичный
- Компоненты: GlassCard, MetricTile, VombatButton, SpeedGaugeView
- Extensions: Color+Hex, Double+Formatting

### Xcode настройки
- Bundle ID: com.vpnord.app
- Display Name: VPNeo
- Network Extensions capability (packet-tunnel)
- App Groups для всех таргетов
- Camera permission (QR сканер)
- URL Types: vpnord://
- Deployment Target: iOS 17.0

---

## Удалённые экраны
- Ping Test (PingView, PingViewModel, PingService)
- WiFi Info (WiFiInfoView, WiFiInfoViewModel, WiFiService)
- DNS Lookup (DNSLookupView, DNSLookupViewModel, DNSService)

---

## Что осталось сделать

### Критично
- [ ] Тест VPN на реальном устройстве (симулятор не поддерживает NE)
- [ ] GeoIP/GeoSite данные для Xray (скачивание/bundling)
- [ ] Обработка reconnect при смене сети (Wi-Fi ↔ Cellular)

### Улучшения
- [ ] Ping/latency для каждого сервера в списке
- [ ] Subscription URL импорт (автообновление серверов)
- [ ] Уведомления о разрыве VPN
- [ ] Логирование подключений
- [ ] Onboarding экран

### Подготовка к релизу
- [ ] Иконка приложения
- [ ] Скриншоты для App Store
- [ ] Privacy Policy обновление (VPN)
- [ ] App Store описание
- [ ] Codemagic CI/CD настройка
