Warning: Flutter support for your project's Kotlin version (2.2.20) will soon be dropped. Please upgrade your Kotlin version to a version of at least 2.3.20 soon.
Alternatively, use the flag "--android-skip-build-dependency-validation" to bypass this check.

Potential fix: Your project's KGP version is typically defined in the plugins block of the `settings.gradle` file (/home/sabdydev/Documents/projet_carrement_web/flutter/fraya-mobile/fraya_mobile/android/settings.gradle), by a plugin with the id of org.jetbrains.kotlin.android. 
If you don't see a plugins block, your project was likely created with an older template version, in which case it is most likely defined in the top-level build.gradle file (/home/sabdydev/Documents/projet_carrement_web/flutter/fraya-mobile/fraya_mobile/android/build.gradle) by the ext.kotlin_version property.

lib/features/driver/vehicle/screens/driver_vehicle_screen.dart:310:56: Error: Required named parameter 'cameraAvailable' must be provided.
    final source = await DriverDocumentSourceSheet.show(context);
                                                       ^
lib/features/driver/kyc/widgets/driver_document_source_sheet.dart:15:43: Context: Found this candidate, but the arguments don't match.
  static Future<DriverKycDocumentSource?> show(
                                          ^^^^
lib/features/driver/profile/widgets/driver_kyc_update_document_tile.dart:102:56: Error: Required named parameter 'cameraAvailable' must be provided.
    final source = await DriverDocumentSourceSheet.show(context);
                                                       ^
lib/features/driver/kyc/widgets/driver_document_source_sheet.dart:15:43: Context: Found this candidate, but the arguments don't match.
  static Future<DriverKycDocumentSource?> show(
                                          ^^^^
Target kernel_snapshot_program failed: Exception


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileFlutterBuildDriverDebug'.
> Process 'command '/home/sabdydev/flutter/bin/flutter'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 31s
Running Gradle task 'assembleDriverDebug'...                       32,6s
Error: Gradle task assembleDriverDebug failed with exit code 1
