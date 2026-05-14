package run.mound.unse.ui.analyzing

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import kotlinx.coroutines.delay
import run.mound.unse.manse.BirthInput
import run.mound.unse.manse.Manse
import run.mound.unse.manse.SajuComputed
import run.mound.unse.manse.DaeWoon
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 AnalyzingView — 사주 계산 + AI 풀이 진행 로딩.
 * iOS AnalyzingView.swift 대응.
 *
 * v1: Manse 동기 계산이라 ~1ms. UX상 시각 효과 위해 1.5초 delay.
 * AI 풀이 호출은 Q3/Q4 합의 후 추가.
 */
@Composable
fun AnalyzingView(input: BirthInput, onComplete: (SajuComputed, List<DaeWoon>) -> Unit) {
    LaunchedEffect(input) {
        val result = Manse.calculate(
            year = input.year, month = input.month, day = input.day,
            hour = input.hour, minute = input.minute,
            calendar = input.calendar, gender = input.gender
        )
        delay(1500) // UX 안정감
        onComplete(result.saju, result.daeWoon)
    }

    Column(
        modifier = Modifier.fillMaxSize().background(Bg),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        CircularProgressIndicator(color = LavenderDeep)
        Spacer(Modifier.height(Spacing.xl))
        Text(
            "사주를 풀고 있어요",
            style = MaterialTheme.typography.headlineMedium,
            color = Ink1,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(Spacing.sm))
        Text(
            "잠시만 기다려주세요",
            color = Ink2,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center
        )
    }
}
