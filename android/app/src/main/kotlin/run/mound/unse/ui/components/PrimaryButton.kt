package run.mound.unse.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Surface

/**
 * 하루결 PrimaryButton — iOS PrimaryButton.swift 대응.
 * 라벤더 배경, 흰 텍스트, 52pt 높이, 둥근 모서리.
 */
@Composable
fun PrimaryButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    color: Color = LavenderDeep,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(color)
            .alpha(if (enabled) 1f else 0.5f)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            color = Surface,
            style = MaterialTheme.typography.titleLarge
        )
    }
}
