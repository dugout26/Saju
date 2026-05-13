package run.mound.unse.ui.daily

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import run.mound.unse.manse.Manse
import run.mound.unse.manse.SajuComputed
import run.mound.unse.ui.components.Tag
import run.mound.unse.ui.components.UnseCard
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Cream
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Lavender
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Mint
import run.mound.unse.ui.theme.Peach
import run.mound.unse.ui.theme.Rose
import run.mound.unse.ui.theme.Spacing
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

/**
 * 하루결 DailyFortuneView — 오늘의 운세.
 * iOS DailyFortuneView.swift 대응.
 *
 * v1: 일진 + 행운의 색만 로컬 계산. Mock 한 줄 운세.
 * AI 풀이는 Q3/Q4 합의 + Supabase Kotlin SDK 통합 후 wiring.
 */
@Composable
fun DailyFortuneView(
    saju: SajuComputed,
    nickname: String,
    modifier: Modifier = Modifier,
    onShare: (() -> Unit)? = null
) {
    val today = LocalDate.now()
    val dayPillar = Manse.dailyPillar(today.year, today.monthValue, today.dayOfMonth)

    // Mock 한 줄 — 진짜는 Edge function 호출 예정
    val mockColors = listOf(
        Triple("라벤더", Lavender, "보라"),
        Triple("피치", Peach, "주황"),
        Triple("민트", Mint, "초록"),
        Triple("크림", Cream, "노랑"),
        Triple("로즈", Rose, "분홍")
    )
    val luckyColor = mockColors[today.dayOfMonth % mockColors.size]

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(Spacing.xxl),
        verticalArrangement = Arrangement.spacedBy(Spacing.xl)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                // CR fix: dayOfWeek.name.take(3) → "MON" 영문 약어. 한국어 UI에 맞게 "월"로.
                val weekday = today.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.KOREAN)
                Tag(text = "${today.monthValue}월 ${today.dayOfMonth}일 · $weekday")
                Spacer(Modifier.height(Spacing.md))
                Text(
                    "오늘의\n행운 색",
                    style = MaterialTheme.typography.displayMedium,
                    color = Ink1
                )
            }
            if (onShare != null) {
                Text(
                    "공유",
                    style = MaterialTheme.typography.labelLarge,
                    color = LavenderDeep,
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(Lavender.copy(alpha = 0.3f))
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .clickable { onShare() }
                )
            }
        }

        // 행운의 색 카드
        UnseCard(padding = Spacing.xxxl) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .size(140.dp)
                        .clip(RoundedCornerShape(70.dp))
                        .background(luckyColor.second),
                    contentAlignment = Alignment.Center
                ) {
                    Text("TODAY", style = MaterialTheme.typography.labelMedium, color = Color.White)
                }
                Spacer(Modifier.height(Spacing.lg))
                Text(luckyColor.first, style = MaterialTheme.typography.headlineLarge, color = Ink1)
                Text("(${luckyColor.third} 계열)", color = Ink3, style = MaterialTheme.typography.bodySmall)
            }
        }

        // 한 줄 운세
        UnseCard {
            Text("오늘의 한 줄", style = MaterialTheme.typography.titleLarge, color = Ink1)
            Spacer(Modifier.height(Spacing.md))
            Text(
                "${nickname}님, 오늘은 ${luckyColor.first}색과 함께 시작해보세요. " +
                "${dayPillar.stem.korean}${dayPillar.branch.korean}일이 가져오는 흐름이 ${nickname}님에게 우호적입니다.",
                color = Ink2,
                style = MaterialTheme.typography.bodyMedium,
                lineHeight = 24.sp
            )
        }

        // 일진
        UnseCard {
            Text("오늘의 일진", style = MaterialTheme.typography.titleLarge, color = Ink1)
            Spacer(Modifier.height(Spacing.md))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        "${dayPillar.stem.character}${dayPillar.branch.character}",
                        style = MaterialTheme.typography.displaySmall,
                        color = LavenderDeep
                    )
                    Text(
                        "${dayPillar.stem.korean}${dayPillar.branch.korean}",
                        color = Ink3,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("일간과의 관계", color = Ink3, style = MaterialTheme.typography.labelSmall)
                    Text(
                        if (dayPillar.stem == saju.dayMaster) "동일 (비견)" else "${dayPillar.stem.element.korean} 작용",
                        color = Ink2,
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }
        }

        Text(
            "* AI 풀이는 향후 업데이트에서 제공됩니다",
            color = Ink3,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

