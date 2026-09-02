# AI与职业岗位

---

## 归档（2026-08-30）

### 核心视角

如果把「AI」不只看成一个模型，而是看成一个**产业系统**，可以从上游的能源、芯片，一直延伸到下游的具体行业应用。

```text
能源 / 土地 / 数据中心
        ↓
芯片 / 服务器 / 网络
        ↓
云计算 / AI基础设施
        ↓
基础模型
        ↓
模型工具链 / Agent基础设施
        ↓
AI应用
        ↓
各行业
        ↓
最终用户
```

### 职业机会判断

若问的是「AI 会创造哪些产业、哪些职业机会」，应特别关注中间这几层：

> **AI Infrastructure → AI Runtime → Agent → AI Software → AI Industry**

- 最上游：极高资本和技术门槛
- 最下游：需要深厚行业资源
- **模型之上的软件基础设施和 Agent 层**：传统软件工程师比较容易进入的区域

---

### 一、最上游：AI 的物理基础

这是 AI 最底层的产业。

**1. 能源**

- 发电
- 电网
- 储能
- 核电
- 可再生能源

AI 数据中心越来越像「电力密集型工业」。

**2. 数据中心**

- 数据中心建设
- 机房
- 制冷
- 液冷
- UPS
- 机架
- 电力设备

**3. 半导体**

- GPU
- TPU / NPU / ASIC
- CPU
- HBM
- DRAM
- NAND
- 芯片制造
- 先进封装
- 半导体设备
- 半导体材料

半导体产业链：

```text
矿产 / 材料
 ↓
晶圆
 ↓
芯片设计
 ↓
芯片制造
 ↓
先进封装
 ↓
GPU / AI芯片
 ↓
服务器
```

---

### 二、中上游：计算基础设施

有了芯片之后，还需要把大量芯片组织起来。

- AI Server
- GPU Cluster
- 高速网络
- InfiniBand / Ethernet
- 存储
- 分布式计算
- 云计算
- GPU Cloud
- MLOps
- 模型训练平台
- 推理平台

这一层实际上就是：

> **把「芯片」变成「可使用的计算能力」。**

---

### 三、中游：基础模型

这是大家通常理解的「AI」。

包括：

- LLM
- 多模态模型
- 图像模型
- 视频模型
- 音频模型
- Embedding Model
- Speech Model
- Reasoning Model
- World Model
- Robotics Model

产业链：

```text
数据
 ↓
训练
 ↓
基础模型
 ↓
Post-training
 ↓
Reasoning
 ↓
Inference
```

这里产生的是「智能能力」。

---

### 四、模型之上的工具链

这一层非常重要，而且可能是未来 AI 软件产业的核心之一。

包括：

- AI SDK
- Agent Framework
- MCP
- Tool Calling
- RAG
- Vector Database
- Memory
- Knowledge Base
- Evaluation
- Observability
- Guardrails
- AI Gateway
- Model Router
- Prompt Management
- Context Management
- Agent Runtime
- Agent Harness

可以理解成：

> **把一个「模型」变成一个能够工作的「AI 系统」。**

Skill / Harness / Task Planner / Task Executor / Agent，基本都属于这一层。

---

### 五、AI 应用层

这是距离普通用户最近的一层。

**办公**

- AI Office
- AI 搜索
- AI 写作
- AI PPT
- AI 会议
- AI 邮件

**编程**

- AI IDE
- Coding Agent
- Code Review
- 自动测试
- 软件工程 Agent

**设计**

- AI 绘图
- AI 视频
- AI 3D
- AI UI Design

**客服**

- AI 客服
- AI 销售
- AI 电话
- AI 运营

**企业**

- AI ERP
- AI CRM
- AI 知识库
- AI 数据分析
- AI 决策系统

---

### 六、AI 改造传统行业

这可能是整个产业最大的部分。

```text
AI
 ↓
软件
 ↓
企业
 ↓
行业
```

例如：

| 行业 | 方向 |
| --- | --- |
| 金融 | AI + 银行 / 券商 / 保险 / 风控 |
| 医疗 | AI + 医院 / 药物研发 / 医疗影像 |
| 制造 | AI + 工厂 / 机器人 / 质检 / 工业控制 |
| 汽车 | AI + 自动驾驶 / 智能座舱 / 车辆控制 |
| 教育 | AI + 教师 / 学习 / 教材 / 个性化教育 |
| 法律 | AI + 法律检索 / 合同 / 律师工作 |
| 科研 | AI + 数学 / 生物 / 化学 / 物理 / 科研 Agent |

---

### 七、AI 反向改造物理世界

```text
AI
 ↓
机器人
 ↓
物理世界
```

包括：

- 人形机器人
- 工业机器人
- 无人机
- 自动驾驶
- 仓储机器人
- 家庭机器人
- 智能制造
- Autonomous Agent

于是 AI 产业就不再只是软件产业，而逐渐变成：

> **计算产业 → 软件产业 → 自动化产业 → 机器人产业 → 物理世界**

---

### AI 产业地图（压缩版）

```text
                         ┌── 能源
                         ├── 电网
                         └── 数据中心
                              ↓
                         ┌── 芯片
                         ├── HBM
                         ├── 封装
                         └── 服务器
                              ↓
                         ┌── 云计算
                         ├── GPU Cloud
                         ├── 网络
                         └── 存储
                              ↓
                         ┌── 基础模型
                         │   ├── LLM
                         │   ├── 多模态
                         │   └── Reasoning
                         ↓
                  AI Runtime / Tooling
                         ├── Agent
                         ├── MCP
                         ├── RAG
                         ├── Memory
                         ├── Evaluation
                         └── Harness
                              ↓
                         AI Applications
                         ├── Coding
                         ├── Office
                         ├── Search
                         ├── Design
                         └── Customer Service
                              ↓
                       行业 AI
                         ├── 金融
                         ├── 医疗
                         ├── 教育
                         ├── 法律
                         ├── 制造
                         └── 科研
                              ↓
                    AI + Robotics
                         ├── 自动驾驶
                         ├── 工业机器人
                         ├── 人形机器人
                         └── Autonomous Systems
```
