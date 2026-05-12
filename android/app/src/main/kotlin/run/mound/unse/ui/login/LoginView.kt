package run.mound.unse.ui.login

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 LoginView — 간편 로그인 화면.
 *
 * Q2 결정 대기 중 (Kakao + Google vs Kakao + Apple).
 * 현재는 UI 골격만 — 실제 SDK 통합은 Q2 합의 후 Session 3.
 */
@Composable
fun LoginView(onLoggedIn: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().background(Bg).padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
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
        Spacer(Modifier.height(Spacing.xxxl))

        // Kakao 버튼 (TODO Q2 결정 후 실제 SDK 연결)
        SocialButton(
            label = "카카오로 시작하기",
            background = Color(0xFFFEE500),
            foreground = Color.Black,
            onClick = onLoggedIn
        )
        Spacer(Modifier.height(Spacing.md))
        // Google 버튼 (Q2 잠정 — Apple Sign-In Android는 web view라 UX 어색)
        SocialButton(
            label = "Google로 계속하기",
            background = Color.White,
            foreground = Color.Black,
            border = true,
            onClick = onLoggedIn
        )

        Spacer(Modifier.height(Spacing.xxl))
        Text(
            "로그인 시 이용약관 및 개인정보처리방침에 동의합니다",
            color = Ink3,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun SocialButton(
    label: String,
    background: Color,
    foreground: Color,
    border: Boolean = false,
    onClick: () -> Unit
) {
    PrimaryButton(title = label, color = background, onClick = onClick)
    // TODO: foreground 색 + border 적용은 PrimaryButton 확장 시
}
