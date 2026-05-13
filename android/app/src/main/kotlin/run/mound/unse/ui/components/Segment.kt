package run.mound.unse.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Surface
import run.mound.unse.ui.theme.SurfaceAlt

/**
 * iOS `Segment.swift` 대응. 가로 토글 셀렉터.
 */
@Composable
fun Segment(
    options: List<String>,
    selection: String,
    onChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(SurfaceAlt)
            .padding(4.dp),
    ) {
        options.forEach { opt ->
            val isSelected = opt == selection
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .height(44.dp)
                    .clip(RoundedCornerShape(11.dp))
                    .background(if (isSelected) Surface else androidx.compose.ui.graphics.Color.Transparent)
                    .clickable { onChange(opt) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = opt,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (isSelected) Ink1 else Ink3
                )
            }
        }
    }
}
