package run.mound.unse.ui.main

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Chat
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.ShowChart
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import run.mound.unse.manse.DaeWoon
import run.mound.unse.manse.SajuComputed
import run.mound.unse.ui.chat.ChatView
import run.mound.unse.ui.daily.DailyFortuneView
import run.mound.unse.ui.saju.SajuResultView
import run.mound.unse.ui.settings.SettingsView
import run.mound.unse.ui.timeline.TimelineView

/**
 * 하루결 MainTabView — iOS MainTabView 1:1 대응.
 * 5탭 bottom navigation: 오늘 / 사주 / 평생운 / 챗봇 / 설정.
 */
private enum class Tab(val label: String, val icon: ImageVector) {
    DAILY("오늘", Icons.Outlined.WbSunny),
    SAJU("사주", Icons.Outlined.AccountCircle),
    TIMELINE("평생운", Icons.Outlined.ShowChart),
    CHAT("챗봇", Icons.Outlined.Chat),
    SETTINGS("설정", Icons.Outlined.Settings)
}

@Composable
fun MainTabView(
    saju: SajuComputed,
    daeWoon: List<DaeWoon>,
    nickname: String,
    isPremium: Boolean = false
) {
    var selected by remember { mutableStateOf(Tab.SAJU) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                Tab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = selected == tab,
                        onClick = { selected = tab },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { padding ->
        val mod = Modifier.padding(padding)
        when (selected) {
            Tab.DAILY -> DailyFortuneView(saju = saju, nickname = nickname, modifier = mod)
            Tab.SAJU -> SajuResultView(saju = saju, nickname = nickname, modifier = mod)
            Tab.TIMELINE -> TimelineView(daeWoon = daeWoon, isPremium = isPremium, modifier = mod)
            Tab.CHAT -> ChatView(modifier = mod)
            Tab.SETTINGS -> SettingsView(nickname = nickname, isPremium = isPremium, modifier = mod)
        }
    }
}
