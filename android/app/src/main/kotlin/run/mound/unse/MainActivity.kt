package run.mound.unse

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import run.mound.unse.ui.AppNavigation
import run.mound.unse.ui.theme.UnseTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            UnseTheme {
                AppNavigation()
            }
        }
    }
}
