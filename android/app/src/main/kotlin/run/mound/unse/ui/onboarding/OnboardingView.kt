package run.mound.unse.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.components.Tag
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Cream
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Lavender
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Mint
import run.mound.unse.ui.theme.Peach
import run.mound.unse.ui.theme.Spacing

/**
 * 하루결 OnboardingView — iOS OnboardingView.swift 1:1 대응.
 * 4 슬라이드 carousel: 행운의 색 / 사주 풀이 / 평생 흐름 / AI 챗봇.
 */

private data class OnboardingSlide(
    val tag: String,
    val title: String,
    val subtitle: String,
    val visual: @Composable () -> Unit
)

@Composable
fun OnboardingView(onFinish: () -> Unit) {
    val slides = listOf(
        OnboardingSlide("매일 아침", "오늘의\n행운 색", "사주 8글자에서 풀어낸\n오늘의 색·방향·시간") { ColorCardStack() },
        OnboardingSlide("AI 풀이", "사주 8글자를\n친근하게", "전통 명리학을 AI가\n쉬운 말로 풀어드려요") { SajuPreview() },
        OnboardingSlide("평생의 흐름", "10년 단위로\n바뀌는 대운", "큰 흐름 안에서\n오늘 하루를 봐요") { TimelinePreview() },
        OnboardingSlide("AI 챗봇", "궁금한 것\n무엇이든", "올해 금전운부터\n잘 맞는 사람까지") { ChatPreview() }
    )

    val pagerState = rememberPagerState(pageCount = { slides.size })
    val scope = rememberCoroutineScope()

    Column(modifier = Modifier.fillMaxSize().background(Bg)) {
        // 상단 Skip
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.xxl, vertical = Spacing.lg),
            horizontalArrangement = Arrangement.End
        ) {
            Text(
                text = "건너뛰기",
                color = Ink3,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.clickable { onFinish() }
            )
        }

        // Pager (weight 1f)
        HorizontalPager(state = pagerState, modifier = Modifier.weight(1f)) { page ->
            SlideContent(slides[page])
        }

        // Dots
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.lg),
            horizontalArrangement = Arrangement.Center
        ) {
            repeat(slides.size) { i ->
                val selected = pagerState.currentPage == i
                Box(
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .size(if (selected) 24.dp else 8.dp, 8.dp)
                        .clip(RoundedCornerShape(50))
                        .background(if (selected) LavenderDeep else Lavender.copy(alpha = 0.4f))
                )
            }
        }

        // Next / Done
        Box(modifier = Modifier.padding(horizontal = Spacing.xxl, vertical = Spacing.lg)) {
            val isLast = pagerState.currentPage == slides.size - 1
            PrimaryButton(title = if (isLast) "시작하기" else "다음") {
                if (isLast) onFinish()
                else scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
            }
        }
    }
}

@Composable
private fun SlideContent(slide: OnboardingSlide) {
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = Spacing.xxl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        slide.visual()
        Spacer(Modifier.height(Spacing.xxxl))
        Tag(text = slide.tag)
        Spacer(Modifier.height(Spacing.md))
        Text(
            text = slide.title,
            style = MaterialTheme.typography.displayMedium,
            textAlign = TextAlign.Center,
            lineHeight = 36.sp
        )
        Spacer(Modifier.height(Spacing.md))
        Text(
            text = slide.subtitle,
            color = Ink2,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
            lineHeight = 22.sp
        )
    }
}

// MARK: - Placeholder visuals (실제 일러스트는 후속 작업)

@Composable
private fun ColorCardStack() {
    Box(modifier = Modifier.size(220.dp), contentAlignment = Alignment.Center) {
        ColorCard("크림", Cream, -40.dp to -10.dp)
        ColorCard("민트", Mint, -10.dp to 10.dp)
        ColorCard("피치", Peach, 20.dp to 0.dp)
        ColorCard("라벤더", Lavender, 50.dp to 10.dp)
    }
}

@Composable
private fun ColorCard(
    label: String,
    color: Color,
    offset: Pair<androidx.compose.ui.unit.Dp, androidx.compose.ui.unit.Dp>
) {
    Box(
        modifier = Modifier
            .offset(x = offset.first, y = offset.second)
            .size(100.dp, 130.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(color),
        contentAlignment = Alignment.BottomStart
    ) {
        Text(
            text = "TODAY\n$label",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(12.dp)
        )
    }
}

@Composable
private fun SajuPreview() {
    Box(
        modifier = Modifier
            .size(220.dp, 160.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(Lavender.copy(alpha = 0.3f)),
        contentAlignment = Alignment.Center
    ) {
        Text("戊 己 庚 辛", style = MaterialTheme.typography.displaySmall, color = LavenderDeep)
    }
}

@Composable
private fun TimelinePreview() {
    Row(
        modifier = Modifier.size(220.dp, 160.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.Bottom
    ) {
        listOf(40, 60, 80, 100, 80, 60, 40, 50).forEach { h ->
            Box(
                modifier = Modifier
                    .size(16.dp, h.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(Lavender.copy(alpha = 0.6f))
            )
        }
    }
}

@Composable
private fun ChatPreview() {
    Column(
        modifier = Modifier.size(220.dp, 160.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically)
    ) {
        ChatBubble("이번 달 운세는?", isMine = true)
        ChatBubble("새로운 시작에 좋은 시기예요", isMine = false)
    }
}

@Composable
private fun ChatBubble(text: String, isMine: Boolean) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = if (isMine) 40.dp else 0.dp, vertical = 2.dp),
        contentAlignment = if (isMine) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Text(
            text = text,
            color = if (isMine) Color.White else Ink2,
            style = MaterialTheme.typography.bodySmall,
            modifier = Modifier
                .clip(RoundedCornerShape(14.dp))
                .background(if (isMine) LavenderDeep else Color.White)
                .padding(horizontal = 12.dp, vertical = 8.dp)
        )
    }
}
