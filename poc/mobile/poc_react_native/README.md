# 📱 **React Native (Expo) Mobile Summary**

**Highlights**
- Cross-platform with **one JS/TS codebase** (Android, iOS; Web optional).
- **Expo + Fast Refresh** → very quick UI iteration (no native build with Expo Go).
- Huge **ecosystem** (React Navigation, Reanimated, RN community libs).
- Can **scale to native** when needed (Expo prebuild/eject; Gradle/Xcode).
- Familiar **web stack** (React, fetch, async/await) → easy onboarding.

**Challenges**
- Native toolchains (Gradle/Xcode, SDKs) can be **heavy** when leaving Expo Go.
- Some libs require **native modules** → slower builds, version alignment needed.
- **Performance** slightly behind pure native for complex animations/heavy workloads.
- Debugging network/certs on emulators/real devices can be finicky.

**Runtime**
- **Hermes** JS engine by default → lower memory & faster startup than JSC.
- Solid 60fps for most UI; heavy UI/gestures best with Reanimated/Skia.
- Startup slower than Kotlin/Swift in cold start, fine for standard apps.

**Dev Speed**
- **Expo Go** = instant dev loop (no `android/` build), perfect for POCs.
- Prebuild/dev-client needed for native libs → **first build long** (caches help).
- Strong DX with Metro bundler, excellent logs, OTA updates possible with EAS.

**Dev Notes**
- Commands:
  - Run on Android (Expo Go): `npm run android` (=`expo start --android`)
  - Start bundler: `npm run start`
- Project bits (POC login/register/home):
  - **API base URL is fixed** in `lib/api.ts` → `export const BASE_URL = "http://10.0.2.2:8080"`
    - Android Emulator → `10.0.2.2`
    - Real device (USB) → `adb reverse tcp:8080 tcp:8080` then `http://localhost:8080`
    - Real device (Wi-Fi) → `http://<YOUR_LAN_IP>:8080`
  - Endpoints expected from backend:
    - `POST /register { email, password } -> { id, email }`
    - `POST /auth { email, password } -> { access_token, refresh_token }`
  - **No cookies in this POC**. Tokens are kept in memory only.
- Navigation:
  - If using **Expo Router**: `_layout.tsx` wraps providers; use `<Redirect />` in `app/index.tsx`.
  - If using **React Navigation**: single `NavigationContainer` at root (no nesting).

**Bottom Line**
- React Native (Expo) is **excellent for fast mobile POCs** and can graduate to production.
- Use **Expo Go** for speed; prebuild only when you need native modules.
- Mind SDK versions and native deps if you go beyond Expo Go; otherwise DX is top-tier.
