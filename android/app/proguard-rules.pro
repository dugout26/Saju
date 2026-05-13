# 하루결 Android ProGuard rules
#
# Compose + Material3는 자체 consumer rules 포함 — 추가 룰 거의 없음.
# 도메인 코드 (manse/) 는 enum reflection (Stem/Branch/Element fromIndex) 사용 → keep.
# AGP default proguard-android-optimize.txt 위에 보충.

# Kotlin enums — fromIndex(ordinal) 호환
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 데이터 클래스 (BirthInput, SajuComputed, DaeWoon, Pillar) — copy/equals 유지
-keepclassmembers class run.mound.unse.manse.** { *; }

# Coroutines — 안전 default
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
