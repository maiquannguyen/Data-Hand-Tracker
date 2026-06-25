//
//  Localizable.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

// ============================================================
// LOCALIZATION SETUP GUIDE
// ============================================================
//
// STEP 1 — Create the Localizable.strings file
//   • In Xcode: File → New → File → Strings File
//   • Name it exactly: Localizable
//   • Save it in HandsTracker/Resources/Localization/
//
// STEP 2 — Enable localization for the project
//   • Select the project root in the Navigator
//   • Under PROJECT → Info → Localizations, tap "+"
//   • Add the languages you want (e.g. Vietnamese "vi", English "en")
//   • Xcode will create per-language .strings files automatically
//
// STEP 3 — Add the file to each language
//   • Select Localizable.strings in the Navigator
//   • Open the File Inspector (right panel)
//   • Under Localization, check each language you added
//
// STEP 4 — Key format used in this project
//   All keys follow: "module.screen.element"
//   Example: "login.button.title" = "Log In";
//
// STEP 5 — Use the String extension below (String+Localized.swift)
//   Instead of NSLocalizedString("key", comment: ""), just write:
//   "login.button.title".localized
//   Or with arguments: "error.server".localized(with: statusCode)
//
// STEP 6 — Add a new language at any time
//   • Project → Info → Localizations → "+"
//   • Duplicate your base Localizable.strings and translate
//
// ============================================================
// EXAMPLE Localizable.strings (en)
// ============================================================
//
//  /* Login */
//  "login.title"                        = "Welcome Back";
//  "login.field.email.placeholder"      = "Email";
//  "login.field.password.placeholder"   = "Password";
//  "login.button.login"                 = "Log In";
//  "login.button.google"                = "Continue with Google";
//  "login.button.register"              = "Create Account";
//  "login.button.forgot"                = "Forgot Password?";
//
//  /* Register */
//  "register.title"                     = "Create Account";
//  "register.field.name.placeholder"    = "Full Name";
//  "register.field.email.placeholder"   = "Email";
//  "register.field.password.placeholder"= "Password";
//  "register.field.confirm.placeholder" = "Confirm Password";
//  "register.button.create"             = "Create New Account";
//  "register.terms.prefix"              = "By creating an account you agree to our ";
//  "register.terms.link"                = "Terms & Conditions";
//
//  /* Capture */
//  "capture.button.stop"                = "Stop";
//  "capture.label.waiting"              = "Show both hands to begin";
//  "capture.label.paused"               = "Recording paused — show both hands";
//  "capture.left.hand"                  = "Left Hand";
//  "capture.right.hand"                 = "Right Hand";
//
//  /* List Videos */
//  "videos.empty.title"                 = "No Videos Yet";
//  "videos.empty.subtitle"              = "Captured hand tracking videos will appear here.";
//  "videos.upload.all"                  = "Upload All";
//  "videos.upload.button"               = "Upload";
//
//  /* Errors */
//  "error.generic"                      = "Something went wrong. Please try again.";
//  "error.network"                      = "Network error. Please check your connection.";
//  "error.upload"                       = "Upload failed. Please try again.";
//  "error.camera.permission"            = "Camera access is required to capture videos.";
//
// ============================================================
