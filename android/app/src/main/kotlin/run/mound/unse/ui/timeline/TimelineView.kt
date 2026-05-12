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
    modifier: Modifier = Modifier
) {
    val currentAge = remember { LocalDate.now().year - 1990 } // 임시 — UserProfile.birthYear 추가 후 교체

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
        Row(
            modifier = Modifier.fillMaxWidth().height(120.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.Bottom
        ) {
            daeWoon.forEach { dw ->
                val isCurrent = dw.startAge <= currentAge && currentAge < dw.startAge + 10
                Box(
                    modifier = Modifier
                        .width(20.dp)
                        .height((40 + dw.startAge).dp.coerceAtMost(120.dp))
                        .clip(RoundedCornerShape(4.dp))
                        .background(if (isCurrent) LavenderDeep else Lavender.copy(alpha = 0.5f))
                )
            }
        }
    }
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

