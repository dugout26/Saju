package run.mound.unse.ui.paywall

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Chat
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.ShowChart
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.legal.LegalKind
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Lavender
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.LavenderSoft
import run.mound.unse.ui.theme.Line
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface

/**
 * 하루결 PaywallView — PRO 구독 안내.
 * iOS PaywallView.swift 대응.
 *
 * v1: UI만. 실제 결제는 Q3 (Play Billing) 합의 후.
 */
@Composable
fun PaywallView(
    onClose: () -> Unit,
    onPurchase: (plan: String) -> Unit,
    onLegal: ((LegalKind) -> Unit)? = null
) {
    var selectedPlan by remember { mutableStateOf("yearly") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
    ) {
        // 닫기
        Row(
            modifier = Modifier.fillMaxWidth().padding(Spacing.md),
            horizontalArrangement = Arrangement.End
        ) {
            IconButton(onClick = onClose) {
                Icon(Icons.Outlined.Close, contentDescription = "닫기", tint = Ink2)
            }
        }

        Column(
            modifier = Modifier.padding(horizontal = Spacing.xxl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.lg)
        ) {
            // PRO badge
            Box(
                modifier = Modifier.size(80.dp).clip(CircleShape).background(LavenderSoft),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Outlined.Star,
                    contentDescription = null,
                    tint = LavenderDeep,
                    modifier = Modifier.size(40.dp)
                )
            }

            Text("하루결 PRO", style = MaterialTheme.typography.displayMedium, color = Ink1)
            Text(
                "자세한 5단계 풀이와\n무제한 AI 챗봇",
                color = Ink2,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            // 혜택 4개
            Column(
                modifier = Modifier.fillMaxWidth().padding(top = Spacing.md),
                verticalArrangement = Arrangement.spacedBy(Spacing.md)
            ) {
                Benefit(Icons.Outlined.Chat, "무제한 AI 챗봇", "사주에 대한 모든 궁금증을 AI와 함께")
                Benefit(Icons.Outlined.ShowChart, "평생운 + 5단계 풀이", "10년 대운 흐름과 평생 종합 분석")
                Benefit(Icons.Outlined.Star, "영역별 자세한 풀이", "직업·금전·연애·건강 4영역 분석")
                Benefit(Icons.Outlined.Notifications, "매일 운세 자세히", "오늘 시간대별 행운 + 광고 없음")
            }

            Spacer(Modifier.height(Spacing.lg))

            // 상품 선택
            PlanOption(
                title = "PRO 연간",
                price = "₩33,000 / 년",
                save = "월간 대비 17% 할인",
                selected = selectedPlan == "yearly",
                onClick = { selectedPlan = "yearly" }
            )
            PlanOption(
                title = "PRO 월간",
                price = "₩3,300 / 월",
                save = null,
                selected = selectedPlan == "monthly",
                onClick = { selectedPlan = "monthly" }
            )

            Spacer(Modifier.height(Spacing.md))

            PrimaryButton(title = "시작하기") { onPurchase(selectedPlan) }

            Text(
                "이미 구독 중이에요",
                color = LavenderDeep,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(top = Spacing.sm)
            )
            LegalLinksRow(onLegal = onLegal)
        }
    }
}

/** 결제 직전 화면 컴플라이언스 — 약관/개인정보 접근. CR fix: 클릭 가능 + LegalKind 라우팅. */
@Composable
private fun LegalLinksRow(onLegal: ((LegalKind) -> Unit)?) {
    Row(
        modifier = Modifier.padding(vertical = Spacing.md),
        horizontalArrangement = Arrangement.spacedBy(Spacing.lg)
    ) {
        Text(
            "이용약관",
            color = Ink3,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.clickable(enabled = onLegal != null) {
                onLegal?.invoke(LegalKind.TERMS)
            }
        )
        Text(
            "개인정보처리방침",
            color = Ink3,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.clickable(enabled = onLegal != null) {
                onLegal?.invoke(LegalKind.PRIVACY)
            }
        )
    }
}

@Composable
private fun Benefit(icon: ImageVector, title: String, subtitle: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(LavenderSoft),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = LavenderDeep)
        }
        Spacer(Modifier.size(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, color = Ink1)
            Text(subtitle, color = Ink3, style = MaterialTheme.typography.labelSmall)
        }
        Icon(Icons.Outlined.Check, contentDescription = null, tint = LavenderDeep)
    }
}

@Composable
private fun PlanOption(
    title: String,
    price: String,
    save: String?,
    selected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (selected) LavenderSoft else Surface)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) LavenderDeep else Line,
                shape = RoundedCornerShape(12.dp)
            )
            .clickable(onClick = onClick)
            .padding(Spacing.lg),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, color = Ink1)
            if (save != null) Text(save, color = LavenderDeep, style = MaterialTheme.typography.labelSmall)
        }
        Text(price, style = MaterialTheme.typography.titleMedium, color = Ink1)
    }
}
