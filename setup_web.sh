#!/usr/bin/env bash
set -e
flutter create --platforms=web,android,ios .
flutter pub get
flutter run -d chrome
