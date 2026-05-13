package run.mound.unse.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Line
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface
import run.mound.unse.ui.theme.UnseTheme

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

@Preview(showBackground = true, backgroundColor = 0xFFF7F4FB)
@Composable
private fun UnseCardPreview() {
    UnseTheme {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            UnseCard {
                Text("오늘의 운세", color = Ink1, style = MaterialTheme.typography.titleMedium)
                Text("차분히 듣는 자세가 인연을 부르는 날입니다.", color = Ink1)
            }
        }
    }
}
