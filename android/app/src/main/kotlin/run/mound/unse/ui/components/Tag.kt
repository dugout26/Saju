package run.mound.unse.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.LavenderSoft

/**
 * 하루결 Tag — iOS Tag 컴포넌트 대응.
 * 작은 pill 형태 라벨.
 */
@Composable
fun Tag(
    text: String,
    modifier: Modifier = Modifier,
    background: Color = LavenderSoft,
    foreground: Color = LavenderDeep
) {
    Text(
        text = text,
        color = foreground,
        style = MaterialTheme.typography.labelSmall,
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(background)
            .padding(horizontal = 10.dp, vertical = 4.dp)
    )
}
