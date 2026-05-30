Problem: Your browser console shows CORS preflight failures when uploading to Firebase Storage (requests blocked).

Why: Firebase Storage uses Google Cloud Storage (GCS). When running the app on `http://localhost:...` the browser sends a preflight (OPTIONS) request — GCS must be configured to allow that origin and methods.

Recommended fixes (choose one):

1) Proper fix — set CORS on your bucket (recommended)

- Create a JSON file (we added `cors.json` at repo root).
- Get your bucket name (Firebase Console → Storage). It is usually `<PROJECT_ID>.appspot.com`.
- Install `gsutil` (part of Google Cloud SDK) if you don't have it.
- Run (PowerShell):

  gsutil cors set cors.json gs://YOUR_BUCKET_NAME

  Example:

  gsutil cors set cors.json gs://my-firebase-project.appspot.com

- After applying, clear browser cache and reload your app.

2) Alternative via Cloud Console

- Go to https://console.cloud.google.com/storage/browser
- Open your bucket → click "Edit CORS configuration" (or from settings)
- Paste the JSON content (from `cors.json`) and save.

3) Quick local workaround (unsafe; for temporary dev only)

- Start Chrome with web security disabled (not recommended for normal use):

  Close all Chrome windows first, then run:

  "C:\Program Files\Google\Chrome\Application\chrome.exe" --user-data-dir="C:/tmp/chrome-dev-profile" --disable-web-security

- This bypasses CORS checks, but DO NOT use it for normal browsing.

4) If uploads still fail, check these too:
- Make sure the user is authenticated if your Storage rules require it. Check `AuthProvider.user` is not null.
- Check Firebase Storage rules (in Firebase Console) allow writes for authenticated users.
- Inspect network tab for exact failing request and error code (403 permission-denied, 404 bucket not found, or CORS preflight failure).

Small checklist to debug quickly:
- [ ] Re-run `flutter run -d chrome` and open DevTools → Network and Console
- [ ] Click KIRIM and look for failing requests to `firebasestorage.googleapis.com`
- [ ] If you see CORS preflight failure in Console, apply `cors.json` to bucket
- [ ] After applying, reload the app and retry

If you want, I can:
- Edit `cors.json` to add/remove specific localhost ports you use.
- Provide the `gsutil` command tailored to your project if you give me the bucket name.
- Help update Firebase Storage rules if needed (paste current rules here).
