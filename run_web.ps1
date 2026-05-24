# Local development script for AuraHabit (Flutter web).
# Run from the pa/ directory: .\run_web.ps1

$env:FIREBASE_API_KEY             = "AIzaSyCNh9UQQTH_4vU_Ug6WpNJaDcabVNf3H6I"
$env:FIREBASE_AUTH_DOMAIN         = "tyto-pa.firebaseapp.com"
$env:FIREBASE_PROJECT_ID          = "tyto-pa"
$env:FIREBASE_STORAGE_BUCKET      = "tyto-pa.firebasestorage.app"
$env:FIREBASE_MESSAGING_SENDER_ID = "896665959301"
$env:FIREBASE_APP_ID              = "1:896665959301:web:100ae3f382cf76a012e2ec"

# Set your Google OAuth Client ID here to enable Planner → Google Calendar sync.
# Find it in Google Cloud Console > APIs & Services > Credentials (Web application type).
$env:GOOGLE_OAUTH_CLIENT_ID       = ""

flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=$env:FIREBASE_API_KEY `
  --dart-define=FIREBASE_AUTH_DOMAIN=$env:FIREBASE_AUTH_DOMAIN `
  --dart-define=FIREBASE_PROJECT_ID=$env:FIREBASE_PROJECT_ID `
  --dart-define=FIREBASE_STORAGE_BUCKET=$env:FIREBASE_STORAGE_BUCKET `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=$env:FIREBASE_MESSAGING_SENDER_ID `
  --dart-define=FIREBASE_APP_ID=$env:FIREBASE_APP_ID `
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=$env:GOOGLE_OAUTH_CLIENT_ID
