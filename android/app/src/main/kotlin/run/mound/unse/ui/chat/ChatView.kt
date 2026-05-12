package run.mound.unse.ui.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Send
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import run.mound.unse.ui.theme.Bg
import run.mound.unse.ui.theme.Ink1
import run.mound.unse.ui.theme.Ink2
import run.mound.unse.ui.theme.Ink3
import run.mound.unse.ui.theme.LavenderDeep
import run.mound.unse.ui.theme.Spacing
import run.mound.unse.ui.theme.Surface

/**
 * 하루결 ChatView — AI 챗봇.
 * iOS ChatView.swift 대응.
 *
 * v1: UI shell만 — 메시지 입력/표시. SSE streaming 실제 호출은
 * Supabase Kotlin SDK 통합 (Q4) + Edge function `chat` wiring 후.
 */
private data class ChatMessage(val text: String, val isMine: Boolean)

@Composable
fun ChatView(modifier: Modifier = Modifier) {
    val messages = remember {
        mutableStateListOf<ChatMessage>(
            ChatMessage("안녕하세요! 사주에 대해 궁금한 점을 물어보세요.", isMine = false)
        )
    }
    var input by remember { mutableStateOf("") }

    Column(
        modifier = modifier.fillMaxSize().background(Bg)
    ) {
        Text(
            "AI 챗봇",
            style = MaterialTheme.typography.headlineMedium,
            color = Ink1,
            modifier = Modifier.padding(Spacing.xxl)
        )

        LazyColumn(
            modifier = Modifier.weight(1f).padding(horizontal = Spacing.xxl),
            verticalArrangement = Arrangement.spacedBy(Spacing.md)
        ) {
            items(messages) { msg ->
                MessageBubble(msg)
            }
        }

        // 입력
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Surface)
                .padding(Spacing.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                placeholder = { Text("사주에 대해 물어보세요") },
                modifier = Modifier.weight(1f),
                singleLine = true
            )
            IconButton(
                onClick = {
                    if (input.isNotBlank()) {
                        messages.add(ChatMessage(input, isMine = true))
                        messages.add(
                            ChatMessage(
                                "AI 응답은 향후 업데이트에서 제공됩니다. (Q3/Q4 합의 후 wiring)",
                                isMine = false
                            )
                        )
                        input = ""
                    }
                }
            ) {
                Icon(Icons.Outlined.Send, contentDescription = "전송", tint = LavenderDeep)
            }
        }
    }
}

@Composable
private fun MessageBubble(msg: ChatMessage) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = if (msg.isMine) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Text(
            text = msg.text,
            color = if (msg.isMine) Color.White else Ink1,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier
                .padding(start = if (msg.isMine) 60.dp else 0.dp, end = if (msg.isMine) 0.dp else 60.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(if (msg.isMine) LavenderDeep else Surface)
                .padding(horizontal = Spacing.lg, vertical = Spacing.md)
        )
    }
}
