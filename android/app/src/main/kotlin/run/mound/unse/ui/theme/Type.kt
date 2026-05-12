package run.mound.unse.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * 하루결 타이포 — iOS Typography.swift 대응.
 * iOS는 Pretendard + Apple SD Gothic Neo. Android는 sans-serif default (시스템 한글 폰트).
 * Pretendard 폰트 통합은 후속 (assets/font/pretendard_*.ttf 추가).
 */

private val display = FontFamily.SansSerif      // 추후 Pretendard로 교체
private val serif = FontFamily.Serif            // 한국어 명조체

val Type = Typography(
    displayLarge = TextStyle(fontFamily = serif, fontWeight = FontWeight.SemiBold, fontSize = 32.sp),
    displayMedium = TextStyle(fontFamily = serif, fontWeight = FontWeight.SemiBold, fontSize = 28.sp),
    displaySmall = TextStyle(fontFamily = serif, fontWeight = FontWeight.SemiBold, fontSize = 24.sp),

    headlineLarge = TextStyle(fontFamily = display, fontWeight = FontWeight.SemiBold, fontSize = 22.sp),
    headlineMedium = TextStyle(fontFamily = display, fontWeight = FontWeight.SemiBold, fontSize = 18.sp),
    headlineSmall = TextStyle(fontFamily = display, fontWeight = FontWeight.SemiBold, fontSize = 16.sp),

    titleLarge = TextStyle(fontFamily = display, fontWeight = FontWeight.SemiBold, fontSize = 17.sp),
    titleMedium = TextStyle(fontFamily = display, fontWeight = FontWeight.Medium, fontSize = 15.sp),
    titleSmall = TextStyle(fontFamily = display, fontWeight = FontWeight.Medium, fontSize = 13.sp),

    bodyLarge = TextStyle(fontFamily = display, fontWeight = FontWeight.Normal, fontSize = 16.sp, lineHeight = 24.sp),
    bodyMedium = TextStyle(fontFamily = display, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 21.sp),
    bodySmall = TextStyle(fontFamily = display, fontWeight = FontWeight.Normal, fontSize = 12.sp, lineHeight = 18.sp),

    labelLarge = TextStyle(fontFamily = display, fontWeight = FontWeight.SemiBold, fontSize = 14.sp),
    labelMedium = TextStyle(fontFamily = display, fontWeight = FontWeight.Medium, fontSize = 12.sp),
    labelSmall = TextStyle(fontFamily = display, fontWeight = FontWeight.Medium, fontSize = 11.sp)
)
