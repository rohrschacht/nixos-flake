{ lib, config, pkgs, ... }:

let
  # buildToolsVersion = "34.0.0";
  # androidComposition = pkgs.androidenv.composeAndroidPackages {
  #   cmdLineToolsVersion = "9.0";
  #   toolsVersion = "26.1.1";
  #   platformToolsVersion = "35.0.2";
  #   buildToolsVersions = [ "${buildToolsVersion}" ];
  #   includeEmulator = true;
  #   emulatorVersion = "35.2.5";
  #   platformVersions = [ "34" "35" ];
  #   includeSources = true;
  #   includeSystemImages = true;
  #   systemImageTypes = [ "google_apis_playstore" ];
  #   # abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
  #   abiVersions = [ "x86_64" ];
  #   cmakeVersions = [ "3.22.1" ];
  #   includeNDK = true;
  #   ndkVersions = ["22.0.7026061"];
  #   useGoogleAPIs = true;
  #   useGoogleTVAddOns = false;
  #   includeExtras = [
  #     "extras;google;gcm"
  #   ];
  # };
  # androidHome = "${androidComposition.androidsdk}/libexec/android-sdk";
  localAndroidHome = "Android/Sdk";
in
{
  options.android-devenv = {
    enable = lib.mkEnableOption "enable android development environment";
  };

  config = lib.mkIf config.android-devenv.enable {
    nixpkgs.config.android_sdk.accept_license = true;

    home.packages = with pkgs; [
      jdk17
      nodejs_20
      nodePackages.yarn
      prettierd
      # android-studio
      # androidComposition.androidsdk
      # androidComposition.platform-tools
    ];

    # home.file."${localAndroidHome}".source = config.lib.file.mkOutOfStoreSymlink "${androidHome}";
    # home.file."${localAndroidHome}" = {
    #   source = "${androidHome}";
    #   recursive = true;
    # };
    # home.activation = {
    #   copySdkAction = lib.hm.dag.entryAfter ["writeBoundary"] ''
    #     run mkdir -p ${localAndroidHome} && cp -rL ${androidHome}/* ${localAndroidHome} && chmod -R u+w ${localAndroidHome}
    #   '';
    # };

    home.sessionVariables = {
      ANDROID_HOME="$HOME/${localAndroidHome}";
      ANDROID_NDK_ROOT="$HOME/${localAndroidHome}/ndk-bundle";

      # Use the same buildToolsVersion here
      # GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${localAndroidHome}/build-tools/${buildToolsVersion}/aapt2";
    };

    home.sessionPath = [
      "$ANDROID_HOME/emulator"
      "$ANDROID_HOME/platform-tools"
    ];
  };
}
