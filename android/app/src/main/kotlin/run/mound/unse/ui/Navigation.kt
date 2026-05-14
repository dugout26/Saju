package run.mound.unse.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import run.mound.unse.manse.BirthInput
import run.mound.unse.manse.DaeWoon
import run.mound.unse.manse.SajuComputed
import run.mound.unse.ui.analyzing.AnalyzingView
import run.mound.unse.ui.birthinfo.BirthInfoView
import run.mound.unse.ui.legal.LegalDocumentView
import run.mound.unse.ui.legal.LegalKind
import run.mound.unse.ui.login.LoginView
import run.mound.unse.ui.main.MainTabView
import run.mound.unse.ui.onboarding.OnboardingView
import run.mound.unse.ui.settings.EditSajuView
import run.mound.unse.ui.share.ShareCardView

/**
 * 하루결 Android Navigation.
 *
 * Onboarding → Login → BirthInfo → Analyzing → SajuResult.
 *
 * 인증/DB/구독 wiring은 Q1-Q6 합의 후 Session 3+. v1은 화면 흐름만.
 */
object Routes {
    const val ONBOARDING = "onboarding"
    const val LOGIN = "login"
    const val BIRTH_INFO = "birth_info"
    const val ANALYZING = "analyzing"
    const val SAJU_RESULT = "saju_result"
    const val MAIN = "main"
    const val EDIT_SAJU = "edit_saju"
    const val SHARE = "share"
    const val LEGAL = "legal/{kind}"
    fun legal(kind: LegalKind) = "legal/${kind.name}"
}

@Composable
fun AppNavigation() {
    val nav = rememberNavController()

    // v1 임시 — Q4 (Room) 적용 전까지 in-memory state로 BirthInput + Saju 전달.
    var pendingInput by remember { mutableStateOf<BirthInput?>(null) }
    var pendingSaju by remember { mutableStateOf<Pair<SajuComputed, List<DaeWoon>>?>(null) }
    var nickname by remember { mutableStateOf("사용자") }

    NavHost(navController = nav, startDestination = Routes.ONBOARDING) {
        composable(Routes.ONBOARDING) {
            OnboardingView(onFinish = { nav.navigate(Routes.LOGIN) })
        }
        composable(Routes.LOGIN) {
            LoginView(onLoggedIn = { nav.navigate(Routes.BIRTH_INFO) })
        }
        composable(Routes.BIRTH_INFO) {
            BirthInfoView(onSubmit = { input ->
                pendingInput = input
                nickname = input.nickname.ifBlank { "사용자" }
                nav.navigate(Routes.ANALYZING)
            })
        }
        composable(Routes.ANALYZING) {
            // CR fix: 빈 화면 회피 — pendingInput null 시 BIRTH_INFO로 안전 redirect
            // (앱 강제 종료 후 deep-link 진입 등의 엣지 케이스).
            val input = pendingInput
            if (input == null) { RedirectToBirthInfo(nav); return@composable }
            AnalyzingView(input = input, onComplete = { saju, daeWoon ->
                pendingSaju = saju to daeWoon
                nav.navigate(Routes.MAIN) { popUpTo(Routes.LOGIN) { inclusive = false } }
            })
        }
        composable(Routes.MAIN) {
            val pair = pendingSaju
            if (pair == null) { RedirectToBirthInfo(nav); return@composable }
            val (saju, daeWoon) = pair
            MainTabView(
                saju = saju,
                daeWoon = daeWoon,
                nickname = nickname,
                birthYear = pendingInput?.year,
                onEditSaju = { nav.navigate(Routes.EDIT_SAJU) },
                onShare = { nav.navigate(Routes.SHARE) },
                onLegal = { kind -> nav.navigate(Routes.legal(kind)) }
            )
        }
        composable(Routes.EDIT_SAJU) {
            val current = pendingInput
            if (current == null) { RedirectToBirthInfo(nav); return@composable }
            EditSajuView(
                initial = current,
                onSave = { updated ->
                    pendingInput = updated
                    nickname = updated.nickname.ifBlank { "사용자" }
                    nav.popBackStack()
                }
            )
        }
        composable(Routes.SHARE) { ShareCardView(nickname = nickname) }
        composable(
            Routes.LEGAL,
            arguments = listOf(navArgument("kind") { type = NavType.StringType })
        ) { entry ->
            val name = entry.arguments?.getString("kind")
            val kind = LegalKind.entries.firstOrNull { it.name == name } ?: LegalKind.TERMS
            LegalDocumentView(kind = kind)
        }
    }
}

@Composable
private fun RedirectToBirthInfo(nav: NavHostController) {
    LaunchedEffect(Unit) {
        nav.navigate(Routes.BIRTH_INFO) {
            popUpTo(Routes.BIRTH_INFO) { inclusive = true }
        }
    }
}
