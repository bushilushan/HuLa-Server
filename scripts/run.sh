#!/usr/bin/env bash

# 简化版服务运行脚本
# 用法: ./scripts/run.sh <module-name> <directory> <profile> <action>
# 示例: ./scripts/run.sh luohuo-gateway-server luohuo-gateway dev start

MODULE=$1
DIRECTORY=$2
PROFILE=${3:-dev}
ACTION=${4:-start}

# 查找项目根目录（通过查找 luohuo-util 和 luohuo-cloud 目录）
find_project_root() {
    # 获取脚本绝对路径
    local script_path
    script_path=$(readlink -f "$0" 2>/dev/null)
    if [[ -z "$script_path" ]]; then
        script_path=$(realpath "$0" 2>/dev/null)
    fi
    if [[ -z "$script_path" ]]; then
        # 最后的fallback
        script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    fi

    # 从脚本所在目录开始，向上查找项目根目录
    local current_dir
    current_dir=$(dirname "$script_path")

    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/luohuo-util" && -d "$current_dir/luohuo-cloud" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    # 如果找不到，报错退出
    echo "错误: 找不到项目根目录（需要同时存在 luohuo-util 和 luohuo-cloud 目录）" >&2
    exit 1
}

BASE_PATH=$(find_project_root)

# JVM 参数配置
case $MODULE in
    "luohuo-ai-server")
        JAVA_OPT="-server -Xms1024M -Xmx1024M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    "luohuo-system-server")
        JAVA_OPT="-server -Xms1024M -Xmx1024M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    "luohuo-oauth-server")
        JAVA_OPT="-server -Xms1024M -Xmx1024M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    "luohuo-gateway-server")
        JAVA_OPT="-server -Xms1600M -Xmx2048M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    "luohuo-base-server")
        JAVA_OPT="-server -Xms1024M -Xmx1024M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    "luohuo-ws-server")
        JAVA_OPT="-server -Xms1024M -Xmx1024M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    "luohuo-im-server")
        JAVA_OPT="-server -Xms1680M -Xmx2048M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
    *)
        echo "模块 $MODULE 未配置 JVM 参数，使用默认配置"
        JAVA_OPT="-server -Xms1024M -Xmx1024M -Xss256k -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+UseG1GC"
        ;;
esac

JAVA_OPT="$JAVA_OPT -Dspring.profiles.active=$PROFILE"

# 日志目录
LOG_DIR="$BASE_PATH/luohuo-cloud/logs"
LOG_FILE="$LOG_DIR/$MODULE.log"

# jar 包路径
JAR_PATH="$BASE_PATH/luohuo-cloud/$DIRECTORY/$MODULE/target/$MODULE.jar"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 启动服务
start() {
    count=$(ps -ef | grep java | grep "$MODULE" | grep -v grep | wc -l)
    if [ "$count" -ne 0 ]; then
        echo "$MODULE 已在运行"
        return
    fi

    echo "启动 $MODULE..."
    echo "配置: $JAVA_OPT"
    echo "JAR: $JAR_PATH"
    echo "日志: $LOG_FILE"

    if [ ! -f "$JAR_PATH" ]; then
        echo "错误: jar 包不存在: $JAR_PATH"
        exit 1
    fi

    nohup java -jar $JAVA_OPT "$JAR_PATH" > "$LOG_FILE" 2>&1 &

    sleep 5
    count=$(ps -ef | grep java | grep "$MODULE" | grep -v grep | wc -l)
    if [ "$count" -ne 0 ]; then
        echo "$MODULE 启动成功"
    else
        echo "$MODULE 启动失败，请查看日志: $LOG_FILE"
    fi
}

# 停止服务
stop() {
    echo "停止 $MODULE..."
    pid=$(ps -ef | grep java | grep "$MODULE" | grep -v grep | awk '{print $2}')
    if [ -n "$pid" ]; then
        kill "$pid"
        sleep 2
        count=$(ps -ef | grep java | grep "$MODULE" | grep -v grep | wc -l)
        if [ "$count" -eq 0 ]; then
            echo "$MODULE 已停止"
        else
            echo "强制停止 $MODULE..."
            kill -9 "$pid"
            echo "$MODULE 已停止"
        fi
    else
        echo "$MODULE 未运行"
    fi
}

# 重启服务
restart() {
    stop
    sleep 2
    start
}

# 查看状态
status() {
    count=$(ps -ef | grep java | grep "$MODULE" | grep -v grep | wc -l)
    if [ "$count" -ne 0 ]; then
        echo "$MODULE 运行中"
    else
        echo "$MODULE 未运行"
    fi
}

# 执行操作
case $ACTION in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "用法: $0 <module-name> <directory> <profile> <action>"
        echo "示例: $0 luohuo-gateway-server luohuo-gateway dev start"
        exit 1
        ;;
esac
