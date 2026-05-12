package run.mound.unse.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.Line
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface

/**
 * 하루결 Card — iOS Card.swift 대응.
 * 흰 배경 + 라인 보더 + 둥근 모서리.
 */
@Composable
fun UnseCard(
    modifier: Modifier = Modifier,
    padding: Dp = Spacing.lg,
    content: @Composable () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Spacing.radiusLg))
            .background(Surface)
            .border(1.dp, Line, RoundedCornerShape(Spacing.radiusLg))
            .padding(padding)
    ) {
        content()
    }
}
