import { audio } from '@kit.AudioKit';

export class NoiseService {
  private static audioRenderer: audio.AudioRenderer | null = null;
  private static isPlaying: boolean = false;
  // [优化 1] 提升采样率到 48kHz (移动设备原生标准)，声音更细腻深沉
  // 10秒缓冲区 = 48000 * 10
  private static readonly SAMPLE_RATE: number = 48000;
  private static readonly BUFFER_SIZE: number = 48000 * 10;
  private static pcmBuffer: ArrayBuffer | null = null;

  private static bufferOffset: number = 0;
  private static fadeTimer: number = -1; // 用于控制淡入淡出的计时器

  // 初始化并生成布朗噪音数据
  private static async init() {
    if (NoiseService.audioRenderer) return;

    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: NoiseService.SAMPLE_RATE, // 使用 48k
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
    const data: Int16Array = new Int16Array(bufferLen);

    // 积分状态变量 (不要在循环中直接乘以增益！)
    let state = 0.0;

    for (let i = 0; i < bufferLen; i++) {
      let white = Math.random() * 2 - 1;

      // [修复 2] 还原标准算法系数 (0.02 / 1.02)
      // 这是您提供的 audio.ts 中的原始参数，能产生标准的"红/棕色"噪音频谱
      state = (state + (0.02 * white)) / 1.02;

      // [修复 3] 增益补偿仅作用于"输出值"，不改变"状态值"
      // 之前代码直接修改 lastOut 导致了数值爆炸和高频失真
      let output = state * 3.5;

      // [修复 4] 软限幅 (Soft Clipping)
      // 超过 1.0 的部分平滑处理，避免刺耳的数字削波
      if (output > 1.0) output = 1.0;
      if (output < -1.0) output = -1.0;

      // 转换为 16bit PCM
      data[i] = output * 32767;
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