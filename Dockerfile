# 使用官方的 R 3.6.2 基础镜像
FROM jupyter/r-notebook:x86_64-lab-3.6.2

# 设置环境变量，避免 apt 安装时出现交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 修复 Debian Buster (10) EOL 导致的 apt 源 404 错误
# 将源替换为 archive.debian.org，并忽略 GPG 签名时间过期检查
RUN echo "deb http://archive.debian.org/debian/ buster main" > /etc/apt/sources.list \
    && echo "deb-src http://archive.debian.org/debian/ buster main" >> /etc/apt/sources.list \
    && echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99-archive

# 2. 修复 MRAN 停服导致的 404 错误
# 将 R 的默认源修改为 Posit Package Manager 的 2020-02-28 历史快照
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2020-02-28/"))' > /usr/local/lib/R/etc/Rprofile.site

# 设置工作目录
WORKDIR /workspace

# 暴露 JupyterLab 默认端口
EXPOSE 8888

# 启动 JupyterLab，允许 root 运行，并为了本地开发方便暂时关闭 token 验证
# CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]