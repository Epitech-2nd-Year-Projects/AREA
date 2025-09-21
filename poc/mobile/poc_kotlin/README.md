# 📱 **Kotlin (Android Native) Mobile Summary**

**Highlights**
- Native performance optimized (direct access to Android SDK).
- Best possible integration with Android ecosystem (Services, Jetpack, Compose).
- Support for **Jetpack Compose** → modern declarative UI.
- New Android APIs are always available in Kotlin first.
- Great tool integration (Android Studio, Profiler).

**Challenges**
- Single‑platform only (no iOS → duplicate work in Swift).
- More verbose and slower iteration compared to Flutter (gradle build time, no instant hot‑reload).
- Learning curve if coming from Java/XML to Compose.
- Some Android APIs still feel heavy/boilerplate compared to Flutter widgets.

**Runtime**
- Faster startup/performance (no embedded engine overhead like Flutter).
- Smaller APK (~5‑10MB for simple app).
- Lower memory footprint → better on low‑end devices.
- Benefits directly from ART/Android runtime and SDK optimizations.

**Dev Speed**
- Very fast when using Android‑specific APIs (location, notifications, background services).
- Much slower if you need Android **and** iOS → two separate projects.
- Excellent productivity with Android Studio debug/profiling.
- Compose speeds up UI building compared to XML.

**Dev Notes**
- Build with Gradle (`./gradlew build`, Android Studio Run).
- Dependencies managed in `build.gradle(.kts)`.
- Jetpack Compose is now standard for UI.
- Remember to declare permissions (INTERNET, LOCATION, etc.) in `AndroidManifest.xml`.

**Bottom Line**
- Kotlin native is **best for performance and deep Android integration**, great if Android‑only.
- Strong long‑term choice if app relies heavily on Android services/APIs.
- But doubles the work if you need iOS.
- Overall: reliable, performant, but less productive cross‑platform compared to Flutter.