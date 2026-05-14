package run.mound.unse.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.components.Tag
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Cream
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.Lavender
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.LavenderSoft
import run.mound.unse.ui.theme.Mint
import run.mound.unse.ui.theme.Peach
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface

/**
 * 하루결 OnboardingView — iOS OnboardingView.swift 1:1.
 * 3 슬라이드: 행운의 색 / AI 해설 / 평생 흐름.
 *
 * 레이아웃: skipButton 위 + artPager (weight 1) + copySection 아래 고정.
 */

private enum class ArtKind { COLORS, CHAT, TIMELINE }

private data class OnboardSlide(
    val eyebrow: String,
    val titleA: String,
    val titleB: String,
    val subtitle: String,
    val art: ArtKind
)

private val slides = listOf(
    OnboardSlide(
        eyebrow = "매일 아침",
        titleA = "오늘의",
        titleB = "행운 색",
        subtitle = "사주 8글자에서 풀어낸\n오늘의 색·방향·시간",
        art = ArtKind.COLORS
    ),
    OnboardSlide(
        eyebrow = "AI 해설",
        titleA = "진짜 사주를",
        titleB = "풀어드려요",
        subtitle = "카톡 운세 말고,\n진짜 명리학 기반 풀이",
        art = ArtKind.CHAT
    ),
    OnboardSlide(
        eyebrow = "평생의 흐름",
        titleA = "지금이",
        titleB = "어떤 시기인지",
        subtitle = "대운 그래프로 보는\n인생의 정점과 저점",
        art = ArtKind.TIMELINE
    )
)

@Composable
fun OnboardingView(onFinish: () -> Unit) {
    val pagerState = rememberPagerState(pageCount = { slides.size })
    val scope = rememberCoroutineScope()

    Column(modifier = Modifier.fillMaxSize().background(Bg)) {
        // 상단 Skip
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.lg, vertical = Spacing.sm),
            horizontalArrangement = Arrangement.End
        ) {
            Text(
                text = "건너뛰기",
                color = Ink3,
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.clickable { onFinish() }.padding(Spacing.sm)
            )
        }

        // Art Pager — 위쪽 영역 (flex)
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = Spacing.xxxl)
        ) { page ->
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                when (slides[page].art) {
                    ArtKind.COLORS -> ColorCardsArt()
                    ArtKind.CHAT -> ChatArt()
                    ArtKind.TIMELINE -> TimelineArt()
                }
            }
        }

        // Copy 섹션 — 하단 고정
        val s = slides[pagerState.currentPage]
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.xxxl, vertical = 0.dp)
                .padding(bottom = 32.dp)
        ) {
            Tag(text = s.eyebrow)
            Spacer(Modifier.height(14.dp))
            Text(
                text = "${s.titleA}\n${s.titleB}",
                style = MaterialTheme.typography.displayLarge,
                color = Ink1,
                lineHeight = 42.sp
            )
            Spacer(Modifier.height(14.dp))
            Text(
                text = s.subtitle,
                color = Ink2,
                style = MaterialTheme.typography.bodyMedium,
                lineHeight = 22.sp
            )

            // Dots
            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 28.dp, bottom = 20.dp),
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

            val isLast = pagerState.currentPage == slides.size - 1
            PrimaryButton(title = if (isLast) "시작하기" else "다음") {
                if (isLast) onFinish()
                else scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
            }
        }
    }
}

// MARK: - ColorCardsArt (iOS OnboardArtColors — floating cards with rotation)

@Composable
private fun ColorCardsArt() {
    Box(modifier = Modifier.size(280.dp), contentAlignment = Alignment.Center) {
        FloatingCard("라벤더", Lavender, angle = -12f, x = (-65).dp, y = (-60).dp)
        FloatingCard("피치", Peach, angle = 6f, x = 40.dp, y = (-15).dp)
        FloatingCard("민트", Mint, angle = -8f, x = (-35).dp, y = 60.dp)
        FloatingCard("크림", Cream, angle = 10f, x = 55.dp, y = 65.dp)
    }
}

@Composable
private fun FloatingCard(
    label: String,
    color: Color,
    angle: Float,
    x: androidx.compose.ui.unit.Dp,
    y: androidx.compose.ui.unit.Dp
) {
    Box(
        modifier = Modifier
            .offset(x = x, y = y)
            .rotate(angle)
            .size(130.dp, 170.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(color),
        contentAlignment = Alignment.BottomStart
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(
                text = "TODAY",
                color = Color.Black.copy(alpha = 0.5f),
                style = MaterialTheme.typography.labelSmall,
                letterSpacing = 1.sp
            )
            Spacer(Modifier.height(2.dp))
            Text(text = label, style = MaterialTheme.typography.titleLarge, color = Ink1)
        }
    }
}

// MARK: - ChatArt (iOS OnboardArtChat — 2 bubbles + typing indicator)

@Composable
private fun ChatArt() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.lg),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // 사용자 메시지
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            Text(
                text = "올해 이직해도 괜찮을까요?",
                color = Color.White,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier
                    .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomStart = 20.dp, bottomEnd = 4.dp))
                    .background(Ink1)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            )
        }
        // AI 응답
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
            Text(
                text = "戊土 일간에\n木 대운이 들어오는 시기네요.\n새 시작이 잘 풀리는 흐름으로 해석됩니다.",
                color = Ink1,
                style = MaterialTheme.typography.bodyMedium,
                lineHeight = 20.sp,
                modifier = Modifier
                    .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomStart = 4.dp, bottomEnd = 20.dp))
                    .background(Surface)
                    .padding(horizontal = 18.dp, vertical = 14.dp)
            )
        }
        // Typing indicator
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Start) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(Surface)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                repeat(3) { i ->
                    Box(
                        modifier = Modifier
                            .size(6.dp)
                            .clip(RoundedCornerShape(50))
                            .background(LavenderDeep.copy(alpha = (3 - i) / 3f))
                    )
                }
            }
        }
    }
}

// MARK: - TimelineArt (iOS OnboardArtTimeline — zone bars + lines)

@Composable
private fun TimelineArt() {
    Row(
        modifier = Modifier.fillMaxWidth().size(width = 280.dp, height = 200.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.Bottom
    ) {
        // 평생 흐름 막대 — 3개 zone (저 / 평 / 고)
        listOf(60, 80, 110, 140, 120, 100, 80, 60).forEachIndexed { i, h ->
            val color = when {
                i < 3 -> LavenderSoft
                i < 6 -> Peach.copy(alpha = 0.6f)
                else -> Mint.copy(alpha = 0.6f)
            }
            Box(
                modifier = Modifier
                    .size(20.dp, h.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(color)
            )
        }
    }
}
