#!/usr/bin/env bash

# HuLa-Server 一键启动脚本
# 功能：检查环境 -> 编译项目 -> 启动服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径（自动获取）
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
UTIL_PATH="$PROJECT_ROOT/luohuo-util"
CLOUD_PATH="$PROJECT_ROOT/luohuo-cloud"
RUN_SCRIPT="$PROJECT_ROOT/scripts/run.sh"

# 服务列表（按启动顺序）
SERVICES=(
    "luohuo-gateway-server:luohuo-gateway"
    "luohuo-oauth-server:luohuo-oauth"
    "luohuo-base-server:luohuo-base"
    "luohuo-system-server:luohuo-system"
    "luohuo-ai-server:luohuo-ai"
    "luohuo-im-server:luohuo-im"
    "luohuo-ws-server:luohuo-ws"
)

# 打印带消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 未安装，请先安装"
        return 1
    fi
    return 0
}

# 检查环境
check_environment() {
    print_info "=== 检查必要环境 ==="

    local required_tools=("java" "mvn")
    local all_ok=true

    for tool in "${required_tools[@]}"; do
        if ! check_command "$tool"; then
            all_ok=false
        fi
    done

    # 检查依赖服务端口
    local ports=("6379:Redis" "3306:MySQL" "8080:Nacos" "9876:RocketMQ")
    for port_service in "${ports[@]}"; do
        local port="${port_service%%:*}"
        local service="${port_service##*:}"
        if ! nc -z localhost "$port" 2>/dev/null && ! timeout 1 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
            print_warning "$service (端口 $port) 可能未启动，请确认"
        else
            print_success "$service (端口 $port) 已运行"
        fi
    done

    if [ "$all_ok" = false ]; then
        print_error "缺少必要工具，请安装后重试"
        exit 1
    fi
}

# 编译 luohuo-util
build_util() {
    print_info "=== 编译安装 luohuo-util ==="
    cd "$UTIL_PATH" || exit 1

    mvn clean install -Dmaven.javadoc.skip=true -Dgpg.skip=true -Dmaven.source.skip=true -DskipTests=true -f pom.xml

    if [ $? -eq 0 ]; then
        print_success "luohuo-util 编译成功"
    else
        print_error "luohuo-util 编译失败"
        exit 1
    fi
}

# 编译 luohuo-cloud
build_cloud() {
    print_info "=== 编译安装 luohuo-cloud ==="
    cd "$CLOUD_PATH" || exit 1

    mvn clean install -Dmaven.javadoc.skip=true -Dgpg.skip=true -Dmaven.source.skip=true -DskipTests=true

    if [ $? -eq 0 ]; then
        print_success "luohuo-cloud 编译成功"
    else
        print_error "luohuo-cloud 编译失败"
        exit 1
    fi
}

# 停止所有服务
stop_services() {
    print_info "=== 停止所有服务 ==="

    for service in "${SERVICES[@]}"; do
        local jar_name="${service%%:*}"
        local dir_name="${service##*:}"

        bash "$RUN_SCRIPT" "$jar_name" "$dir_name" dev stop
    done
}

# 启动服务
start_services() {
    print_info "=== 启动微服务 ==="

    for service in "${SERVICES[@]}"; do
        local jar_name="${service%%:*}"
        local dir_name="${service##*:}"

        print_info "启动 $jar_name ..."

        bash "$RUN_SCRIPT" "$jar_name" "$dir_name" dev start

        sleep 3  # 等待服务启动

        # 检查服务是否启动成功
        count=$(ps -ef | grep java | grep "$jar_name" | grep -v grep | wc -l)
        if [ "$count" -ne 0 ]; then
            print_success "$jar_name 启动成功"
        else
            print_error "$jar_name 启动失败，请查看日志"
        fi
    done
}

# 显示服务状态
show_status() {
    print_info "=== 服务状态 ==="

    for service in "${SERVICES[@]}"; do
        local jar_name="${service%%:*}"
        local count=$(ps -ef | grep java | grep "$jar_name" | grep -v grep | wc -l)
        if [ "$count" -ne 0 ]; then
            echo -e "$jar_name: ${GREEN}运行中${NC}"
        else
            echo -e "$jar_name: ${RED}未运行${NC}"
        fi
    done
}

# 显示帮助
show_help() {
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  all       检查环境、编译并启动所有服务（默认）"
    echo "  build     只编译项目"
    echo "  start     只启动服务（跳过编译）"
    echo "  stop      停止所有服务"
    echo "  restart   重启所有服务"
    echo "  status    查看服务状态"
    echo "  help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 完整流程：检查+编译+启动"
    echo "  $0 all          # 同上"
    echo "  $0 start        # 只启动已编译的服务"
    echo "  $0 stop         # 停止所有服务"
}

# 主函数
main() {
    local command="${1:-all}"

    case "$command" in
        "all")
            check_environment
            build_util
            build_cloud
            stop_services
            start_services
            print_success "=== 所有服务启动完成 ==="
            show_status
            ;;
        "build")
            check_environment
            build_util
            build_cloud
            print_success "=== 编译完成 ==="
            ;;
        "start")
            start_services
            print_success "=== 服务启动完成 ==="
            show_status
            ;;
        "stop")
            stop_services
            print_success "=== 所有服务已停止 ==="
            ;;
        "restart")
            stop_services
            sleep 2
            start_services
            print_success "=== 服务重启完成 ==="
            show_status
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
