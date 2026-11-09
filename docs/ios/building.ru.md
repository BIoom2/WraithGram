# Сборка Wraithgram

[🇬🇧 English](building.md) · 🇷🇺 Русский

Wraithgram распространяется только исходным кодом: готовых IPA нет. Здесь написано, как собрать приложение
самому — на своём Mac или на Mac от GitHub через GitHub Actions.

- [Сначала: свой api_id и bundle ID](#сначала-свой-api_id-и-bundle-id)
- [Сборка на своём Mac](#сборка-на-своём-mac)
- [Сборка через GitHub Actions](#сборка-через-github-actions)
- [Push-уведомления](#push-уведомления)
- [Если что-то пошло не так](#если-что-то-пошло-не-так)

## Сначала: свой api_id и bundle ID

> [!WARNING]
> В шаблоне конфигурации, `build-system/wraithgram-configuration.example.json`, лежат **собственные публичные
> значения Telegram** из репозитория [Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS):
> `api_id` `8`, его `api_hash` и bundle ID `ph.telegra.Telegraph`. Они там, чтобы сборка для симулятора
> работала сразу. Перед сборкой для iPhone или перед тем, как делиться приложением, замени их на свои.

| Поле | Что туда вписать |
|------|------------------|
| `api_id`, `api_hash` | Свои значения. Войди на [my.telegram.org](https://my.telegram.org), открой **API development tools** и создай приложение. [Правила Telegram для разработчиков](https://github.com/TelegramMessenger/Telegram-iOS#creating-your-telegram-application) требуют свой `api_id`. |
| `bundle_id` | Свой идентификатор в обратной записи домена, например `com.yourname.wraithgram`. IPA с `ph.telegra.Telegraph` встала бы поверх официального Telegram, поэтому сборки для устройства с ним останавливаются. |

Скрипты сборки проверяют конфигурацию через `build-system/WGConfigCheck.py`: пока `api_id` равен `8`, они
выводят предупреждение, а сборка для устройства с `bundle_id` `ph.telegra.Telegraph` останавливается.

## Сборка на своём Mac

### Что нужно

- Mac с версией Xcode из [`versions.json`](../../versions.json) (поле `"xcode"`), выбранной через
  `sudo xcode-select -s /Applications/Xcode.app`. Скрипты привязывают сборку к этому Xcode, так что
  установленная рядом более новая бета не мешает.
- Python 3 и Git.
- Много свободного места. На нашем Mac результаты сборки заняли около 30 ГБ, а кэш Bazel в
  `~/telegram-bazel-cache` за много сборок вырос примерно до 50 ГБ.

Сам Bazel скачивается в `build-input/` при первом запуске.

### Шаги

1. Склонируй репозиторий вместе с подмодулями:

   ```sh
   git clone --recursive -j8 https://github.com/Wraithgram/ios.git
   cd ios
   ```

2. Создай свой файл конфигурации из шаблона:

   ```sh
   cp build-system/wraithgram-configuration.example.json build-system/wraithgram-configuration.json
   ```

   Файл в `.gitignore`. Впиши в него свои `api_id`, `api_hash` и `bundle_id`, как описано в разделе
   [Сначала](#сначала-свой-api_id-и-bundle-id). Для сборки под симулятор можно оставить значения шаблона.

3. Собери для симулятора:

   ```sh
   build-system/WGBuild.sh
   ```

   Скрипт показывает ход сборки и пишет полный лог в `/tmp/wg-build.log`. В конце он выводит `BUILD OK`, а
   приложение лежит в `bazel-bin/Telegram/Telegram.ipa`. Симулятор не проверяет подписи: без своих профилей
   скрипт подписывает тестовыми профилями Telegram из `build-system/fake-codesigning`.

4. Собери IPA для iPhone:

   ```sh
   build-system/WGBuildResign.sh 1
   ```

   `1` — номер сборки. Результат — `build-output/ipa/Wraithgram-for-resign.ipa` с твоим `bundle_id` и всеми
   расширениями (меню «Поделиться», виджеты, уведомления, Siri).

5. Установи IPA через программу подписи на iPhone, например ESign или LCSign, со своим сертификатом. Программа
   заменит подпись сборки на твою.

Чтобы подписывать на Mac своими профилями Apple Developer вместо программы подписи, смотри
[Подпись своими профилями](codesigning.ru.md).

### Необязательно: ядро VPN

Для VPN нужно ядро Xray, по умолчанию оно не собирается:

```sh
Wraithgram/Features/Vless/Core/build-core.sh
```

Нужен Go 1.26 или новее; при первом запуске скрипт скачивает [Xray-core](https://github.com/XTLS/Xray-core).
Без ядра приложение всё равно собирается, а экран VPN сообщает, что ядро не включено.

## Сборка через GitHub Actions

Workflow `.github/workflows/build.yml` («Build IPA for re-signing») запускает `WGBuildResign.sh` на Mac от
GitHub и отдаёт IPA на скачивание. Он запускается только вручную. Стандартные раннеры GitHub бесплатны для
публичных репозиториев.
В нашей пробной сборке на раннере `xcode-27` весь запуск занял около 1 часа 20 минут, а артефакт с IPA
весил около 78 МБ.

1. Сделай форк репозитория на GitHub.
2. Необязательно, но лучше сделать: в своём форке открой **Settings → Secrets and variables → Actions** и
   добавь два секрета репозитория, `TELEGRAM_API_ID` и `TELEGRAM_API_HASH`, со своими значениями с
   [my.telegram.org](https://my.telegram.org). Без них сборка возьмёт `api_id` `8` от Telegram и покажет
   предупреждение.
3. Открой вкладку **Actions** своего форка и включи workflow, если GitHub попросит.
4. Выбери **Build IPA for re-signing**, нажми **Run workflow** и заполни поля:
   - **bundle_id** — свой bundle ID, например `com.yourname.wraithgram`;
   - **build_number** — любое число, по умолчанию `1`;
   - **runner** — оставь `xcode-27`. На раннере должна быть версия Xcode из `versions.json`; какие версии
     Xcode стоят на каждом раннере, GitHub пишет в [actions/runner-images](https://github.com/actions/runner-images).
5. Когда запуск закончится, открой его и скачай артефакт `Wraithgram-for-resign-<номер сборки>` внизу
   страницы запуска. GitHub хранит его 3 дня. Скачивается ZIP, внутри — `Wraithgram-for-resign.ipa`.
6. Установи IPA через программу подписи, как в [шаге 5](#шаги) сборки на Mac.

Если запуск упал, он выкладывает лог сборки артефактом `build-log`.

## Push-уведомления

В наших проверках сборка с только что созданным `api_id` не получала push-уведомлений: когда приложение
регистрировалось для них, сервер Telegram отвечал `APP_PUSH_CERT_MISSING` — у Telegram нет push-сертификата
Apple для этого `api_id`. Сообщения приходили, когда приложение открывали. Всё остальное работает и без
push-уведомлений.

## Если что-то пошло не так

| Сообщение | Что делать |
|-----------|------------|
| `ERROR: build-system/wraithgram-configuration.json is missing` | Выполни шаг 2 [сборки на Mac](#шаги). |
| `ERROR: bundle_id in … is Telegram's own (ph.telegra.Telegraph)` | Впиши свой `bundle_id` в файл конфигурации (или в поле **bundle_id** workflow). |
| `WARNING: … uses Telegram's own api_id (8)` | Впиши свои `api_id` и `api_hash` в файл конфигурации (или в секреты workflow). |
| `ERROR: … neither applies nor is already applied` | Изменился подмодуль. Выполни `git submodule update --init --recursive` и собери снова. |
| `/Applications/Xcode_….app is not on this runner` (GitHub Actions) | Выбери метку раннера, на которой есть эта версия Xcode. |
