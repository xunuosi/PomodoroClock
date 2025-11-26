import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class NoiseService {
  private static audioRenderer: audio.AudioRenderer | null = null;
  private static isPlaying: boolean = false;
  // [修改] 将缓冲区扩大到 2 秒 (44100Hz * 2)，解决"频率过快"的循环噪音问题
  private static readonly BUFFER_SIZE: number = 44100 * 2;
  private static pcmBuffer: ArrayBuffer | null = null;

  private static bufferOffset: number = 0;
  private static fadeTimer: number = -1; // 用于控制淡入淡出的计时器

  // 初始化并生成布朗噪音数据
  private static async init() {
    if (NoiseService.audioRenderer) return;

    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };

    let audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
      rendererFlags: 0
    };

    let audioRendererOptions: audio.AudioRendererOptions = {
      streamInfo: audioStreamInfo,
      rendererInfo: audioRendererInfo
    };

    try {
      NoiseService.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);
      NoiseService.generateBrownNoiseBuffer();
    } catch (err) {
      console.error(`NoiseService create renderer failed: ${err}`);
    }
  }

  // 生成布朗噪音算法 (随机游走)
  private static generateBrownNoiseBuffer() {
    const bufferLen = NoiseService.BUFFER_SIZE;
    const data = new Int16Array(bufferLen);
    let lastOut = 0.0;

    for (let i = 0; i < bufferLen; i++) {
      // 生成 -1.0 到 1.0 的白噪音
      let white = Math.random() * 2 - 1;

      // 积分处理生成布朗噪音 (低通滤波)
      lastOut = (lastOut + (0.02 * white)) / 1.02;

      // 增益补偿并限幅
      lastOut *= 3.5;
      if (lastOut > 1.0) lastOut = 1.0;
      if (lastOut < -1.0) lastOut = -1.0;

      // 转换为 16bit PCM
      data[i] = lastOut * 32767;
    }
    NoiseService.pcmBuffer = data.buffer as ArrayBuffer;
  }

  static async start() {
    if (NoiseService.isPlaying) return;

    try {
      if (!NoiseService.audioRenderer) {
        await NoiseService.init();
      }

      if (NoiseService.audioRenderer) {
        // 1. 移除 'async'，改为同步函数
        // 2. 直接将数据 copy 到回调提供的 buffer 中
        NoiseService.audioRenderer.on('writeData', (buffer: ArrayBuffer) => {
          if (!NoiseService.pcmBuffer) return;

          // 准备数据视图
          let dest = new Int16Array(buffer);
          let src = new Int16Array(NoiseService.pcmBuffer);
          let reqLen = dest.length;
          let srcLen = src.length;

          // 循环填充数据
          for (let i = 0; i < reqLen; i++) {
            dest[i] = src[NoiseService.bufferOffset];
            NoiseService.bufferOffset++;
            // 如果读到了末尾，回到开头 (循环播放)
            if (NoiseService.bufferOffset >= srcLen) {
              NoiseService.bufferOffset = 0;
            }
          }
        });

        await NoiseService.audioRenderer.start();
        NoiseService.isPlaying = true;

        // 执行淡入动画 (2秒内从 0 -> 1.0)
        NoiseService.fadeVolume(0, 1.0, 2000);
      }
    } catch (err) {
      console.error(`NoiseService start failed: ${err}`);
    }
  }

  static async stop() {
    if (!NoiseService.isPlaying || !NoiseService.audioRenderer) return;

    // 执行淡出动画 (1秒内从 当前音量 -> 0)
    // 动画结束后才真正停止和释放资源
    const currentVol = 1.0; // 假设最大是1，或者可以读取 getVolume
    NoiseService.fadeVolume(currentVol, 0, 1000, async () => {
      // 淡出完成后的回调
      try {
        if (NoiseService.audioRenderer) {
          await NoiseService.audioRenderer.stop();
          await NoiseService.audioRenderer.release();
          NoiseService.audioRenderer = null;
        }
        NoiseService.isPlaying = false;
        NoiseService.bufferOffset = 0;
      } catch (err) {
        console.error(`NoiseService stop error: ${err}`);
      }
    });
  }

  // [辅助] 音量渐变控制器
  private static fadeVolume(from: number, to: number, duration: number, onComplete?: () => void) {
    if (NoiseService.fadeTimer !== -1) {
      clearInterval(NoiseService.fadeTimer);
    }

    const steps = 20; // 调整次数
    const intervalTime = duration / steps;
    const stepValue = (to - from) / steps;
    let currentStep = 0;
    let currentVol = from;

    NoiseService.fadeTimer = setInterval(() => {
      currentStep++;
      currentVol += stepValue;

      // 边界保护
      if (currentVol < 0) currentVol = 0;
      if (currentVol > 1) currentVol = 1;

      if (NoiseService.audioRenderer) {
        NoiseService.audioRenderer.setVolume(currentVol);
      }

      if (currentStep >= steps) {
        clearInterval(NoiseService.fadeTimer);
        NoiseService.fadeTimer = -1;
        if (onComplete) {
          onComplete();
        }
      }
    }, intervalTime);
  }
}