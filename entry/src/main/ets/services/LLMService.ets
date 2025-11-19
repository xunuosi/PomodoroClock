import http from '@ohos.net.http';
import { DailyStat } from '../model/Types';

const API_KEY = "YOUR_GEMINI_API_KEY";
const BASE_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${API_KEY}`;

// 1. 定义 Gemini 返回数据的结构 (为了解决 ArkTS 无法直接访问 Object 属性的问题)
class GeminiPart {
  text: string = "";
}

class GeminiContent {
  parts: GeminiPart[] = [];
}

class GeminiCandidate {
  content: GeminiContent = new GeminiContent();
}

class GeminiResponse {
  candidates: GeminiCandidate[] = [];
}

export class GeminiService {
  static async generateProductivityInsight(stats: DailyStat[], totalFocusMinutes: number): Promise<string> {
    const prompt = `
      You are a productivity coach for a Pomodoro timer app.
      Based on the following user data, provide a short, encouraging, and specific insight (max 2 sentences).

      Data:
      - Total Focus Time: ${totalFocusMinutes} minutes
      - Recent Activity (Last 7 days): ${JSON.stringify(stats)}

      Tone: Motivating, concise, friendly.
    `;

    try {
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(BASE_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        // 建议显式指定期望返回 string，防止系统自动解析为 Object
        expectDataType: http.HttpDataType.STRING,
        extraData: {
          "contents": [{
            "parts": [{ "text": prompt }]
          }]
        }
      });

      if (response.responseCode === 200) {
        // 2. 安全处理 response.result
        let resultStr: string = "";

        if (typeof response.result === 'string') {
          resultStr = response.result;
        } else {
          // 如果系统已经自动转换成了对象，将其转回字符串或直接处理
          resultStr = JSON.stringify(response.result);
        }

        // 3. 解析并断言类型为 GeminiResponse
        const result = JSON.parse(resultStr) as GeminiResponse;

        // 4. 使用可选链安全访问 (配合上面定义的类结构)
        return result.candidates?.[0]?.content?.parts?.[0]?.text || "Keep focusing!";
      }
      return "Great job focusing today!";
    } catch (error) {
      console.error("Gemini API Error:", error);
      return "Consistency is key. Keep it up!";
    }
  }
}