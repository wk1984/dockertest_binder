# ==========================================
# 第一阶段：编译环境 (Build Stage)
# ==========================================
FROM ubuntu:noble AS builder

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装编译所需的开发库和工具
# 合并命令并清理缓存以减小中间层体积 
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libboost-all-dev \
    libjsoncpp-dev \
    liblapacke-dev \
    libnetcdf-dev \
    libreadline-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 仅复制编译所需的文件 [cite: 30, 32]
COPY src/ ./src
COPY include/ ./include
COPY Makefile ./Makefile
COPY .git ./ .git

# 解决 git 安全路径问题并进行编译 [cite: 33, 36]
RUN git config --global --add safe.directory /build && \
    make

# ==========================================
# 第二阶段：运行环境 (Runtime Stage)
# ==========================================
# 使用相同的发行版以确保 GLIBC 兼容性，但保持精简 [cite: 42]
FROM ubuntu:noble

WORKDIR /app

# 从构建阶段复制编译好的二进制程序 [cite: 42]
COPY --from=builder /build/dvmdostem ./

# 复制必要的配置文件和脚本（根据需求选择性复制） [cite: 42]
COPY config/ ./config
COPY parameters/ ./parameters
COPY scripts/ ./scripts

# 安装仅运行所需的最小化共享库
# 注意：这里只安装运行时库，不安装 -dev 后缀的开发包 [cite: 38]
RUN apt-get update && apt-get install -y --no-install-recommends \
    libboost-system1.83.0 \
    libboost-filesystem1.83.0 \
    libboost-program-options1.83.0 \
    libboost-log1.83.0 \
    libjsoncpp25 \
    liblapacke \
    libnetcdf19 \
    libreadline8 \
    && rm -rf /var/lib/apt/lists/*

# 设置环境变量 [cite: 24]
ENV PATH="/app:${PATH}"

# 运行模型
ENTRYPOINT ["./dvmdostem"]