package run.mound.unse.ui.settings

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Logout
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material3.HorizontalDivider
import androidx.compose.ui.unit.dp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import run.mound.unse.ui.components.Tag
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.LavenderSoft
import run.mound.unse.ui.theme.Line
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface

/**
 * 하루결 SettingsView — 프로필 + 구독 + 알림 + 지원 + 위험.
 * iOS SettingsView.swift 대응.
 *
 * v1: UI만. push 토글 wiring은 Q5 (Push 토큰 스키마) 합의 후.
 * 로그아웃/계정 삭제는 Q2 (Auth) 합의 후 wiring.
 */
@Composable
fun SettingsView(
    nickname: String,
    isPremium: Boolean,
    modifier: Modifier = Modifier,
    onEditSaju: (() -> Unit)? = null
) {
    var pushEnabled by remember { mutableStateOf(true) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(Spacing.xxl),
        verticalArrangement = Arrangement.spacedBy(Spacing.lg)
    ) {
        Text("설정", style = MaterialTheme.typography.headlineLarge, color = Ink1)

        // 프로필 카드
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier.size(52.dp).clip(CircleShape).background(LavenderSoft),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    nickname.take(1),
                    style = MaterialTheme.typography.headlineMedium,
                    color = LavenderDeep
                )
            }
            Spacer(Modifier.size(Spacing.md))
            Column(modifier = Modifier.weight(1f)) {
                Text(nickname, style = MaterialTheme.typography.titleLarge, color = Ink1)
                Text(if (isPremium) "PRO 구독 중" else "Free", color = Ink3, style = MaterialTheme.typography.bodySmall)
            }
            if (isPremium) Tag(text = "PRO")
        }
        HorizontalDivider(color = Line)

        SectionHeader("구독")
        if (isPremium) {
            SettingsRow(Icons.Outlined.Star, "PRO 구독 중", trailing = "Pro")
            SettingsRow(Icons.Outlined.Description, "구독 관리") { /* TODO link to Play subscriptions */ }
        } else {
            SettingsRow(Icons.Outlined.Star, "PRO로 업그레이드", highlight = true) {
                /* TODO navigate to PaywallView */
            }
        }
        HorizontalDivider(color = Line)

        SectionHeader("알림")
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Outlined.Notifications, contentDescription = null, tint = Ink2)
            Spacer(Modifier.size(Spacing.md))
            Text("오늘의 운세 알림", color = Ink1, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
            Switch(checked = pushEnabled, onCheckedChange = { pushEnabled = it })
        }
        HorizontalDivider(color = Line)

        SectionHeader("지원")
        SettingsRow(Icons.Outlined.Email, "문의하기", subtitle = "contact@mound.run") { /* TODO mailto */ }
        SettingsRow(Icons.Outlined.Description, "이용약관") { /* TODO LegalDocumentView */ }
        SettingsRow(Icons.Outlined.Description, "개인정보처리방침") { }
        SettingsRow(Icons.Outlined.Description, "면책 고지") { }
        HorizontalDivider(color = Line)

        SectionHeader("계정")
        SettingsRow(Icons.Outlined.AccountCircle, "사주 정보 편집", onClick = onEditSaju)
        SettingsRow(Icons.Outlined.Logout, "로그아웃") { /* TODO Q2 후 wiring */ }
        SettingsRow(Icons.Outlined.AccountCircle, "계정 삭제", destructive = true) { /* TODO */ }
        Spacer(Modifier.height(Spacing.xxxl))
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelMedium,
        color = Ink3,
        modifier = Modifier.padding(top = Spacing.md, bottom = Spacing.xs)
    )
}

@Composable
private fun SettingsRow(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    trailing: String? = null,
    highlight: Boolean = false,
    destructive: Boolean = false,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(MaterialTheme.shapes.medium)
            .clickable(enabled = onClick != null) { onClick?.invoke() }
            .padding(vertical = Spacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = when {
                destructive -> androidx.compose.ui.graphics.Color.Red
                highlight -> LavenderDeep
                else -> Ink2
            }
        )
        Spacer(Modifier.size(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.titleMedium,
                color = when {
                    destructive -> androidx.compose.ui.graphics.Color.Red
                    highlight -> LavenderDeep
                    else -> Ink1
                }
            )
            if (subtitle != null) Text(subtitle, color = Ink3, style = MaterialTheme.typography.labelSmall)
        }
        if (trailing != null) Text(trailing, color = Ink3, style = MaterialTheme.typography.bodySmall)
    }
}
