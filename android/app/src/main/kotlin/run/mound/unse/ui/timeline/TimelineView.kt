package run.mound.unse.ui.timeline

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import run.mound.unse.manse.DaeWoon
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.components.Tag
import run.mound.unse.ui.components.UnseCard
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Lavender
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface
import java.time.LocalDate

/**
 * 하루결 TimelineView — 평생 흐름 (대운 10년 주기).
 * iOS TimelineView.swift 대응.
 *
 * PRO 전용 — 비프리미엄은 차트 blur + PRO lock card overlay.
 */
@Composable
fun TimelineView(
    daeWoon: List<DaeWoon>,
    isPremium: Boolean,
    modifier: Modifier = Modifier,
    birthYear: Int? = null
) {
    // CR fix: 1990 hardcode 제거. birthYear 모를 때(현실적으로 없음 — Q4 wiring 전 default) 첫 대운
    // startYear 기반으로 역산 — `birthYear ≈ daeWoon[0].startYear - daeWoon[0].startAge`.
    val currentYear = remember { LocalDate.now().year }
    val resolvedBirthYear = birthYear ?: daeWoon.firstOrNull()?.let { it.startYear - it.startAge }
    val currentAge = resolvedBirthYear?.let { currentYear - it } ?: 0

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(Spacing.xxl),
        verticalArrangement = Arrangement.spacedBy(Spacing.lg)
    ) {
        // 헤더
        Tag(text = "대운 · 10년 주기")
        Text(
            "큰 흐름으로 보는\n인생의 지도",
            style = MaterialTheme.typography.displaySmall,
            color = Ink1
        )
        Text(
            "대운은 10년 단위로 찾아오는 큰 기운의 흐름입니다",
            color = Ink3,
            style = MaterialTheme.typography.bodySmall
        )

        Spacer(Modifier.height(Spacing.md))

        // PRO 게이트
        Box {
            Column(
                verticalArrangement = Arrangement.spacedBy(Spacing.md),
                modifier = Modifier.blur(if (isPremium) 0.dp else 10.dp)
            ) {
                DaeWoonChart(daeWoon, currentAge)
                daeWoon.forEach { dw ->
                    DaeWoonRow(dw, currentAge)
                }
            }
            if (!isPremium) {
                ProLockCard(modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}

@Composable
private fun DaeWoonChart(daeWoon: List<DaeWoon>, currentAge: Int) {
    UnseCard {
        Text("대운 그래프", style = MaterialTheme.typography.titleLarge, color = Ink1)
        Spacer(Modifier.height(Spacing.md))
        // iOS DaeWoonChart.swift 1:1 — fortuneScore (stemScore + sin wave) 기반 막대 + 천간/지지 annotation
        val maxHeight = 160.dp
        Row(
            modifier = Modifier.fillMaxWidth().height(maxHeight),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.Bottom
        ) {
            daeWoon.forEachIndexed { idx, dw ->
                val isCurrent = dw.startAge <= currentAge && currentAge < dw.startAge + 10
                val score = fortuneScore(dw.pillar.stem.element, idx)
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Bottom,
                    modifier = Modifier.height(maxHeight)
                ) {
                    // 천간/지지 annotation
                    Text(
                        dw.pillar.stem.character,
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isCurrent) LavenderDeep else Ink3
                    )
                    Text(
                        dw.pillar.branch.character,
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isCurrent) LavenderDeep else Ink3
                    )
                    Spacer(Modifier.height(2.dp))
                    Box(
                        modifier = Modifier
                            .width(20.dp)
                            .height((score * 120).dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(if (isCurrent) LavenderDeep else Lavender.copy(alpha = 0.6f))
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "${dw.startAge}세",
                        style = MaterialTheme.typography.labelSmall,
                        color = Ink3
                    )
                }
            }
        }
    }
}

/**
 * iOS DaeWoonChart.fortuneScore 1:1 포팅.
 * stemScore (오행별 기본값) + sin wave (인덱스 기반) → clamp(0.4..1.0).
 */
private fun fortuneScore(element: run.mound.unse.manse.Element, index: Int): Float {
    val stemScore = when (element) {
        run.mound.unse.manse.Element.WOOD  -> 0.75f
        run.mound.unse.manse.Element.FIRE  -> 0.90f
        run.mound.unse.manse.Element.EARTH -> 0.65f
        run.mound.unse.manse.Element.METAL -> 0.70f
        run.mound.unse.manse.Element.WATER -> 0.80f
    }
    val wave = kotlin.math.sin(index * 0.9).toFloat() * 0.15f
    return (stemScore + wave).coerceIn(0.4f, 1.0f)
}

@Composable
private fun DaeWoonRow(daeWoon: DaeWoon, currentAge: Int) {
    val isCurrent = daeWoon.startAge <= currentAge && currentAge < daeWoon.startAge + 10
    UnseCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            // 천간/지지 badge
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .size(44.dp, 56.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (isCurrent) LavenderDeep else Surface)
                    .padding(4.dp)
            ) {
                Text(
                    daeWoon.pillar.stem.character,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (isCurrent) Surface else Ink1
                )
                Text(
                    daeWoon.pillar.branch.character,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (isCurrent) Surface else Ink1
                )
            }
            Spacer(Modifier.width(Spacing.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    "${daeWoon.startAge}세 — ${daeWoon.startAge + 9}세",
                    style = MaterialTheme.typography.titleMedium,
                    color = Ink1
                )
                Text(
                    "${daeWoon.startYear}년부터 시작 · ${daeWoon.pillar.stem.element.korean} 기운",
                    color = Ink3,
                    style = MaterialTheme.typography.bodySmall
                )
            }
            if (isCurrent) Tag(text = "현재 대운")
        }
    }
}

@Composable
private fun ProLockCard(modifier: Modifier = Modifier) {
    UnseCard(modifier = modifier.padding(horizontal = Spacing.lg)) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth().padding(Spacing.lg)
        ) {
            Icon(
                imageVector = Icons.Outlined.Lock,
                contentDescription = null,
                tint = LavenderDeep
            )
            Spacer(Modifier.height(Spacing.sm))
            Text(
                "평생운 그래프는 PRO 전용",
                style = MaterialTheme.typography.titleLarge,
                color = Ink1
            )
            Spacer(Modifier.height(Spacing.xs))
            Text(
                "10년 단위 대운 흐름과\n시기별 조언을 자세히 보세요",
                color = Ink2,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                lineHeight = androidx.compose.ui.unit.TextUnit(20f, androidx.compose.ui.unit.TextUnitType.Sp)
            )
            Spacer(Modifier.height(Spacing.md))
            PrimaryButton(title = "PRO로 자세히 보기") { /* TODO: navigate to PaywallView */ }
        }
    }
}

