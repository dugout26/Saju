package run.mound.unse.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import run.mound.unse.manse.BirthCalendar
import run.mound.unse.manse.BirthInput
import run.mound.unse.manse.Gender
import run.mound.unse.ui.components.CheckBox
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.components.Segment
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 EditSajuView — iOS `EditSajuView.swift` 대응.
 * 기존 출생 정보 prefill → 저장. 변경 시 사주 재계산.
 *
 * v1: UI shell + 폼 검증. recompute / Subscription 제한 wiring은 Q3/Q4 합의 후.
 */
@Composable
fun EditSajuView(initial: BirthInput, onSave: (BirthInput) -> Unit) {
    var input by remember { mutableStateOf(initial) }
    var year by remember { mutableStateOf(initial.year.toString()) }
    var month by remember { mutableStateOf(initial.month.toString()) }
    var day by remember { mutableStateOf(initial.day.toString()) }
    var hour by remember { mutableStateOf(initial.hour?.toString() ?: "") }
    var minute by remember { mutableStateOf(initial.minute?.toString() ?: "") }
    var hourUnknownFlag by remember { mutableStateOf(initial.hour == null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.xxl, vertical = Spacing.xxxl),
        verticalArrangement = Arrangement.spacedBy(Spacing.xl)
    ) {
        Text("출생 정보를\n수정할 수 있어요", style = MaterialTheme.typography.headlineLarge, color = Ink1)
        Text("저장하면 사주가 다시 계산되고 풀이도 갱신됩니다", color = Ink3, style = MaterialTheme.typography.bodySmall)

        FormLabel("달력 기준")
        Segment(
            options = BirthCalendar.entries.map { it.korean },
            selection = input.calendar.korean,
            onChange = { korean ->
                input = input.copy(calendar = BirthCalendar.entries.first { it.korean == korean })
            }
        )

        FormLabel("생년월일")
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            NumberField(year, "년", Modifier.weight(1.4f)) { year = it }
            NumberField(month, "월", Modifier.weight(1f)) { month = it }
            NumberField(day, "일", Modifier.weight(1f)) { day = it }
        }

        FormLabel("태어난 시간")
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            NumberField(if (hourUnknownFlag) "" else hour, "시", Modifier.weight(1f), enabled = !hourUnknownFlag) { hour = it }
            NumberField(if (hourUnknownFlag) "" else minute, "분", Modifier.weight(1f), enabled = !hourUnknownFlag) { minute = it }
        }
        CheckBox(
            label = "시 모름",
            isChecked = hourUnknownFlag,
            onChange = { unknown ->
                hourUnknownFlag = unknown
                if (unknown) { hour = ""; minute = "" } else { hour = "12"; minute = "0" }
            }
        )

        FormLabel("성별")
        Segment(
            options = Gender.entries.map { it.korean },
            selection = input.gender.korean,
            onChange = { korean ->
                input = input.copy(gender = Gender.entries.first { it.korean == korean })
            }
        )

        FormLabel("닉네임")
        OutlinedTextField(
            value = input.nickname,
            onValueChange = { input = input.copy(nickname = it) },
            placeholder = { Text("앱에서 부를 이름") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        Spacer(Modifier.height(Spacing.lg))

        val finalInput = input.copy(
            year = year.toIntOrNull() ?: input.year,
            month = month.toIntOrNull() ?: input.month,
            day = day.toIntOrNull() ?: input.day,
            hour = if (hourUnknownFlag) null else hour.toIntOrNull(),
            minute = if (hourUnknownFlag) null else minute.toIntOrNull()
        )
        PrimaryButton(
            title = "저장",
            enabled = finalInput.isValid && finalInput.nickname.isNotBlank()
        ) { onSave(finalInput) }
    }
}

@Composable
private fun FormLabel(text: String) {
    Text(text, style = MaterialTheme.typography.labelLarge, color = Ink1)
}

@Composable
private fun NumberField(
    value: String,
    suffix: String,
    modifier: Modifier,
    enabled: Boolean = true,
    onChange: (String) -> Unit
) {
    OutlinedTextField(
        value = value,
        onValueChange = { if (it.all(Char::isDigit)) onChange(it) },
        modifier = modifier,
        enabled = enabled,
        suffix = { Text(suffix) },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        singleLine = true
    )
}
