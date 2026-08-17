# FROM r-base:3.6.2

# 使用官方的 R 3.6.2 基础镜像
FROM rocker/r-ver:3.6.2

# 设置环境变量，避免 apt 安装时出现交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖（Python/Jupyter 环境以及常见 R 包的底层 C/C++ 库）
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    fonts-dejavu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 升级 pip 并安装 JupyterLab
RUN pip3 install --upgrade pip \
    && pip3 install --no-cache-dir jupyter jupyterlab

# 安装 IRkernel（R 的 Jupyter 内核）并在系统中全局注册
# 注意：这里不指定 repos，让其使用 rocker 镜像默认配置的历史快照源，确保兼容 R 3.6.2
RUN R -e "install.packages('IRkernel')" \
    && R -e "IRkernel::installspec(user = FALSE)"

# 设置工作目录
WORKDIR /workspace

# 暴露 JupyterLab 默认端口
EXPOSE 8888

# 启动 JupyterLab，允许 root 运行，并为了本地开发方便暂时关闭 token 验证
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]