package run.mound.unse.ui.share

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.rememberGraphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import run.mound.unse.ui.components.PrimaryButton
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Cream
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.LavenderSoft
import run.mound.unse.ui.theme.Surface
import run.mound.unse.ui.theme.UnseTheme
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * 하루결 ShareCardView — iOS `ShareCardView.swift` 대응.
 *
 * Compose `graphicsLayer` 로 카드 캡처 → cache PNG → FileProvider URI → ACTION_SEND.
 * v1: Lavender 테마 1개만. FortuneTheme 전체 포팅은 후속.
 */
@Composable
fun ShareCardView(nickname: String) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val graphicsLayer = rememberGraphicsLayer()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Bg)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 32.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("공유하기", style = MaterialTheme.typography.headlineLarge, color = Ink1)

        // graphicsLayer로 캡처 가능한 컨테이너
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(0.8f)
                .clip(RoundedCornerShape(28.dp))
                .drawWithContent {
                    graphicsLayer.record { this@drawWithContent.drawContent() }
                    drawLayer(graphicsLayer)
                }
        ) {
            ShareCard(nickname = nickname)
        }

        PrimaryButton(title = "다른 앱으로 공유") {
            scope.launch {
                val bitmap = graphicsLayer.toImageBitmap().asAndroidBitmap()
                val uri = withContext(Dispatchers.IO) { saveBitmapToCache(context, bitmap) }
                if (uri == null) {
                    Toast.makeText(context, "이미지 생성 실패", Toast.LENGTH_SHORT).show()
                    return@launch
                }
                val share = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                context.startActivity(Intent.createChooser(share, "공유"))
            }
        }
    }
}

/** PNG로 캐시 dir에 저장 후 FileProvider URI 반환. */
private fun saveBitmapToCache(context: Context, bitmap: Bitmap): android.net.Uri? {
    return runCatching {
        val dir = File(context.cacheDir, "share").apply { mkdirs() }
        val file = File(dir, "saju-${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
    }.getOrNull()
}

/**
 * iOS ShareCard 1:1 — gradient + decorative blobs + 헤더 + one-liner + lucky items + footer.
 */
@Composable
private fun ShareCard(nickname: String) {
    val today = remember {
        val formatter = DateTimeFormatter.ofPattern("yyyy년 M월 d일 EEEE", Locale.KOREAN)
        LocalDate.now().format(formatter)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.linearGradient(listOf(LavenderSoft, Cream)))
    ) {
        // Decorative blobs
        Box(
            modifier = Modifier
                .size(200.dp)
                .clip(CircleShape)
                .background(LavenderSoft.copy(alpha = 0.6f))
                .align(Alignment.TopEnd)
        )
        Box(
            modifier = Modifier
                .size(150.dp)
                .clip(CircleShape)
                .background(LavenderDeep.copy(alpha = 0.15f))
                .align(Alignment.BottomStart)
        )

        Column(
            modifier = Modifier.fillMaxSize().padding(28.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Header
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("운세", style = MaterialTheme.typography.labelMedium, color = LavenderDeep)
                    Spacer(Modifier.height(4.dp))
                    Text(today, style = MaterialTheme.typography.labelSmall, color = Ink3)
                }
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(LavenderSoft),
                    contentAlignment = Alignment.Center
                ) {
                    Text("戊", style = MaterialTheme.typography.titleMedium, color = LavenderDeep)
                }
            }

            // One-liner
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .width(3.dp)
                            .height(16.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(LavenderDeep)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        "오늘의 한 마디",
                        style = MaterialTheme.typography.labelMedium,
                        color = LavenderDeep
                    )
                }
                Spacer(Modifier.height(10.dp))
                Text(
                    "차분히 듣는 자세가\n예상 밖의 인연을 부르는 날입니다.",
                    style = MaterialTheme.typography.headlineMedium,
                    color = Ink1,
                    lineHeight = 28.sp
                )
            }

            // Lucky items
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                LuckItem(icon = "🎨", label = "색상", value = "라벤더", modifier = Modifier.weight(1f))
                LuckItem(icon = "🧭", label = "방향", value = "동쪽", modifier = Modifier.weight(1f))
                LuckItem(icon = "🔢", label = "숫자", value = "3 · 8", modifier = Modifier.weight(1f))
            }

            // Footer
            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    "${nickname}님의 오늘 운세",
                    style = MaterialTheme.typography.labelSmall,
                    color = Ink3,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    "하루결으로 보기 →",
                    style = MaterialTheme.typography.labelMedium,
                    color = LavenderDeep
                )
            }
        }
    }
}

@Composable
private fun LuckItem(icon: String, label: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Surface.copy(alpha = 0.85f))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(icon, fontSize = 20.sp)
        Text(label, style = MaterialTheme.typography.labelSmall, color = Ink3)
        Text(value, style = MaterialTheme.typography.titleSmall, color = Ink1)
    }
}

@Preview(showBackground = true, widthDp = 320, heightDp = 400)
@Composable
private fun ShareCardPreview() {
    UnseTheme {
        Box(modifier = Modifier.fillMaxSize().padding(16.dp)) {
            ShareCard(nickname = "프리뷰")
        }
    }
}
