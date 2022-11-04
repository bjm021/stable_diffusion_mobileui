# stable_diffusion_mobileui

A mobile client for [stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
<br/>
## Getting Started

1. Install the stable-diffusion-webui
2. Run the ui with --api (Edit the webui_user.bat and add to COMMANDLINE_ARGS the --api parameter)
3. Install the stable-diffusion-mobileui
4. Go to settings and set the host and port of the webui (e.g. 192.168.1.123:7860) (no http:// and tailing /)

## Getting the app

At the moment there is no release version of the app. Only development versions are available.

### Get the latest development version

1. Go to the actions tab of this repository
2. Look for the latest successful pipeline run
3. Under the artifacts section download the development-apk or the development-ipa artifact
   1. The IPA is signed with an app-store certificate. You can not install it on your device directly. You can use [AltStore](https://altstore.io/) to side-load it on your device or build it yourself.

## Building the app

1. Install flutter (https://flutter.dev/docs/get-started/install)
2. Clone this repository
3. Run `flutter pub get` in the root directory of the repository
4. Run `flutter run` to run the app on a connected device or emulator
5. Or Run `flutter run --release` to build a release version of the app that does not need a debug connection to the device

For iOS you need to have a Mac with XCode installed to correctly sign and build the app.
