# Liquid Glass 渲染引擎技术设计文档

> 版本: v1.0.0
> 状态: 规划中
> 创建日期: 2026-04-13
> Flutter SDK: >=3.10.0

---

## 目录

1. [概述与目标](#1-概述与目标)
2. [技术可行性验证方案](#2-技术可行性验证方案)
3. [整体架构设计](#3-整体架构设计)
4. [Shader 实现详细设计](#4-shader-实现详细设计)
5. [渲染管线](#5-渲染管线)
6. [物理模拟系统](#6-物理模拟系统)
7. [Widget API 设计](#7-widget-api-设计)
8. [降级策略](#8-降级策略)
9. [实施计划与里程碑](#9-实施计划与里程碑)
10. [文件结构](#10-文件结构)
11. [附录：Shader 代码参考](#11-附录shader-代码参考)

---

## 1. 概述与目标

### 1.1 项目背景

将游戏引擎级渲染技术应用于 2D 超风格化 UI，实现类似苹果 Liquid Glass 的视觉效果。包括：

- **双向光线散射**：物体与背景间颜色相互渗透
- **动态光源系统**：可配置虚拟光源，支持平行光和点光源
- **自发光控制**：开发者可开关元素发光效果
- **真实物理模拟**：弹簧/阻尼系统驱动液态变形
- **全平台支持**：iOS、Android、Web、Windows、macOS
- **优雅降级**：根据设备性能自动选择最佳渲染模式

### 1.2 核心特性列表

| 特性 | 描述 | 优先级 |
|------|------|--------|
| 双向散射 | 背景↔物体颜色渗透，模拟全局光照 | P0 |
| 光源系统 | 平行光/点光源，方向+颜色+强度可配置 | P0 |
| 自发光 | 元素可独立控制发光颜色和强度 | P0 |
| 物理模拟 | 弹簧阻尼系统，物体间碰撞，触摸交互 | P0 |
| 降级方案 | 三档降级：full/simple/fallback | P0 |
| 多平台 | iOS/Android/Web/Windows/macOS | P0 |
| 性能优化 | 分辨率自适应、采样数动态调整 | P1 |
| 风格化效果 | 边缘光晕(Fresnel)、高光(Phong) | P1 |

### 1.3 术语表

| 术语 | 定义 |
|------|------|
| Scatter | 散射，光线在表面间的弹射 |
| Emission | 自发光，元素自身产生的光 |
| Fresnel | 菲涅尔效应，边缘光晕 |
| Ping-Pong Buffer | 双缓冲，用于累积散射反馈 |
| Spring Physics | 弹簧物理，用于液态变形 |
| SSAO | 屏幕空间环境光遮蔽 |

---

## 2. 技术可行性验证方案

### 2.1 验证目标

在正式开发前，验证以下关键技术点：

1. Flutter FragmentProgram API 在各平台的可用性
2. GLSL ES 1.0 兼容代码的编写方式
3. RenderRepaintBoundary 纹理捕获性能
4. Ping-Pong Buffer 反馈累积效果
5. 物理模拟在 Flutter 中的性能表现

### 2.2 验证步骤

#### 阶段 1：Shader 加载验证

```dart
// 最小验证代码
Future<bool> validateShaderLoading() async {
  try {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/validate.frag',
    );
    return program != null;
  } catch (e) {
    return false;
  }
}
```

**验证标准**：
- iOS/Android/Web 能成功加载编译后的 shader
- 无 shader 编译错误

#### 阶段 2：散射效果验证

创建 `validate_scatter` shader，实现：
- 8 方向 Poisson Disk 采样
- 高斯衰减权重
- 反馈累积（上一帧 + 当前帧）

**验证标准**：
- 散射颜色能在相邻区域可见
- 反馈累积产生"渗色"效果

#### 阶段 3：物理验证

创建单按钮物理原型：
- 触摸拖拽产生变形
- 松手后弹簧回弹

**验证标准**：
- 60fps 稳定
- 回弹动画流畅

### 2.3 验证交付物

```
验证阶段/
├── shaders/
│   └── validate_scatter.frag    # 散射验证 shader
├── validate/
│   ├── validate_shader_loading.dart
│   ├── validate_scatter_effect.dart
│   └── validate_physics.dart
└── 验证报告.md
```

---

## 3. 整体架构设计

### 3.1 渲染管线架构

```
┌────────────────────────────────────────────────────────────────────────┐
│                           Flutter Widget Tree                          │
│  LiquidGlassWidget → ShaderContext → PhysicalSimulationWidget          │
│         ↓                    ↓                    ↓                    │
│   [配置层]            [渲染上下文]           [物理引擎]                  │
└────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌────────────────────────────────────────────────────────────────────────┐
│                          渲染管线 (3 Stage Pipeline)                    │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Stage 1: 场景捕获 (Scene Capture)                                  │   │
│  │                                                                   │   │
│  │   RenderRepaintBoundary → 背景纹理 (backgroundTex)               │   │
│  │   RenderRepaintBoundary → 物体纹理 (objectTex)                    │   │
│  │                                                                   │   │
│  │   输入: Widget tree (背景 + 按钮)                                  │   │
│  │   输出: 两个纹理对象，供后续 Pass 使用                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    ↓                                   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Stage 2: 光照与散射 (Light & Scatter)                             │   │
│  │                                                                   │   │
│  │   scatter.frag                                                   │   │
│  │   ├── 环境色采样: backgroundTex 8方向 Poisson 采样               │   │
│  │   │   └── 高斯加权平均 → 环境色 E                                 │   │
│  │   ├── 物体散射: objectTex × 光照方向系数                           │   │
│  │   │   └── 计算散射贡献 S                                         │   │
│  │   ├── 反馈累积: feedbackTex × 0.95 + S × 0.05                    │   │
│  │   └── 输出: scatterTex (供下一帧反馈)                             │   │
│  │                                                                   │   │
│  │   输入: backgroundTex, objectTex, feedbackTex                    │   │
│  │   输出: scatterTex                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    ↓                                   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Stage 3: 合成输出 (Composite)                                    │   │
│  │                                                                   │   │
│  │   composite.frag                                                 │   │
│  │   ├── 基础合成: objectTex + scatterTex 散射影响                   │   │
│  │   ├── 自发光: emissionColor × emissionIntensity (if enabled)     │   │
│  │   ├── 高光: Phong 模型 (R=reflect(-L,N), spec=dot(R,V)^power)    │   │
│  │   ├── 边缘光晕: Fresnel effect (pow(1-dot(N,V), power))         │   │
│  │   └── 输出到屏幕 + 保存到 feedbackTex (ping-pong swap)           │   │
│  │                                                                   │   │
│  │   输入: objectTex, scatterTex                                    │   │
│  │   输出: 最终屏幕图像                                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌────────────────────────────────────────────────────────────────────────┐
│                         物理模拟子系统                                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  LiquidPhysicsEngine                                                    │
│  │                                                                     │
│  ├── 弹簧系统 (Spring System)                                           │
│  │   └── F = -kx - bv  (胡克定律 + 阻尼)                                │
│  │                                                                     │
│  ├── 碰撞系统 (Collision System)                                        │
│  │   ├── AABB 粗检测                                                  │
│  │   ├── 变形量叠加检测                                               │
│  │   └── 弹簧反作用响应                                               │
│  │                                                                     │
│  ├── 触摸交互 (Touch Interaction)                                       │
│  │   ├── onPanStart: 记录触摸点，设置变形方向                          │
│  │   ├── onPanUpdate: 拖拽距离 → 变形量                                │
│  │   ├── onPanEnd: 启动弹簧回弹                                       │
│  │   └── onTapDown: 短暂按压变形 (快速衰减)                             │
│  │                                                                     │
│  └── 力场系统 (Force Field)                                            │
│      ├── 重力 (可选)                                                   │
│      └── 外部力输入                                                    │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌────────────────────────────────────────────────────────────────────────┐
│                          降级决策系统                                    │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  CapabilityDetector                                                     │
│  │                                                                     │
│  ├── GPU Benchmark: 渲染 5 帧简单 shader，测量平均耗时                  │
│  │                                                                     │
│  └── RenderQuality 决策:                                               │
│      ├── full (avg < 8ms):  原生分辨率, 8 采样, 完整反馈               │
│      ├── simple (8-16ms):   0.5x 分辨率, 4 采样, 无反馈累积            │
│      └── fallback:          BackdropFilter + ColorFilter               │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.2 数据流图

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ 背景 Widget │ ──→ │ SceneCapture │ ──→ │backgroundTex│
└─────────────┘     └──────────────┘     └─────────────┘
                                              ↓
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ 按钮 Widget │ ──→ │ SceneCapture │ ──→ │ objectTex   │
└─────────────┘     └──────────────┘     └─────────────┘
                                              ↓
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│feedbackTex │ ←── │ scatter_pass │ ←── │ scatterTex  │
│ (上一帧)    │     └──────────────┘     │ (当前帧)    │
└─────────────┘            ↓            └─────────────┘
                          ↓
┌─────────────┐     ┌──────────────┐
│feedbackTex  │ ←── │ ping-pong    │
│ (下一帧)    │     │ swap         │
└─────────────┘     └──────────────┘
                          ↓
              ┌──────────────────────┐
              │   composite_pass      │
              │   + 高光 + Fresnel    │
              └──────────────────────┘
                          ↓
                   ┌─────────────┐
                   │  最终屏幕   │
                   └─────────────┘
```

### 3.3 组件关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                      LiquidGlassWidget                          │
│  (主组件，StatefulWidget，承载配置和状态)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              LiquidGlassRenderObject                       │ │
│  │  (RenderBox，管理渲染流程)                                  │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │   ┌────────────────┐    ┌────────────────┐                  │ │
│  │   │ LiquidGlass    │    │ LiquidPhysics  │                  │ │
│  │   │ Renderer       │    │ Engine         │                  │ │
│  │   │                │    │                │                  │ │
│  │   │ - SceneCapture │    │ - Spring System│                  │ │
│  │   │ - scatter_pass │    │ - Collision    │                  │ │
│  │   │ - composite    │    │ - Touch Input  │                  │ │
│  │   │                │    │                │                  │ │
│  │   └────────────────┘    └────────────────┘                  │ │
│  │                                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
                              ↓
              ┌───────────────────────────────┐
              │     CapabilityDetector       │
              │  (GPU 性能检测，降级决策)       │
              └───────────────────────────────┘
                              ↓
              ┌───────────────────────────────┐
              │     LightSourceProvider       │
              │  (光源配置注入)                │
              └───────────────────────────────┘
```

---

## 4. Shader 实现详细设计

### 4.1 Shader 文件结构

```
shaders/
└── liquid_glass/
    ├── common.glsl          # 共享函数库
    ├── scatter.frag         # Pass 2: 散射计算
    └── composite.frag       # Pass 3: 合成输出
```

### 4.2 common.glsl — 共享函数

#### 4.2.1 Poisson Disk 采样方向

```glsl
// 8 方向 Poisson Disk 分布
// 这些方向经过预计算，保证均匀分布和最大间距
const vec2 poissonDisk[8] = vec2[](
  vec2(-0.94201624, -0.39906216),
  vec2(0.94558609, -0.76890725),
  vec2(-0.07518471, 0.99254369),
  vec2(0.47328935, -0.48037314),
  vec2(-0.26458311, -0.41893024),
  vec2(-0.44196361, -0.80659827),
  vec2(0.97460198, 0.23249401),
  vec2(0.44322625, 0.97460198)
);
```

#### 4.2.2 高斯衰减权重

```glsl
// 高斯衰减函数
// dist: 采样点距离中心的像素距离
// sigma: 衰减系数，控制散射范围
float gaussianWeight(float dist, float sigma) {
  float exponent = -0.5 * dist * dist / (sigma * sigma);
  return exp(exponent);
}

// 计算归一化权重（确保所有方向权重和为 1）
float normalizedGaussianWeight(float dist, float sigma) {
  float weight = gaussianWeight(dist, sigma);
  // 预计算归一化因子 (1 / (2 * PI * sigma^2))
  float normalization = 0.15915494309189535 / (sigma * sigma);
  return weight * normalization;
}
```

#### 4.2.3 简化的 Simplex Noise

```glsl
// 用于非实时散射的简化噪声（可选，用于有机散射效果）
float simpleNoise(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 有机噪声混合（用于散射的不规则性）
float organicNoise(vec2 uv, float time) {
  float n1 = simpleNoise(uv * 4.0 + time * 0.1);
  float n2 = simpleNoise(uv * 8.0 - time * 0.15);
  float n3 = simpleNoise(uv * 16.0 + time * 0.2);
  return (n1 + n2 * 0.5 + n3 * 0.25) / 1.75;
}
```

#### 4.2.4 光照计算工具

```glsl
// 归一化向量
vec3 normalizeSafe(vec3 v) {
  float len = length(v);
  return len > 0.0 ? v / len : vec3(0.0);
}

// 计算散射方向系数（基于光线入射角度）
// lightDir: 归一化光照方向
// normal: 表面法线（这里简化为 UV 梯度）
float scatterDirectionFactor(vec2 lightDir, vec2 toPixel) {
  // 背光面散射更强（模拟次表面散射）
  float alignment = dot(normalize(toPixel), lightDir);
  return mix(1.0, max(0.0, alignment), 0.3);
}
```

### 4.3 scatter.frag — 散射 Pass

#### 4.3.1 完整代码结构

```glsl
#version 460 core  // Flutter 3.7+ 使用 GLSL ES 1.0 兼容模式

precision highp float;

// ============== Uniforms ==============

// 时间与分辨率
uniform float uTime;
uniform vec2 uResolution;
uniform float uPixelRatio;

// 散射参数
uniform float uScatterRadius;      // 散射半径（像素）
uniform float uScatterStrength;   // 散射强度 [0.0, 1.0]
uniform int uSampleCount;         // 采样方向数

// 光照参数
uniform vec2 uLightDirection;     // 归一化平行光方向
uniform vec3 uLightColor;         // 光源颜色 RGB
uniform float uLightIntensity;    // 光源强度

// 自发光参数
uniform vec3 uEmissionColor;      // 自发光颜色 RGB
uniform float uEmissionIntensity; // 自发光强度
uniform bool uEmissionEnabled;     // 自发光开关

// 纹理输入
uniform sampler2D uBackgroundTex; // 背景纹理
uniform sampler2D uObjectTex;     // 物体纹理
uniform sampler2D uFeedbackTex;   // 反馈纹理（上一帧散射结果）

// ============== 散射核采样 ==============

// 从背景采样环境色
vec3 sampleBackgroundScatter(vec2 uv, vec2 pixelCoord) {
  vec3 totalColor = vec3(0.0);
  float totalWeight = 0.0;

  float normalizedRadius = uScatterRadius / uPixelRatio;
  float sigma = normalizedRadius * 0.4;  // 调整散射形状

  for (int i = 0; i < uSampleCount; i++) {
    vec2 offset = poissonDisk[i] * normalizedRadius;
    vec2 samplePos = pixelCoord + offset;
    vec2 sampleUV = samplePos / uResolution;

    // 越界检查
    if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 &&
        sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {

      vec3 sampleColor = texture2D(uBackgroundTex, sampleUV).rgb;

      // 高斯衰减
      float dist = length(offset);
      float weight = gaussianWeight(dist, sigma);

      // 光照方向影响（背光面散射更多）
      float dirFactor = scatterDirectionFactor(
        uLightDirection,
        normalize(offset)
      );
      weight *= dirFactor;

      totalColor += sampleColor * weight;
      totalWeight += weight;
    }
  }

  // 防止除零
  if (totalWeight > 0.0) {
    return totalColor / totalWeight;
  }
  return vec3(0.0);
}

// 计算物体散射贡献
vec3 computeObjectScatter(vec2 uv) {
  vec4 objectColor = texture2D(uObjectTex, uv);

  // 物体颜色向外的散射
  vec3 scatterColor = objectColor.rgb;

  // 光照方向影响散射强度
  float dirFactor = scatterDirectionFactor(
    uLightDirection,
    vec2(0.5) - uv  // 简化的从中心向外的方向
  );

  // 自发光贡献
  if (uEmissionEnabled) {
    scatterColor += uEmissionColor * uEmissionIntensity;
  }

  return scatterColor * dirFactor * uScatterStrength;
}

// ============== 主函数 ==============

void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 uv = pixelCoord / uResolution;

  // 1. 环境色采样
  vec3 ambientColor = sampleBackgroundScatter(uv, pixelCoord);

  // 2. 物体散射贡献
  vec3 scatterContrib = computeObjectScatter(uv);

  // 3. 反馈累积
  vec3 feedbackColor = texture2D(uFeedbackTex, uv).rgb;

  // 反馈衰减 + 新散射贡献
  vec3 newFeedback = feedbackColor * 0.95 + scatterContrib * 0.05;

  // 4. 最终散射结果
  // 背景渗透过来的环境色 + 累积的物体散射反馈
  vec3 finalScatter = mix(ambientColor, newFeedback, uScatterStrength);

  // 5. 光源颜色调制
  finalScatter *= uLightColor * uLightIntensity;

  gl_FragColor = vec4(finalScatter, 1.0);
}
```

#### 4.3.2 uniform 对照表

| Uniform | 类型 | 描述 | 默认值 |
|---------|------|------|--------|
| `uTime` | float | 微秒时间戳 | - |
| `uResolution` | vec2 | 渲染分辨率 | - |
| `uPixelRatio` | float | 设备像素比 | 1.0 |
| `uScatterRadius` | float | 散射半径(px) | 50.0 |
| `uScatterStrength` | float | 散射强度 | 0.5 |
| `uSampleCount` | int | 采样方向数 | 8 |
| `uLightDirection` | vec2 | 光照方向 | (0.5, -0.5) |
| `uLightColor` | vec3 | 光源颜色 | (1,1,1) |
| `uLightIntensity` | float | 光源强度 | 1.0 |
| `uEmissionColor` | vec3 | 自发光颜色 | (0.8,0.9,1.0) |
| `uEmissionIntensity` | float | 自发光强度 | 0.0 |
| `uEmissionEnabled` | bool | 自发光开关 | false |

### 4.4 composite.frag — 合成 Pass

#### 4.4.1 完整代码结构

```glsl
#version 460 core

precision highp float;

// ============== Uniforms ==============

// 基础参数
uniform float uTime;
uniform vec2 uResolution;
uniform sampler2D uObjectTex;
uniform sampler2D uScatterTex;

// 光照参数
uniform vec2 uLightDirection;
uniform vec3 uLightColor;
uniform float uLightIntensity;

// 高光参数
uniform float uHighlightPower;   // 高光锐度 (32-128)
uniform float uHighlightIntensity; // 高光强度

// Fresnel 参数
uniform float uFresnelPower;      // 菲涅尔指数 (2-8)
uniform vec3 uFresnelColor;       // 边缘光晕颜色
uniform float uFresnelIntensity; // 边缘光晕强度

// 自发光参数
uniform vec3 uEmissionColor;
uniform float uEmissionIntensity;
uniform bool uEmissionEnabled;

// ============== 高光计算 ==============

// Phong 高光模型
// L: 光照方向 (从表面指向光源)
// N: 表面法线
// V: 视线方向 (从表面指向相机)
// R: 反射方向
float phongSpecular(vec2 lightDir, vec2 normal, vec2 viewDir, float power) {
  // 简化 2D 版本
  // R = 2 * (N·L) * N - L
  vec2 r = 2.0 * dot(normal, lightDir) * normal - lightDir;

  // spec = max(0, R·V)^power
  float spec = max(0.0, dot(r, viewDir));
  return pow(spec, power);
}

// 简化的表面法线（从 alpha 梯度估算）
vec2 estimateNormal(sampler2D tex, vec2 uv, vec2 resolution) {
  float eps = 1.0 / min(resolution.x, resolution.y);

  float left = texture2D(tex, uv - vec2(eps, 0.0)).a;
  float right = texture2D(tex, uv + vec2(eps, 0.0)).a;
  float top = texture2D(tex, uv - vec2(0.0, eps)).a;
  float bottom = texture2D(tex, uv + vec2(0.0, eps)).a;

  // 返回法线方向
  return normalize(vec2(right - left, top - bottom));
}

// ============== Fresnel 边缘光晕 ==============

float fresnel(vec2 normal, vec2 viewDir, float power) {
  // 基本 Fresnel: pow(1 - dot(N,V), power)
  float nDotV = max(0.0, dot(normal, viewDir));
  return pow(1.0 - nDotV, power);
}

// ============== 主函数 ==============

void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 uv = pixelCoord / uResolution;

  // 1. 基础纹理采样
  vec4 objectColor = texture2D(uObjectTex, uv);
  vec4 scatterColor = texture2D(uScatterTex, uv);

  // 2. 合成基础颜色
  // 物体色 + 散射影响
  vec3 baseColor = objectColor.rgb;
  vec3 scatterInfluence = scatterColor.rgb;

  vec3 litColor = baseColor + scatterInfluence;

  // 3. 自发光
  if (uEmissionEnabled) {
    vec3 emission = uEmissionColor * uEmissionIntensity;
    litColor += emission;
  }

  // 4. 光照调制
  litColor *= uLightColor * uLightIntensity;

  // 5. 高光计算
  // 估算物体边缘的法线方向
  vec2 normal = estimateNormal(uObjectTex, uv, uResolution);

  // 视线方向（简化为 (0,0,1) 即垂直于屏幕）
  vec2 viewDir = normalize(vec2(0.5) - uv);

  float spec = phongSpecular(
    normalize(uLightDirection),
    normal,
    viewDir,
    uHighlightPower
  );

  vec3 specular = uLightColor * spec * uHighlightIntensity;
  litColor += specular;

  // 6. Fresnel 边缘光晕
  float fres = fresnel(normal, viewDir, uFresnelPower);
  vec3 fresnelEffect = uFresnelColor * fres * uFresnelIntensity;
  litColor += fresnelEffect;

  // 7. Alpha 通道（从物体纹理传递）
  float alpha = objectColor.a;

  gl_FragColor = vec4(litColor, alpha);
}
```

#### 4.4.2 uniform 对照表

| Uniform | 类型 | 描述 | 默认值 |
|---------|------|------|--------|
| `uTime` | float | 微秒时间戳 | - |
| `uResolution` | vec2 | 渲染分辨率 | - |
| `uObjectTex` | sampler2D | 物体纹理 | - |
| `uScatterTex` | sampler2D | 散射纹理 | - |
| `uLightDirection` | vec2 | 光照方向 | (0.5,-0.5) |
| `uLightColor` | vec3 | 光源颜色 | (1,1,1) |
| `uLightIntensity` | float | 光源强度 | 1.0 |
| `uHighlightPower` | float | 高光锐度 | 64.0 |
| `uHighlightIntensity` | float | 高光强度 | 0.3 |
| `uFresnelPower` | float | 菲涅尔指数 | 4.0 |
| `uFresnelColor` | vec3 | 边缘光晕颜色 | (1,1,1) |
| `uFresnelIntensity` | float | 边缘光晕强度 | 0.2 |
| `uEmissionColor` | vec3 | 自发光颜色 | (0.8,0.9,1.0) |
| `uEmissionIntensity` | float | 自发光强度 | 0.0 |
| `uEmissionEnabled` | bool | 自发光开关 | false |

---

## 5. 渲染管线

### 5.1 渲染流程状态机

```
                    ┌─────────────┐
                    │   IDLE      │ ← 初始化
                    └──────┬──────┘
                           ↓ initialize()
                    ┌─────────────┐
         ┌─────────│  READY       │
         │         └──────┬──────┘
         │                ↓ render()
         │         ┌─────────────┐
         │         │  CAPTURING   │ → Pass 1: SceneCapture
         │         └──────┬──────┘
         │                ↓
         │         ┌─────────────┐
         │         │  SCATTERING  │ → Pass 2: scatter.frag
         │         └──────┬──────┘
         │                ↓
         │         ┌─────────────┐
         │         │ COMPOSITING  │ → Pass 3: composite.frag
         │         └──────┬──────┘
         │                ↓
         │         ┌─────────────┐
         │  no ────┤  SCALING?    │
         │         └──────┬──────┘
         │                │ yes → 降采样输出
         │                ↓
         │         ┌─────────────┐
         └────────→│   DONE      │
                    └─────────────┘
```

### 5.2 SceneCapture — 场景捕获

#### 5.2.1 职责

将 Flutter Widget 树渲染到 GPU 纹理，供后续 shader Pass 使用。

#### 5.2.2 实现

```dart
class SceneCapture {
  /// 捕获场景到纹理
  /// [backgroundBuilder] - 背景层 Widget
  /// [objectBuilder] - 物体层 Widget（按钮等）
  /// [size] - 渲染区域大小
  /// 返回包含 backgroundTex 和 objectTex 的 SceneTextures
  Future<SceneTextures> capture({
    required Widget backgroundBuilder,
    required Widget objectBuilder,
    required Size size,
  });
}

class SceneTextures {
  final ui.Image backgroundTex;
  final ui.Image objectTex;
  final Size size;
}
```

#### 5.2.3 纹理尺寸决策

| RenderQuality | 缩放比 | 1920x1080 下的实际尺寸 |
|---------------|--------|----------------------|
| full | 1.0x | 1920x1080 |
| simple | 0.5x | 960x540 |
| fallback | N/A | 不使用 shader |

### 5.3 PingPongBuffer — 双缓冲管理

#### 5.3.1 职责

管理反馈纹理的 ping-pong 交换，实现时序上的散射累积。

#### 5.3.2 实现

```dart
class PingPongBuffer {
  ui.Image _bufferA;
  ui.Image _bufferB;
  int _currentIndex = 0;

  /// 当前帧的反馈纹理（只读）
  ui.Image get feedbackRead => _currentIndex == 0 ? _bufferA : _bufferB;

  /// 写入目标（当前帧计算结果写入）
  ui.Image get feedbackWrite => _currentIndex == 0 ? _bufferB : _bufferA;

  /// 交换读写缓冲（每帧结束后调用）
  void swap() {
    _currentIndex = 1 - _currentIndex;
  }

  /// 确保缓冲区大小匹配
  Future<void> ensureSize(Size size, RenderQuality quality);

  /// 释放资源
  void dispose();
}
```

#### 5.3.3 反馈衰减系数

```dart
// scatter.frag 中的反馈衰减
const float kFeedbackDecay = 0.95;  // 每帧保留 95%
const float kScatterContribution = 0.05;  // 新散射贡献 5%

// newFeedback = feedbackColor * kFeedbackDecay + scatterContrib * kScatterContribution
```

### 5.4 LiquidGlassRenderer — 主渲染器

#### 5.4.1 职责

- 加载和管理 FragmentProgram
- 协调三个 Pass 的执行顺序
- 管理 uniform 状态
- 处理降级逻辑

#### 5.4.2 核心接口

```dart
class LiquidGlassRenderer {
  /// 初始化渲染器（加载 shader）
  Future<void> initialize();

  /// 设置光源
  void setLightSource(LightSource light);

  /// 设置散射参数
  void setScatterConfig(ScatterConfig config);

  /// 设置自发光
  void setEmissionConfig(EmissionConfig config);

  /// 设置物理状态
  void setPhysicsState(PhysicsState state);

  /// 执行单帧渲染
  void renderFrame(SceneTextures scene);

  /// 获取渲染质量
  RenderQuality get quality;

  /// 释放资源
  void dispose();
}
```

#### 5.4.3 渲染循环

```dart
void renderFrame(SceneTextures scene) {
  // 1. Pass 1: 场景捕获（由调用者提供 scene）

  // 2. Pass 2: 散射计算
  _scatterProgram.render(
    inputs: {
      'uBackgroundTex': scene.backgroundTex,
      'uObjectTex': scene.objectTex,
      'uFeedbackTex': _pingPong.feedbackRead,
    },
    uniforms: _currentUniforms,
    output: _pingPong.feedbackWrite,
  );

  // 3. Ping-pong 交换
  _pingPong.swap();

  // 4. Pass 3: 合成输出
  _compositeProgram.render(
    inputs: {
      'uObjectTex': scene.objectTex,
      'uScatterTex': _pingPong.feedbackRead,
    },
    uniforms: _currentUniforms,
    output: null,  // 直接绘制到屏幕
  );
}
```

---

## 6. 物理模拟系统

### 6.1 物理引擎架构

```
LiquidPhysicsEngine
├── SpringSystem
│   ├── Spring(mass, stiffness, damping)
│   └── DeformationTarget(current, rest, velocity)
├── CollisionSystem
│   ├── BroadPhase (AABB)
│   └── NarrowPhase (shape intersection)
├── TouchInteraction
│   ├── PanGestureRecognizer
│   └── TapGestureRecognizer
└── ForceField
    ├── Gravity (optional)
    └── ExternalForce
```

### 6.2 弹簧物理

#### 6.2.1 物理模型

基于胡克定律和阻尼振动：

```
F_total = F_spring + F_damping + F_external

F_spring = -k * (x - x_rest)  // 弹簧力
F_damping = -b * v             // 阻尼力
F_external = m * a              // 外部力

加速度: a = F_total / m
速度更新: v += a * dt
位置更新: x += v * dt
```

#### 6.2.2 关键参数

```dart
class SpringConfig {
  /// 弹簧刚度系数 (k)
  /// 推荐范围: 100 - 1000
  /// 值越大，回弹越快
  final double stiffness = 500.0;

  /// 阻尼系数 (b)
  /// 推荐范围: 10 - 30
  /// 值越大，振动衰减越快
  final double damping = 15.0;

  /// 等效质量 (m)
  /// 推荐范围: 0.5 - 2.0
  /// 值越大，响应越慢
  final double mass = 1.0;

  /// 最大变形量（像素）
  /// 超过此值时硬限制
  final double maxDeformation = 30.0;
}
```

#### 6.2.3 物理更新循环

```dart
class DeformableObject {
  Offset position;          // 当前中心位置
  Offset deformation;       // 当前变形量（顶点偏移）
  Offset velocity;          // 变形速度
  Size baseSize;            // 原始尺寸
  SpringConfig config;

  void update(double dt) {
    // 1. 计算弹簧力
    Offset springForce = -config.stiffness * deformation;

    // 2. 计算阻尼力
    Offset dampingForce = -config.damping * velocity;

    // 3. 合力
    Offset totalForce = springForce + dampingForce;

    // 4. 加速度 = F / m
    Offset acceleration = totalForce / config.mass;

    // 5. 速度更新
    velocity += acceleration * dt;

    // 6. 位置（变形量）更新
    deformation += velocity * dt;

    // 7. 硬限制最大变形
    deformation = _clampDeformation(deformation);
  }

  /// 应用外部触摸力
  void applyTouchForce(Offset force) {
    velocity += force / config.mass;
  }

  /// 开始回弹到原始状态
  void startRecovery() {
    // velocity 保持，由弹簧力自然回弹
  }
}
```

### 6.3 碰撞系统

#### 6.3.1 AABB 粗检测

```dart
class AABB {
  Offset min;
  Offset max;

  bool intersects(AABB other) {
    return !(max.dx < other.min.dx ||
             min.dx > other.max.dx ||
             max.dy < other.min.dy ||
             min.dy > other.max.dy);
  }
}

class CollisionSystem {
  List<AABB> computeAABB(List<DeformableObject> objects) {
    return objects.map((obj) {
      Offset halfDeform = obj.deformation.abs();
      return AABB(
        min: obj.position - obj.baseSize / 2 - halfDeform,
        max: obj.position + obj.baseSize / 2 + halfDeform,
      );
    }).toList();
  }
}
```

#### 6.3.2 碰撞响应

```dart
void resolveCollision(DeformableObject a, DeformableObject b) {
  // 1. 计算重叠量
  Offset overlap = _computeOverlap(a, b);

  // 2. 计算碰撞法线
  Offset normal = _computeNormal(a, b);

  // 3. 计算分离力（弹簧反作用）
  double separationForce = a.config.stiffness * overlap.distance * 0.5;

  // 4. 应用分离力到变形量
  a.deformation += normal * separationForce * 0.1;
  b.deformation -= normal * separationForce * 0.1;
}
```

### 6.4 触摸交互

#### 6.4.1 手势识别

```dart
class LiquidGlassGestureHandler extends StatefulWidget {
  // ...
  void _handlePanStart(DragStartDetails details) {
    _dragStartPosition = details.localPosition;
    _dragTarget = _findTouchedObject(details.localPosition);

    if (_dragTarget != null) {
      // 记录初始变形状态
      _dragStartDeformation = _dragTarget.deformation;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragTarget == null) return;

    // 计算拖拽偏移
    Offset dragDelta = details.localPosition - _dragStartPosition;

    // 转换到变形空间（基于触摸点相对位置）
    Offset normalizedDelta = _computeDeformationFromDrag(
      dragDelta,
      details.localPosition - _dragTarget.position,
    );

    // 应用拖拽变形
    _dragTarget.deformation = _dragStartDeformation + normalizedDelta;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_dragTarget == null) return;

    // 启动弹簧回弹
    _dragTarget.startRecovery();
    _dragTarget = null;
  }
}
```

#### 6.4.2 按压变形

```dart
void _handleTapDown(TapDownDetails details) {
  final target = _findTouchedObject(details.localPosition);
  if (target == null) return;

  // 快速按压变形（短促的脉冲力）
  Offset pushForce = Offset(0, 5);  // 向下按压
  target.applyTouchForce(pushForce);

  // 快速衰减（不用弹簧，直接回归）
  Future.delayed(Duration(milliseconds: 100), () {
    target.deformation = Offset.zero;
  });
}
```

### 6.5 物理更新时序

```dart
// 60fps 目标，每帧 16.67ms
const double kPhysicsDt = 1.0 / 60.0;

class LiquidPhysicsEngine {
  void update(double dt) {
    // 1. 应用外部力（触摸等）
    _applyExternalForces();

    // 2. 更新每个可变形物体
    for (final obj in _objects) {
      obj.update(dt);
    }

    // 3. 碰撞检测与响应
    _detectAndResolveCollisions();

    // 4. 边界约束（可选，防止物体移出屏幕）
    _applyBoundaryConstraints();
  }
}
```

---

## 7. Widget API 设计

### 7.1 核心配置类

#### 7.1.1 LiquidGlassConfig

```dart
class LiquidGlassConfig {
  /// 散射半径（像素）
  /// 默认: 50.0
  /// 开发者可配置范围: 10.0 - 200.0
  final double scatterRadius;

  /// 散射强度 [0.0 - 1.0]
  /// 默认: 0.5
  final double scatterStrength;

  /// 散射采样数
  /// full 模式: 8
  /// simple 模式: 4
  final int sampleCount;

  const LiquidGlassConfig({
    this.scatterRadius = 50.0,
    this.scatterStrength = 0.5,
  });
}
```

#### 7.1.2 LightSource

```dart
class LightSource {
  /// 光源类型
  final LightType type;

  /// 平行光方向（归一化），仅 type == LightType.parallel 时使用
  final Offset direction;

  /// 点光源位置，仅 type == LightType.point 时使用
  final Offset position;

  /// 光源颜色
  final Color color;

  /// 光源强度
  final double intensity;

  const LightSource({
    this.type = LightType.parallel,
    this.direction = const Offset(0.5, -0.5),
    this.position = Offset.zero,
    this.color = Colors.white,
    this.intensity = 1.0,
  });

  /// 创建默认平行光（从左上方）
  factory LightSource.defaultParallel() => const LightSource(
    type: LightType.parallel,
    direction: Offset(-0.707, -0.707),  // 45度角
    color: Colors.white,
    intensity: 1.0,
  );
}

enum LightType {
  parallel,  // 平行光（方向光）
  point,     // 点光源
}
```

#### 7.1.3 EmissionConfig

```dart
class EmissionConfig {
  /// 是否启用自发光
  final bool enabled;

  /// 自发光颜色
  final Color color;

  /// 自发光强度
  final double intensity;

  /// 自发光半径（像素），控制发光扩散范围
  final double radius;

  const EmissionConfig({
    this.enabled = false,
    this.color = const Color(0xFFE8F0FF),
    this.intensity = 0.3,
    this.radius = 20.0,
  });
}
```

#### 7.1.4 LiquidPhysicsConfig

```dart
class LiquidPhysicsConfig {
  /// 是否启用物理模拟
  final bool enabled;

  /// 弹簧刚度
  final double stiffness;

  /// 阻尼系数
  final double damping;

  /// 等效质量
  final double mass;

  /// 最大变形量
  final double maxDeformation;

  /// 是否启用碰撞
  final bool collisionEnabled;

  const LiquidPhysicsConfig({
    this.enabled = true,
    this.stiffness = 500.0,
    this.damping = 15.0,
    this.mass = 1.0,
    this.maxDeformation = 30.0,
    this.collisionEnabled = true,
  });
}
```

### 7.2 LiquidGlassWidget — 主组件

```dart
class LiquidGlassWidget extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 液态玻璃配置
  final LiquidGlassConfig? config;

  /// 光源配置
  final LightSource? lightSource;

  /// 自发光配置
  final EmissionConfig? emission;

  /// 物理模拟配置
  final LiquidPhysicsConfig? physics;

  /// 是否启用物理模拟
  final bool physicsEnabled;

  /// 外部施加的力（用于与其他系统集成）
  final Offset? externalForce;

  /// 边框半径
  final BorderRadius borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  const LiquidGlassWidget({
    super.key,
    required this.child,
    this.config,
    this.lightSource,
    this.emission,
    this.physics,
    this.physicsEnabled = true,
    this.externalForce,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
  });
}
```

### 7.3 LiquidButton — 按钮特化

```dart
class LiquidButton extends StatefulWidget {
  /// 按钮文本
  final String text;

  /// 图标（可选）
  final IconData? icon;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 禁用状态
  final bool enabled;

  /// 自发光配置（默认启用柔和蓝白渐变）
  final EmissionConfig emission;

  /// 物理模拟配置
  final LiquidPhysicsConfig physics;

  /// 按钮尺寸
  final Size? size;

  /// 样式
  final LiquidButtonStyle? style;

  const LiquidButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.emission = const EmissionConfig(
      enabled: true,
      color: Color(0xFFE8F0FF),
      intensity: 0.3,
    ),
    this.physics = const LiquidPhysicsConfig(),
    this.size,
    this.style,
  });
}

/// 按钮样式
class LiquidButtonStyle {
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const LiquidButtonStyle({
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w600,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });
}
```

### 7.4 使用示例

#### 7.4.1 基础用法

```dart
// 默认配置
LiquidGlassWidget(
  child: Text('Hello Liquid Glass'),
)

// 自定义散射
LiquidGlassWidget(
  config: const LiquidGlassConfig(
    scatterRadius: 80.0,
    scatterStrength: 0.7,
  ),
  child: Text('Strong Scattering'),
)

// 带发光
LiquidGlassWidget(
  emission: const EmissionConfig(
    enabled: true,
    color: Color(0xFFFF6B6B),
    intensity: 0.5,
  ),
  child: Text('Glowing Text'),
)
```

#### 7.4.2 按钮

```dart
LiquidButton(
  text: 'Click Me',
  icon: Icons.touch_app,
  onPressed: () => print('Pressed!'),
  emission: const EmissionConfig(
    enabled: true,
    color: Color(0xFF4ECDC4),
    intensity: 0.4,
  ),
)

// 禁用物理的静态按钮
LiquidButton(
  text: 'Static Button',
  physics: const LiquidPhysicsConfig(enabled: false),
  onPressed: () {},
)
```

#### 7.4.3 多光源

```dart
// 通过 Provider 注入全局光源
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LightSourceProvider(
      lightSource: LightSource.defaultParallel().copyWith(
        color: const Color(0xFFFFE4B5),
        intensity: 0.8,
      ),
      child: LiquidGlassWidget(
        // ...
      ),
    );
  }
}
```

### 7.5 LightSourceProvider — 光源注入

```dart
class LightSourceProvider extends InheritedWidget {
  /// 全局默认光源
  final LightSource defaultLight;

  /// 额外的点光源列表
  final List<LightSource> additionalLights;

  const LightSourceProvider({
    super.key,
    required this.defaultLight,
    this.additionalLights = const [],
    required super.child,
  });

  /// 获取当前激活的光源
  static List<LightSource> of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<LightSourceProvider>();
    if (provider != null) {
      return [provider.defaultLight, ...provider.additionalLights];
    }
    return [LightSource.defaultParallel()];
  }
}
```

---

## 8. 降级策略

### 8.1 降级决策树

```
┌─────────────────────────────────────────────────────────────────┐
│                      CapabilityDetector                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. FragmentProgram.supported?                                   │
│     ├── No → .fallback                                          │
│     └── Yes →                                                    │
│           ↓                                                      │
│  2. GPU Benchmark (5 frames avg)                                 │
│     ├── > 16.67ms/frame (≤ 60fps) → .simple                      │
│     ├── > 8.33ms/frame (≤ 120fps) → .full                       │
│     └── ≤ 8.33ms/frame → .full                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 GPU 基准测试

```dart
class CapabilityDetector {
  /// 执行 GPU 基准测试
  /// 返回平均帧时间（毫秒）
  Future<double> benchmark() async {
    final List<double> frameTimes = [];
    const int warmupFrames = 2;
    const int measureFrames = 5;

    // 预热
    for (int i = 0; i < warmupFrames; i++) {
      await _renderTestFrame();
    }

    // 测量
    for (int i = 0; i < measureFrames; i++) {
      final stopwatch = Stopwatch()..start();
      await _renderTestFrame();
      stopwatch.stop();
      frameTimes.add(stopwatch.elapsedMicroseconds / 1000.0);
    }

    // 返回平均值
    return frameTimes.reduce((a, b) => a + b) / frameTimes.length;
  }

  /// 渲染测试帧（简单散射 shader）
  Future<void> _renderTestFrame() async {
    // 实现...
  }
}

enum RenderQuality {
  /// 完整模式
  /// - 原生分辨率
  /// - 8 方向 Poisson 采样
  /// - 完整反馈累积
  /// - 物理模拟开启
  full,

  /// 简化模式
  /// - 0.5x 分辨率（双线性放大）
  /// - 4 方向采样
  /// - 无反馈累积（单帧散射）
  /// - 简化物理（降低模拟频率）
  simple,

  /// 回退模式
  /// - 使用现有 GlassContainer
  /// - 纯色 + BackdropFilter 模拟
  /// - 无物理模拟
  fallback,
}
```

### 8.3 各模式配置

| 配置项 | full | simple | fallback |
|--------|------|--------|----------|
| 渲染分辨率 | 1.0x | 0.5x | N/A |
| 散射采样数 | 8 | 4 | N/A |
| 反馈累积 | 0.95 衰减 | 无 | N/A |
| 高光 | Phong | 简化 | 无 |
| Fresnel | 完整 | 无 | 无 |
| 物理模拟 | 60fps | 30fps | 禁用 |
| 触摸响应 | 完整 | 简化 | 无 |
| 碰撞检测 | AABB + 变形 | 仅 AABB | 无 |

### 8.4 自动降级

```dart
class LiquidGlassRenderer {
  RenderQuality _quality = RenderQuality.full;
  double _lastBenchmarkTime = 0;

  /// 每 30 秒重新评估性能
  void _periodicQualityCheck() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBenchmarkTime > 30000) {
      _lastBenchmarkTime = now;
      _quality = _detector.detect();
    }
  }

  /// 用户可手动设置质量模式（覆盖自动检测）
  void setQualityMode(RenderQuality quality) {
    _quality = quality;
  }
}
```

### 8.5 Fallback 实现

```dart
class FallbackGlassContainer extends StatelessWidget {
  final Widget child;
  final LiquidGlassConfig? config;
  final EmissionConfig? emission;

  const FallbackGlassContainer({
    super.key,
    required this.child,
    this.config,
    this.emission,
  });

  @override
  Widget build(BuildContext context) {
    // 使用现有的 GlassContainer
    return GlassContainer(
      blur: 20.0,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }
}

// Fallback 时的发光效果
class FallbackEmission extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    if (emission?.enabled != true) return child;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: emission!.color.withOpacity(emission!.intensity * 0.5),
            blurRadius: emission!.radius,
            spreadRadius: emission!.radius * 0.5,
          ),
        ],
      ),
      child: child,
    );
  }
}
```

---

## 9. 实施计划与里程碑

### 9.1 阶段划分

| 阶段 | 内容 | 工期 |
|------|------|------|
| A | Shader 基础设施 | 2-3 天 |
| B | 渲染管线核心 | 3-4 天 |
| C | 物理模拟系统 | 2-3 天 |
| D | Widget 封装与降级 | 2 天 |
| E | 集成测试与优化 | 2-3 天 |
| **总计** | | **11-15 天** |

### 9.2 详细任务清单

#### 阶段 A：Shader 基础设施

| # | 任务 | 依赖 | 工时 | 交付物 |
|---|------|------|------|--------|
| A.1 | 创建 shaders/ 目录结构 | - | 0.5h | 目录创建 |
| A.2 | 编写 common.glsl | A.1 | 2h | 散射核、工具函数 |
| A.3 | 编写 scatter.frag | A.2 | 4h | 散射计算 shader |
| A.4 | 编写 composite.frag | A.2 | 3h | 合成输出 shader |
| A.5 | pubspec.yaml 添加 shader 配置 | A.1 | 0.5h | 构建配置更新 |
| A.6 | **阶段 A 验证**：Shader 加载测试 | A.3, A.4, A.5 | 2h | validate_scatter shader |
| **小计** | | | **12h** | |

#### 阶段 B：渲染管线核心

| # | 任务 | 依赖 | 工时 | 交付物 |
|---|------|------|------|--------|
| B.1 | PingPongBuffer 双缓冲实现 | A.6 | 2h | buffer_manager.dart |
| B.2 | SceneCapture 场景捕获 | A.5 | 3h | scene_capture.dart |
| B.3 | FragmentProgram 封装 | B.1, B.2 | 4h | shader_program.dart |
| B.4 | LiquidGlassRenderer 主渲染器 | B.3 | 6h | renderer.dart |
| B.5 | **阶段 B 验证**：散射效果展示 | B.4 | 3h | Demo 页面 |
| **小计** | | | **18h** | |

#### 阶段 C：物理模拟系统

| # | 任务 | 依赖 | 工时 | 交付物 |
|---|------|------|------|--------|
| C.1 | LiquidPhysicsEngine 核心 | B.5 | 4h | physics_engine.dart |
| C.2 | SpringSystem 弹簧系统 | C.1 | 3h | spring_system.dart |
| C.3 | CollisionSystem 碰撞系统 | C.1 | 3h | collision_system.dart |
| C.4 | TouchInteraction 触摸处理 | C.2 | 2h | gesture_handler.dart |
| C.5 | **阶段 C 验证**：物理变形 Demo | C.3, C.4 | 3h | physics_demo.dart |
| **小计** | | | **15h** | |

#### 阶段 D：Widget 封装与降级

| # | 任务 | 依赖 | 工时 | 交付物 |
|---|------|------|------|--------|
| D.1 | CapabilityDetector GPU 检测 | B.5 | 2h | detector.dart |
| D.2 | RenderQuality 降级决策 | D.1 | 1h | quality_manager.dart |
| D.3 | LiquidGlassConfig 配置类 | - | 1h | config.dart |
| D.4 | LightSourceProvider 光源注入 | D.3 | 2h | provider.dart |
| D.5 | LiquidGlassWidget 主组件 | D.2, D.3, D.4 | 4h | liquid_glass_widget.dart |
| D.6 | LiquidButton 特化按钮 | D.5 | 2h | liquid_button.dart |
| D.7 | FallbackGlassContainer | D.2 | 1h | fallback.dart |
| D.8 | **阶段 D 验证**：完整按钮 Demo | D.5, D.6 | 2h | button_demo.dart |
| **小计** | | | **15h** | |

#### 阶段 E：集成测试与优化

| # | 任务 | 依赖 | 工时 | 交付物 |
|---|------|------|------|--------|
| E.1 | 多按钮场景测试 | D.8 | 3h | multi_button_test.dart |
| E.2 | 性能优化：分辨率自适应 | E.1 | 3h | resolution_scaler.dart |
| E.3 | 性能优化：采样数动态调整 | E.2 | 2h | adaptive_sampling.dart |
| E.4 | 多平台兼容性测试 | E.3 | 3h | platform_test.dart |
| E.5 | Bug 修复与调优 | E.4 | 4h | - |
| E.6 | 文档编写 | E.5 | 2h | API 文档 |
| E.7 | **阶段 E 验收**：完整 Demo | E.6 | 2h | final_demo.dart |
| **小计** | | | **19h** | |

### 9.3 里程碑

```
Week 1 (Mon-Fri)
├── Day 1-2: 阶段 A (Shader 基础设施)
├── Day 3-4: 阶段 B (渲染管线核心)
└── Day 5: 阶段 B 验证 + 阶段 C 启动

Week 2 (Mon-Wed)
├── Day 6-7: 阶段 C (物理模拟系统)
├── Day 8: 阶段 D (Widget 封装与降级)
└── Day 9-10: 阶段 E (集成测试)

Week 3 (Mon-Wed)
├── Day 11-12: 性能优化与调优
└── Day 13: 最终验收
```

### 9.4 风险与缓解

| 风险 | 概率 | 影响 | 缓解策略 |
|------|------|------|----------|
| FragmentProgram API 不稳定 | 中 | 高 | 验证阶段优先测试，保留 fallback |
| Shader 编译错误 | 中 | 中 | GLSL ES 1.0 兼容代码，避免高级特性 |
| 性能不达标 | 高 | 高 | 简化模式和降采样预研，early profiling |
| 物理模拟性能问题 | 中 | 中 | 降低模拟频率，简化碰撞检测 |
| Web 平台兼容性问题 | 中 | 中 | WebGL 1.0 回退，FragmentProgram 检测 |

---

## 10. 文件结构

### 10.1 完整文件清单

```
lib/
├── shaders/
│   └── liquid_glass/
│       ├── common.glsl           # 共享函数
│       ├── scatter.frag          # 散射 Pass
│       └── composite.frag        # 合成 Pass
│
├── rendering/
│   ├── liquid_glass_renderer.dart  # 主渲染器
│   ├── scene_capture.dart          # 场景捕获
│   ├── ping_pong_buffer.dart      # 双缓冲管理
│   ├── fragment_program.dart       # Shader 程序封装
│   └── physics/
│       ├── liquid_physics_engine.dart  # 物理引擎核心
│       ├── spring_system.dart          # 弹簧系统
│       ├── collision_system.dart        # 碰撞系统
│       └── gesture_handler.dart         # 触摸手势处理
│
├── providers/
│   ├── liquid_glass_context.dart   # 全局渲染上下文
│   └── light_source_provider.dart  # 光源注入
│
├── config/
│   ├── liquid_glass_config.dart     # 液态玻璃配置
│   ├── light_source.dart            # 光源配置
│   ├── emission_config.dart         # 发光配置
│   └── physics_config.dart          # 物理配置
│
├── widgets/
│   ├── liquid_glass_widget.dart      # 主组件
│   ├── liquid_button.dart           # 按钮组件
│   └── liquid_container.dart        # 容器组件
│
└── services/
    └── capability_detector.dart      # GPU 能力检测

pubspec.yaml                           # 添加 shader 配置
```

### 10.2 目录结构图

```
E:\git\ToDoTimeSquare\
├── lib\
│   ├── shaders\
│   │   └── liquid_glass\
│   │       ├── common.glsl
│   │       ├── scatter.frag
│   │       └── composite.frag
│   │
│   ├── rendering\
│   │   ├── liquid_glass_renderer.dart
│   │   ├── scene_capture.dart
│   │   ├── ping_pong_buffer.dart
│   │   ├── fragment_program.dart
│   │   └── physics\
│   │       ├── liquid_physics_engine.dart
│   │       ├── spring_system.dart
│   │       ├── collision_system.dart
│   │       └── gesture_handler.dart
│   │
│   ├── providers\
│   │   ├── liquid_glass_context.dart
│   │   └── light_source_provider.dart
│   │
│   ├── config\
│   │   ├── liquid_glass_config.dart
│   │   ├── light_source.dart
│   │   ├── emission_config.dart
│   │   └── physics_config.dart
│   │
│   ├── widgets\
│   │   ├── liquid_glass_widget.dart
│   │   ├── liquid_button.dart
│   │   └── liquid_container.dart
│   │
│   └── services\
│       └── capability_detector.dart
│
├── shaders\                          # 项目根目录的 shaders
│   └── liquid_glass\
│       ├── common.glsl
│       ├── scatter.frag
│       └── composite.frag
│
└── docs\
    └── liquid-glass-renderer-design.md  # 本文档
```

---

## 11. 附录：Shader 代码参考

### 11.1 scatter.frag 完整代码

```glsl
#version 460 core

precision highp float;

// ============== Uniforms ==============
uniform float uTime;
uniform vec2 uResolution;
uniform float uPixelRatio;
uniform float uScatterRadius;
uniform float uScatterStrength;
uniform int uSampleCount;
uniform vec2 uLightDirection;
uniform vec3 uLightColor;
uniform float uLightIntensity;
uniform vec3 uEmissionColor;
uniform float uEmissionIntensity;
uniform bool uEmissionEnabled;
uniform sampler2D uBackgroundTex;
uniform sampler2D uObjectTex;
uniform sampler2D uFeedbackTex;

// ============== Poisson Disk ==============
const vec2 poissonDisk[8] = vec2[](
  vec2(-0.94201624, -0.39906216),
  vec2(0.94558609, -0.76890725),
  vec2(-0.07518471, 0.99254369),
  vec2(0.47328935, -0.48037314),
  vec2(-0.26458311, -0.41893024),
  vec2(-0.44196361, -0.80659827),
  vec2(0.97460198, 0.23249401),
  vec2(0.44322625, 0.97460198)
);

// ============== Utility Functions ==============
float gaussianWeight(float dist, float sigma) {
  float exponent = -0.5 * dist * dist / (sigma * sigma);
  return exp(exponent);
}

float scatterDirectionFactor(vec2 lightDir, vec2 toPixel) {
  float alignment = dot(normalize(toPixel), lightDir);
  return mix(1.0, max(0.0, alignment), 0.3);
}

// ============== Main ==============
void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 uv = pixelCoord / uResolution;

  // 1. Sample background with Poisson disk
  vec3 totalColor = vec3(0.0);
  float totalWeight = 0.0;
  float normalizedRadius = uScatterRadius / uPixelRatio;
  float sigma = normalizedRadius * 0.4;

  for (int i = 0; i < 8; i++) {
    if (i >= uSampleCount) break;

    vec2 offset = poissonDisk[i] * normalizedRadius;
    vec2 samplePos = pixelCoord + offset;
    vec2 sampleUV = samplePos / uResolution;

    if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 &&
        sampleUV.y >= 0.0 && sampleUV.y <= 1.0) {

      vec3 sampleColor = texture2D(uBackgroundTex, sampleUV).rgb;
      float dist = length(offset);
      float weight = gaussianWeight(dist, sigma);
      float dirFactor = scatterDirectionFactor(uLightDirection, normalize(offset));
      weight *= dirFactor;

      totalColor += sampleColor * weight;
      totalWeight += weight;
    }
  }

  vec3 ambientColor = totalWeight > 0.0 ? totalColor / totalWeight : vec3(0.0);

  // 2. Object scatter contribution
  vec4 objectColor = texture2D(uObjectTex, uv);
  vec3 scatterContrib = objectColor.rgb;
  float dirFactor = scatterDirectionFactor(uLightDirection, vec2(0.5) - uv);

  if (uEmissionEnabled) {
    scatterContrib += uEmissionColor * uEmissionIntensity;
  }
  scatterContrib *= dirFactor * uScatterStrength;

  // 3. Feedback accumulation
  vec3 feedbackColor = texture2D(uFeedbackTex, uv).rgb;
  vec3 newFeedback = feedbackColor * 0.95 + scatterContrib * 0.05;

  // 4. Final scatter
  vec3 finalScatter = mix(ambientColor, newFeedback, uScatterStrength);
  finalScatter *= uLightColor * uLightIntensity;

  gl_FragColor = vec4(finalScatter, 1.0);
}
```

### 11.2 composite.frag 完整代码

```glsl
#version 460 core

precision highp float;

// ============== Uniforms ==============
uniform float uTime;
uniform vec2 uResolution;
uniform sampler2D uObjectTex;
uniform sampler2D uScatterTex;
uniform vec2 uLightDirection;
uniform vec3 uLightColor;
uniform float uLightIntensity;
uniform float uHighlightPower;
uniform float uHighlightIntensity;
uniform float uFresnelPower;
uniform vec3 uFresnelColor;
uniform float uFresnelIntensity;
uniform vec3 uEmissionColor;
uniform float uEmissionIntensity;
uniform bool uEmissionEnabled;

// ============== Phong Specular ==============
float phongSpecular(vec2 lightDir, vec2 normal, vec2 viewDir, float power) {
  vec2 r = 2.0 * dot(normal, lightDir) * normal - lightDir;
  float spec = max(0.0, dot(r, viewDir));
  return pow(spec, power);
}

// ============== Normal Estimation ==============
vec2 estimateNormal(sampler2D tex, vec2 uv, vec2 resolution) {
  float eps = 1.0 / min(resolution.x, resolution.y);
  float left = texture2D(tex, uv - vec2(eps, 0.0)).a;
  float right = texture2D(tex, uv + vec2(eps, 0.0)).a;
  float top = texture2D(tex, uv - vec2(0.0, eps)).a;
  float bottom = texture2D(tex, uv + vec2(0.0, eps)).a;
  return normalize(vec2(right - left, top - bottom));
}

// ============== Fresnel ==============
float fresnel(vec2 normal, vec2 viewDir, float power) {
  float nDotV = max(0.0, dot(normal, viewDir));
  return pow(1.0 - nDotV, power);
}

// ============== Main ==============
void main() {
  vec2 pixelCoord = gl_FragCoord.xy;
  vec2 uv = pixelCoord / uResolution;

  // 1. Base color
  vec4 objectColor = texture2D(uObjectTex, uv);
  vec4 scatterColor = texture2D(uScatterTex, uv);

  vec3 baseColor = objectColor.rgb + scatterColor.rgb;

  // 2. Emission
  if (uEmissionEnabled) {
    baseColor += uEmissionColor * uEmissionIntensity;
  }

  // 3. Light modulation
  baseColor *= uLightColor * uLightIntensity;

  // 4. Specular
  vec2 normal = estimateNormal(uObjectTex, uv, uResolution);
  vec2 viewDir = normalize(vec2(0.5) - uv);

  float spec = phongSpecular(
    normalize(uLightDirection),
    normal,
    viewDir,
    uHighlightPower
  );

  vec3 specular = uLightColor * spec * uHighlightIntensity;
  baseColor += specular;

  // 5. Fresnel
  float fres = fresnel(normal, viewDir, uFresnelPower);
  vec3 fresnelEffect = uFresnelColor * fres * uFresnelIntensity;
  baseColor += fresnelEffect;

  // 6. Output
  gl_FragColor = vec4(baseColor, objectColor.a);
}
```

---

## 修改历史

| 版本 | 日期 | 修改内容 |
|------|------|----------|
| v1.0.0 | 2026-04-13 | 初始版本 |

---

*本文档为 Liquid Glass 渲染引擎的完整技术设计规范，实现前请仔细阅读各章节细节。*
