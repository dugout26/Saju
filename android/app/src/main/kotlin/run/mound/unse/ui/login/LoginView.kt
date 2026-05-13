package run.mound.unse.ui.login

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Chat
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Line
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 LoginView — 간편 로그인.
 * iOS LoginView.swift 1:1 매칭:
 * - Spacer로 상단/중앙/하단 영역 분배
 * - Kakao(노란, 검정 텍스트) + Google(흰, 검정 텍스트 + 보더) 버튼
 * - 아이콘 + 텍스트 가로 배치
 * - 하단 약관 안내
 *
 * Q2 결정 대기 — 실제 SDK 통합은 Session 4+.
 */
@Composable
fun LoginView(onLoggedIn: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().background(Bg).padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.spacedBy(Spacing.xxl)
    ) {
        Spacer(Modifier.weight(1f))

        // 헤더
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
            Text(
                "시작하기",
                style = MaterialTheme.typography.displayMedium,
                color = Ink1,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(Spacing.md))
            Text(
                "나만의 사주 분석을 위해\n간편 로그인이 필요해요",
                color = Ink2,
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center
            )
        }

        Spacer(Modifier.weight(1f))

        // Kakao
        SocialButton(
            label = "카카오로 시작하기",
            background = Color(0xFFFEE500),
            foreground = Color.Black,
            icon = Icons.Outlined.Chat,
            onClick = onLoggedIn
        )

        // Google
        SocialButton(
            label = "Google로 계속하기",
            background = Color.White,
            foreground = Color.Black,
            border = true,
            // 임시 아이콘 — Q2 결정 후 Google G 로고로 교체
            icon = null,
            onClick = onLoggedIn
        )

        // 약관 안내 (하단)
        Text(
            "로그인 시 이용약관 및 개인정보처리방침에 동의합니다",
            color = Ink3,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
        )
    }
}

@Composable
private fun SocialButton(
    label: String,
    background: Color,
    foreground: Color,
    border: Boolean = false,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    onClick: () -> Unit
) {
    val base = Modifier
        .fillMaxWidth()
        .height(52.dp)
        .clip(RoundedCornerShape(12.dp))
        .background(background)
    val withBorder = if (border) base.border(1.dp, Line, RoundedCornerShape(12.dp)) else base

    Box(
        modifier = withBorder.clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
            if (icon != null) {
                Icon(icon, contentDescription = null, tint = foreground, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(
                label,
                color = foreground,
                style = MaterialTheme.typography.titleLarge
            )
        }
    }
}
