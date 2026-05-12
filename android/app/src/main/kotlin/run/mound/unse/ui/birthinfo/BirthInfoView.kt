package run.mound.unse.ui.birthinfo

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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import run.mound.unse.manse.BirthInput
import run.mound.unse.manse.Gender
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 BirthInfoView — 생년월일·시·성별·닉네임 입력.
 * iOS BirthInfoView.swift 대응.
 *
 * v1: 양력만 (Q4 lunar 변환 미구현). LUNAR 옵션은 disabled.
 */
@Composable
fun BirthInfoView(onSubmit: (BirthInput) -> Unit) {
    var year by remember { mutableStateOf("1990") }
    var month by remember { mutableStateOf("3") }
    var day by remember { mutableStateOf("15") }
    var hour by remember { mutableStateOf("12") }
    var minute by remember { mutableStateOf("0") }
    var nickname by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf(Gender.FEMALE) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.xxl, vertical = Spacing.xxxl),
        verticalArrangement = Arrangement.spacedBy(Spacing.xl)
    ) {
        Text("출생 정보를\n입력해주세요", style = MaterialTheme.typography.displaySmall, color = Ink1)
        Text("사주 계산을 위해 정확히 입력해주세요", color = Ink2, style = MaterialTheme.typography.bodyMedium)

        // 생년월일
        FormLabel("생년월일")
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            NumberField(year, "년", Modifier.weight(1.4f)) { year = it }
            NumberField(month, "월", Modifier.weight(1f)) { month = it }
            NumberField(day, "일", Modifier.weight(1f)) { day = it }
        }

        // 시간
        FormLabel("태어난 시간")
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            NumberField(hour, "시", Modifier.weight(1f)) { hour = it }
            NumberField(minute, "분", Modifier.weight(1f)) { minute = it }
        }

        // 성별
        FormLabel("성별")
        Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
            GenderButton("여성", gender == Gender.FEMALE, Modifier.weight(1f)) { gender = Gender.FEMALE }
            GenderButton("남성", gender == Gender.MALE, Modifier.weight(1f)) { gender = Gender.MALE }
        }

        // 닉네임
        FormLabel("닉네임")
        OutlinedTextField(
            value = nickname,
            onValueChange = { nickname = it },
            placeholder = { Text("앱에서 부를 이름") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        Spacer(Modifier.height(Spacing.xl))

        val input = BirthInput(
            year = year.toIntOrNull() ?: 0,
            month = month.toIntOrNull() ?: 0,
            day = day.toIntOrNull() ?: 0,
            hour = hour.toIntOrNull(),
            minute = minute.toIntOrNull(),
            gender = gender,
            nickname = nickname
        )
        PrimaryButton(
            title = "사주 분석 시작",
            enabled = input.isValid && nickname.isNotBlank()
        ) { onSubmit(input) }
    }
}

@Composable
private fun FormLabel(text: String) {
    Text(text, style = MaterialTheme.typography.labelLarge, color = Ink1)
}

@Composable
private fun NumberField(value: String, suffix: String, modifier: Modifier, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value,
        onValueChange = { if (it.all(Char::isDigit)) onChange(it) },
        modifier = modifier,
        suffix = { Text(suffix) },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        singleLine = true
    )
}

@Composable
private fun GenderButton(label: String, selected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    PrimaryButton(
        title = label,
        color = if (selected) run.mound.unse.ui.theme.LavenderDeep else run.mound.unse.ui.theme.SurfaceAlt,
        modifier = modifier,
        onClick = onClick
    )
}
