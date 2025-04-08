# suchat_lite

SuChat，使用 Flutter 开发、以调用云平台在线大模型 API 驱动的、简洁版 AI 聊天应用，支持简单的自定义角色。

SuChat is a concise AI chat application developed using Flutter, powered by calling cloud platform-based large model APIs online. It supports simple custom characters for role-playing.。

大模型 API 调用**只保留其 HTTP API 兼容 openAI API 结构的**云平台和模型。

具体如下(2025-04-08)：

- 对话模型：
  - [阿里](https://help.aliyun.com/zh/model-studio/developer-reference/compatibility-of-openai-with-dashscope)
  - [百度](https://cloud.baidu.com/doc/WENXINWORKSHOP/s/Fm2vrveyu)
  - [腾讯](https://console.cloud.tencent.com/hunyuan/start)
  - [智谱](https://open.bigmodel.cn/dev/api/normal-model/glm-4)
  - [深度求索(DeepSeek)](https://api-docs.deepseek.com/zh-cn/)
  - [火山引擎(火山方舟)](https://www.volcengine.com/docs/82379/1330310)
  - [零一万物](https://platform.lingyiwanwu.com/docs/api-reference)
  - [无问芯穹](https://docs.infini-ai.com/gen-studio/api/maas.html#/operations/chatCompletions)
  - [硅基流动](https://docs.siliconflow.cn/cn/api-reference/chat-completions/chat-completions)
- 图片生成：
  - 阿里云: [图像生成-通义万相 文生图 V2 版](https://help.aliyun.com/zh/model-studio/developer-reference/text-to-image-v2-api-reference)、[文生图 FLUX](https://help.aliyun.com/zh/model-studio/developer-reference/flux/)
  - 智谱 AI: [CogView](https://open.bigmodel.cn/dev/api/image-model/cogview)
  - 硅基流动: [创建图片生成请求](https://docs.siliconflow.cn/cn/api-reference/images/images-generations)
- 视频生成：
  - 阿里云: [视频生成-通义万相](https://help.aliyun.com/zh/model-studio/developer-reference/video-generation-wanx/)
  - 智谱 AI: [CogVideoX](https://open.bigmodel.cn/dev/api/videomodel/cogvideox)
  - 硅基流动: [创建视频生成请求](https://docs.siliconflow.cn/cn/api-reference/videos/videos_submit)

目前只调试了 Android 手机部分。

---

如果对 [硅基流动平台](https://siliconflow.cn/zh-cn/models) 感兴趣，还能用下我的邀请码注册，那就更好了，谢谢：

[https://cloud.siliconflow.cn/i/tRIcST68](https://cloud.siliconflow.cn/i/tRIcST68)

# 更新说明

查看 [CHANGELOG](CHANGELOG.md)，**新版本改动的模块和功能信息也在该 ChangeLog 中简述**。

# 功能介绍

## 补充说明

![配置和其他工具](./_doc/screenshots/导入配置等.jpg)

默认助手、角色扮演的对话可以单独导出，也可以在设置页面和其他内容一起全量备份、覆写恢复。

打包好的 apk 是直接使用我个人密钥的一些免费的大模型，都是比较基础的。可以自行导入平台模型和密钥使用自己的资源。

- “导入”入口在“工具”模块右上角，点击“设置”图标，进入配置页面。
- 如果想使用本应用支持的平台中更加强劲的模型，可自行去各个平台充值、获取密钥，再导入密钥和模型 json 文件
  - **密钥只缓存在本地，事实上，除了调用 API 和加载图片、视频，都没有联网操作**
  - 想用哪个平台、哪个模型，全都自己导入
- 平台密钥和模型规格的**固定 json 结构**见下方

---

**_注意，平台密钥和平台模型规格要同时导入，否则无法正常使用。_**

#### 平台密钥 json 结构

导入平台的密钥的 key 一定要和这个文件中 key 一样，不然匹配不上：

```json
{
  "USER_ALIYUN_API_KEY": "sk-xxx",
  "USER_BAIDU_API_KEY_V2": "xxx",
  "USER_TENCENT_API_KEY": "xxx",

  "USER_DEEPSEEK_API_KEY": "sk-xxx",
  "USER_LINGYIWANWU_API_KEY": "xxx",
  "USER_ZHIPU_API_KEY": "xxx",

  "USER_SILICONCLOUD_API_KEY": "sk-xxx",
  "USER_INFINI_GEN_STUDIO_API_KEY": "sk-xxx",

  // 火山方舟的预置推理接入点
  "USER_VOLCENGINE_API_KEY": "xxx",
  // 自定义推理接入点(比较简单的联网应用)
  "USER_VOLCESBOT_API_KEY": "xxx",

  // 讯飞, 语音转写需要
  "USER_XFYUN_APP_ID": "xxx",
  "USER_XFYUN_API_KEY": "xxx",
  "USER_XFYUN_API_SECRET": "xxx"
}
```

- 密钥可以不是所有平台都填，但填写的部分 key 一定要完全一致，否则识别不到就算有导入模型也用不了
- 讯飞那几个是语音转写需要。

#### 大模型规格 json 结构

简化必要栏位只需要**平台、模型名、模型类型**即可。

```json
[
  {
    "platform": "<*代码中自定义的平台代号，枚举值>",
    "model": "<*指定平台中使用的模型代号，必须与API文档中一致，会用于构建http请求>",
    "modelType": "<*代码中自定义的模型类型代号，枚举值>"
  },
  {
    "platform": "aliyun",
    "model": "deepseek-r1",
    "modelType": "reasoner"
  },
  {
    "platform": "aliyun",
    "model": "deepseek-v3",
    "modelType": "cc"
  }
  // ……
]
```

- platform 枚举值:

```ts
enum ApiPlatform {
  aliyun, // 阿里云百炼
  baidu, // 百度千帆
  tencent, // 腾讯混元

  deepseek, // 深度求索
  lingyiwanwu, // 零一万物
  zhipu, // 智谱 AI

  siliconCloud, // 硅基流动
  infini, // 无问芯穹的 genStudio

  // 2025-03-24 火山引擎默认调用和关联应用(比如配置了联网搜索)使用的url不一样
  // 避免出现冲突，分成两个且互不包含
  volcengine,
  volcesBot,
}
```

- modelType 枚举值:

```ts
enum LLModelType {
  cc, // 文本对话
  reasoner, // 深度思考
  vision, // 图片解读
  tti, // 文本生图
  iti, // 图片生图
  image, // 图片生成(文生图生通用)
  ttv, // 文生视频
  itv, // 图生视频
  video, // 视频生成(文生图生通用)
}
```

后续我会放一些整理好的各个平台我常用的大模型规格 json 文件在项目的 **[\_cus_model_jsons](./_cus_model_jsons)** 文件夹中，可以参考使用。

# 其他说明

## 开发环境

在一个 Windows 7 中使用 Visual Box 7 安装的 Ubuntu20.04 LTS 虚拟机中使用 VSCode 进行开发。

2025-04-08 使用最新 flutter 版本：

```sh
$ flutter --version
Flutter 3.29.2 • channel stable • https://github.com/flutter/flutter.git
Framework • revision c236373904 (4 周前) • 2025-03-13 16:17:06 -0400
Engine • revision 18b71d647a
Tools • Dart 3.7.2 • DevTools 2.42.3
```
