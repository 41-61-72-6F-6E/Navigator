# Navigator
## Description
DB-Navigator like App with a better UI and open-source.

## Setup
To use the App you need a working Instance of [db-rest](https://github.com/derhuerst/db-rest)  

In the root of `/navigator`, create a `.env` file with your API base URL:
```
#navigator/.env
API_URL=<your_api_url_here>:<your_port_here>
```
Then run the app with the environment file as compile-time configuration:
```
flutter run --dart-define-from-file=.env
```
Release builds use the same option with `flutter build`.
