package run.mound.unse.ui.saju

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import run.mound.unse.manse.Element
import run.mound.unse.manse.Pillar
import run.mound.unse.manse.SajuComputed
import run.mound.unse.ui.components.Tag
import run.mound.unse.ui.components.UnseCard
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.ElementEarth
import run.mound.unse.ui.theme.ElementFire
import run.mound.unse.ui.theme.ElementMetal
import run.mound.unse.ui.theme.ElementWater
import run.mound.unse.ui.theme.ElementWood
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 SajuResultView — 사주 8글자 + 오행 균형.
 * iOS SajuResultView.swift 1:1 대응.
 *
 * AI 풀이 텍스트는 Supabase Edge `saju-reading` 호출 — Q3/Q4 합의 후 wiring.
 * v1은 로컬 Manse 계산 결과만 표시.
 */
@Composable
fun SajuResultView(saju: SajuComputed, nickname: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(Spacing.xxl),
        verticalArrangement = Arrangement.spacedBy(Spacing.xl)
    ) {
        // 헤더
        Tag(text = "1단계 · 기본 풀이")
        Text(
            "${nickname}님의 사주는",
            style = MaterialTheme.typography.displaySmall,
            color = Ink1
        )
        Text(
            "${saju.dayMaster.character}${saju.dayMaster.korean} 일간",
            style = MaterialTheme.typography.displaySmall,
            color = LavenderDeep
        )
        Text("사주 기반 분석", color = Ink3, style = MaterialTheme.typography.bodySmall)

        // 사주 8자 grid
        UnseCard {
            PillarRow(saju)
        }

        // 오행 균형
        UnseCard {
            Text("오행 균형", style = MaterialTheme.typography.titleLarge, color = Ink1)
            Spacer(Modifier.height(Spacing.lg))
            ElementsBar(saju)
        }
    }
}

@Composable
private fun PillarRow(saju: SajuComputed) {
    // CR fix: listOfNotNull은 Pair 자체 null만 거름 — Pair 내부 null pillar는 통과해 `pillar!!` NPE.
    // saju.hour가 null이면 시주 entry 자체를 drop.
    val pillars = listOf(
        "시주" to saju.hour,
        "일주" to saju.day,
        "월주" to saju.month,
        "년주" to saju.year
    ).mapNotNull { (label, pillar) -> pillar?.let { label to it } }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        pillars.forEach { (label, pillar) ->
            PillarCell(label, pillar)
        }
    }
}

@Composable
private fun PillarCell(label: String, pillar: Pillar) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, color = Ink3, style = MaterialTheme.typography.labelSmall)
        Spacer(Modifier.height(Spacing.sm))

        // 천간
        Box(
            modifier = Modifier
                .size(60.dp, 70.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(colorForElement(pillar.stem.element)),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(pillar.stem.character, style = MaterialTheme.typography.displaySmall, color = Ink1)
                Text(pillar.stem.korean, color = Ink3, style = MaterialTheme.typography.labelSmall)
            }
        }
        Spacer(Modifier.height(Spacing.sm))

        // 지지
        Box(
            modifier = Modifier
                .size(60.dp, 70.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(colorForElement(pillar.branch.element)),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(pillar.branch.character, style = MaterialTheme.typography.displaySmall, color = Ink1)
                Text(pillar.branch.korean, color = Ink3, style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

@Composable
private fun ElementsBar(saju: SajuComputed) {
    val counts = saju.fiveElements
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Element.entries.forEach { element ->
            val count = counts[element] ?: 0
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .size(50.dp, 50.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(colorForElement(element)),
                    contentAlignment = Alignment.Center
                ) {
                    Text("$count", style = MaterialTheme.typography.titleLarge, color = Ink1)
                }
                Spacer(Modifier.height(Spacing.xs))
                Text(element.character, style = MaterialTheme.typography.titleMedium, color = Ink2)
                Text(element.korean, color = Ink3, style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

private fun colorForElement(e: Element) = when (e) {
    Element.WOOD -> ElementWood
    Element.FIRE -> ElementFire
    Element.EARTH -> ElementEarth
    Element.METAL -> ElementMetal
    Element.WATER -> ElementWater
}
