{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = [ pkgs.git ];

  android = {
    enable = true;

    platforms.version = [ "33" "34" ];

    reactNative.enable = true;
  };

  # Create the initial AVD that's needed by the emulator
  scripts.createavd.exec = "avdmanager create avd --force --name phone --package 'system-images;android-33;google_apis_playstore;x86_64'";

  # These processes will all run whenever we run `devenv run`
  processes.emulator.exec = "emulator -avd phone -skin 720x1280";
  processes.reactnative.exec = "npx react-native start";
}