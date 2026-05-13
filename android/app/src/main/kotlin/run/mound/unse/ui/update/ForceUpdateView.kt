package run.mound.unse.ui.update

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowCircleUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 ForceUpdateView — iOS `ForceUpdateView.swift` 대응.
 * dismiss 불가. "업데이트하기" 버튼만. Play Store URL fallback OK.
 */
@Composable
fun ForceUpdateView(message: String, storeUrl: String?) {
    val context = LocalContext.current
    Box(
        modifier = Modifier.fillMaxSize().background(Bg),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.size(Spacing.xxxl))
            Icon(
                imageVector = Icons.Filled.ArrowCircleUp,
                contentDescription = null,
                tint = LavenderDeep,
                modifier = Modifier.size(72.dp)
            )
            Spacer(Modifier.size(Spacing.xl))
            Text(
                "새 버전이 있어요",
                style = MaterialTheme.typography.headlineLarge,
                color = Ink1,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.size(Spacing.md))
            Text(
                message,
                style = MaterialTheme.typography.bodyMedium,
                color = Ink2,
                textAlign = TextAlign.Center,
                lineHeight = 22.sp
            )
            Spacer(Modifier.size(Spacing.xxxl))
            PrimaryButton(
                title = "업데이트하기",
                modifier = Modifier.fillMaxWidth()
            ) {
                val target = storeUrl ?: "https://play.google.com/store/apps/details?id=${context.packageName}"
                runCatching {
                    context.startActivity(
                        Intent(Intent.ACTION_VIEW, target.toUri()).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                    )
                }
            }
        }
    }
}
