package run.mound.unse.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = LavenderDeep,
    onPrimary = Surface,
    primaryContainer = LavenderSoft,
    onPrimaryContainer = Ink1,
    secondary = Peach,
    background = Bg,
    onBackground = Ink1,
    surface = Surface,
    onSurface = Ink1,
    surfaceVariant = SurfaceAlt,
    onSurfaceVariant = Ink2,
    outline = Line,
    error = Error,
    onError = Surface
)

@Composable
fun UnseTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        typography = Type,
        content = content
    )
}
