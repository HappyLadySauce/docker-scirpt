#!/bin/bash

# 定义颜色
# 红色
RED='\033[0;31m'
# 绿色
GREEN='\033[0;32m'
# 黄色
YELLOW='\033[0;33m'
# 蓝色
BLUE='\033[0;34m'
# 青色
CYAN='\033[0;36m'
# 紫色
PURPLE='\033[0;35m'
# 灰色
GRAY='\033[0;37m'
# 加粗
BOLD='\033[1m'
# 无颜色
NONE='\033[0m'

###############################################################################################################################
# clear
# echo -e $LIGHT_PURPLE"========================================[ Welcome! ]========================================="$NONE
# echo -e $LIGHT_PURPLE"===================================[ Thanks for using! ]====================================="$NONE
# echo -e $LIGHT_BLUE'
#              _  _                     _            _      ___
#             | || |__ _ _ __ _ __ _  _| |   __ _ __| |_  _/ __| __ _ _  _ __ ___
#             | __ / _` | "_ \ "_ \ || | |__/ _` / _` | || \__ \/ _` | || / _/ -_)
#             |_||_\__,_| .__/ .__/\_, |____\__,_\__,_|\_, |___/\__,_|\_,_\__\___|
#                       |_|  |_|   |__/                |__/
# '$NONE
# echo -e "                         "$LIGHT_CYAN"github:"$NONE $YELLOW"https://github.com/HappyLadySauce"$NONE
# echo -e "                          "$LIGHT_CYAN"gitee:"$NONE $YELLOW"https://gitee.com/HappyLadySauce"$NONE
# echo -e "                           "$LIGHT_CYAN"csdn:"$NONE $YELLOW"https://blog.csdn.net/m0_73928695"$NONE
# echo -e "                              "$LIGHT_CYAN"blog:"$NONE $YELLOW"https://happlelaoganma.cn"$NONE
# echo -e $LIGHT_PURPLE"===================================[ Thanks for using! ]====================================="$NONE
###############################################################################################################################

# 功能分析 支持指定镜像文件列表
# docker 操作
# 从 docker 中导出镜像,支持导出到指定目录
# 从 docker 中导入镜像,支持从指定目录导入,如果没有镜像则进行拉取
# 从 docker 中删除镜像
# 仓库操作
# 从仓库中导入镜像,支持从指定目录导入,如果没有镜像则进行拉取
# 从仓库中导出镜像,支持导出到指定目录

# Docker命令说明
docker_command_explanation() {
    echo -e "${BOLD}Docker命令说明${NONE}"
    echo -e "${CYAN}以下是Docker中save、export、load和import命令的区别:${NONE}"
    echo
    echo -e "${BOLD}docker save与docker load${NONE}"
    echo -e "保存和加载${GREEN}镜像${NONE}的完整内容，包括镜像的${YELLOW}分层结构和元数据${NONE}"
    echo -e "适合用于${GREEN}镜像的备份和迁移${NONE}"
    echo
    echo -e "${BOLD}docker export与docker import${NONE}"
    echo -e "导出和导入${GREEN}容器${NONE}的文件系统，${RED}不包含分层结构和元数据${NONE}"
    echo -e "导出的是${YELLOW}扁平的文件系统${NONE}，可以直接解压使用"
    echo -e "导入后生成的镜像${RED}只有一个单一的层${NONE}，无法保留版本历史"
    echo -e "适合从${GREEN}容器创建新的基础镜像${NONE}或备份容器的运行状态"
    echo
    echo -e "${BOLD}docker pull与docker push${NONE}"
    echo -e "用于与${GREEN}镜像仓库${NONE}之间传输镜像"
    echo -e "保留了镜像的${YELLOW}所有元数据和分层信息${NONE}"
    echo
    echo -e "${PURPLE}按任意键继续...${NONE}"
    read -n 1 -s
}

# ./docker.sh
usage () {
    echo -e $PURPLE"用法: $0 [--option] [--option-value]"$NONE
    echo -e $GREEN"指定镜像"$NONE
    echo -e $CYAN"  [-i|--image-list] 指定镜像文件列表"$NONE
    echo -e $CYAN"  [-n|--image-name] 指定单个镜像名称（优先级高于镜像列表）"$NONE
    echo -e $GREEN"指定镜像目录"$NONE
    echo -e $CYAN"  [-d|--images-dir] 指定导出/导入镜像的目录"$NONE
    echo -e $GREEN"docker 相关操作"$NONE
    echo -e $CYAN"  --load    导入镜像的完整内容，包含原始镜像的分层结构和元数据"$NONE
    echo -e $CYAN"  --save    导出镜像的完整内容，包含原始镜像的分层结构和元数据"$NONE
    echo -e $CYAN"  --import  从容器导出的文件系统创建新镜像，仅生成单层镜像"$NONE
    echo -e $CYAN"  --export  导出容器的文件系统，生成扁平的文件系统归档"$NONE
    echo -e $CYAN"  --delete  删除指定镜像"$NONE
    echo -e $CYAN"  --strip-registry 前缀  重命名本地镜像，移除指定的仓库前缀"$NONE
    echo -e $GREEN"仓库相关操作"$NONE
    echo -e $CYAN"  --pull    从仓库拉取镜像"$NONE
    echo -e $CYAN"  --push    推送镜像到仓库"$NONE
    echo -e $CYAN"  [-r|--registry] 指定私有仓库地址"$NONE
    echo -e $CYAN"  [-s|--source-registry] 指定源仓库地址"$NONE
    echo -e $CYAN"  [-p|--project] 指定项目名称"$NONE
    echo -e $CYAN"  [--target-registry] 指定目标仓库前缀，用于推送或重命名（替代默认的docker.io）"$NONE
    echo -e $CYAN"  [--explain] 显示Docker命令说明"$NONE
    echo -e $CYAN"  [-h|--help] 显示帮助信息"$NONE
    echo -e $GREEN"直接操作示例"$NONE
    echo -e $CYAN"  ./docker.sh --save -n nginx:latest -d ./images"$NONE
    echo -e $CYAN"  ./docker.sh --load -n nginx:latest -d ./images"$NONE
    echo -e $CYAN"  ./docker.sh --delete -n nginx:latest"$NONE
    echo -e $CYAN"  ./docker.sh --strip-registry registry.cn-hangzhou.aliyuncs.com -i rancher-images.txt"$NONE
    echo -e $CYAN"  ./docker.sh --push -i rancher-images.txt -r registry.example.com --target-registry library"$NONE
}

# 获取安全的文件名
# 例子: 
# 输入: rancher/calico-cni:v3.27.4-rancher1.tar
# 输出: rancher_calico-cni_v3.27.4-rancher1.tar
get_safe_filename() {
    local filename=$1
    # 替换冒号和斜杠为下划线
    echo "${filename//[:\/]/_}"
}

# 去除镜像名称的仓库前缀
# 例子: 
# 输入: registry.cn-hangzhou.aliyuncs.com/rancher/calico-cni:v3.27.4-rancher1
# 输出: rancher/calico-cni:v3.27.4-rancher1
strip_registry_prefix() {
    local image_name=$1
    local prefix=$2
    
    # 如果指定了前缀
    if [ -n "$prefix" ]; then
        # 检查镜像名是否以指定前缀开头
        if [[ "$image_name" == "$prefix"* ]]; then
            # 移除前缀
            echo "${image_name#$prefix/}"
        else
            # 不是指定前缀，原样返回
            echo "$image_name"
        fi
    else
        # 没有指定前缀，使用通用逻辑
        # 如果镜像名包含至少两个/，则移除第一个/前的所有内容
        if [[ "$image_name" == *"/"*"/"* ]]; then
            echo "${image_name#*/}"
        else
            echo "$image_name"
        fi
    fi
}

# 创建变量来跟踪操作模式
operation_mode=""
registry_mode=""

# 选项处理
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        # 指定镜像文件列表
        -i|--image-list)
        image_list="$2"
        shift # past argument
        shift # past value
        ;;
        # 指定单个镜像名称
        -n|--image-name)
        image_name="$2"
        shift # past argument
        shift # past value
        ;;
        # 指定镜像目录
        -d|--images-dir)
        images_dir="$2"
        shift # past argument
        shift # past value
        ;;
        # 去除镜像仓库前缀
        --strip-registry)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)${NONE}"
            exit 1
        fi
        operation_mode="strip_registry"
        strip_registry="true"
        if [[ "$2" != -* ]] && [[ -n "$2" ]]; then
            registry_prefix="$2"
            shift # past value
        fi
        shift # past argument
        ;;
        # 指定目标仓库前缀
        --target-registry)
        target_registry="$2"
        shift # past argument
        shift # past value
        ;;
        # 导入镜像
        --load)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="load"
        load="true"
        shift # past argument
        ;;
        # 导出镜像
        --save)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="save"
        save="true"
        shift # past argument
        ;;
        # 删除镜像
        --delete)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="delete"
        delete="true"
        shift # past argument
        ;;
        # 拉取镜像
        --pull)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="pull"
        pull="true"
        shift # past argument
        ;;
        # 推送镜像
        --push)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="push"
        push="true"
        shift # past argument
        ;;
        # 导入容器文件系统为镜像
        --import)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="import"
        import="true"
        shift # past argument
        ;;
        # 导出容器文件系统
        --export)
        if [ -n "$operation_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push)${NONE}"
            exit 1
        fi
        operation_mode="export"
        export="true"
        shift # past argument
        ;;
        # 指定私有仓库地址
        -r|--registry)
        if [ -n "$registry_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (-r|--registry, -s|--source-registry)${NONE}"
            exit 1
        fi
        registry_mode="destination"
        registry="$2"
        echo -e "${YELLOW}提示: 使用私有仓库 $2，如果推送/拉取失败，可能需要先登录: ${NONE}"
        echo -e "${CYAN}    docker login $2${NONE}"
        shift # past argument
        shift # past value
        ;;
        # 指定源仓库地址
        -s|--source-registry)
        if [ -n "$registry_mode" ]; then
            echo -e "${RED}错误: 不能同时指定多个操作 (-r|--registry, -s|--source-registry)${NONE}"
            exit 1
        fi
        registry_mode="source"
        source_registry="$2"
        shift # past argument
        shift # past value
        ;;
        # 指定项目名称
        -p|--project)
        project="$2"
        shift # past argument
        shift # past value
        ;;
        # 显示Docker命令说明
        --explain)
        docker_command_explanation
        exit 0
        ;;
        # 显示帮助信息
        -h|--help)
        help="true"
        shift
        ;;
        *)
        usage
        exit 1
        ;;
    esac
done

# 检查是否需要显示帮助信息
if [ "$help" = "true" ]; then
    usage
    exit 0
fi

# 检查必要参数
if [ -z "$operation_mode" ]; then
    echo -e "${RED}错误: 必须指定一个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)${NONE}"
    usage
    exit 1
fi

# 检查镜像来源（镜像名称优先于镜像列表）
if [ -z "$image_name" ] && [ -z "$image_list" ]; then
    echo -e "${YELLOW}警告: 未指定镜像名称或镜像列表，默认使用 rancher-images.txt${NONE}"
    image_list="rancher-images.txt"
fi

# 如果没有指定镜像名称但有指定镜像列表，则检查列表文件是否存在
if [ -z "$image_name" ] && [ ! -f "$image_list" ]; then
    echo -e "${RED}错误: 镜像列表文件 '$image_list' 不存在!${NONE}"
    exit 1
fi

# 检查Docker服务是否正常运行
check_docker_running() {
    if ! docker info &>/dev/null; then
        echo -e "${RED}错误: Docker服务未运行或无法连接!${NONE}"
        echo "请确保Docker服务正常运行后再试。"
        return 1
    fi
    return 0
}

# 检查Docker是否运行
check_docker_running || exit 1

# 准备镜像来源
process_images() {
    local images=""
    if [ -n "$image_name" ]; then
        images=$(echo "$image_name")
    else
        # 过滤掉空行和注释行
        images=$(grep -v "^#" "$image_list" | grep -v "^$")
    fi
    echo "$images"
}

# 执行操作
case $operation_mode in
    "load")
        # 检查必要参数
        if [ -z "$images_dir" ]; then
            echo -e "${RED}错误: 导入镜像需要指定镜像目录 (-d|--images-dir)${NONE}"
            exit 1
        fi
        
        echo -e "${GREEN}开始从目录 $images_dir 导入镜像...${NONE}"
        echo -e "${BLUE}使用docker load命令导入，包含镜像的分层结构和元数据${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r image; do
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 获取镜像文件名
            safe_filename=$(get_safe_filename "$image")
            image_file="${images_dir}/${safe_filename}.tar.gz"
            
            # 检查镜像文件是否存在
            if [ ! -f "$image_file" ]; then
                image_file="${images_dir}/${safe_filename}.tar"
                if [ ! -f "$image_file" ]; then
                    echo -e "${RED}[失败] 未找到镜像文件: ${images_dir}/${safe_filename}.tar(.gz)${NONE}"
                    ((failed++))
                    continue
                fi
            fi
            
            # 加载镜像
            echo -e "${BLUE}[加载] $image${NONE}"
            if docker load < "$image_file"; then
                echo -e "${GREEN}[成功] 加载镜像: $image${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 加载镜像: $image${NONE}"
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "save")
        # 检查必要参数
        if [ -z "$images_dir" ]; then
            echo -e "${RED}错误: 导出镜像需要指定镜像目录 (-d|--images-dir)${NONE}"
            exit 1
        fi
        
        # 创建输出目录
        mkdir -p "$images_dir"
        
        echo -e "${GREEN}开始将镜像导出到目录 $images_dir...${NONE}"
        echo -e "${BLUE}使用docker save命令导出，保留镜像的分层结构和元数据${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表并清除可能的空行
        images_list=$(process_images | grep -v "^$")
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r image; do
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 处理源仓库前缀
            if [ -n "$source_registry" ]; then
                full_image="${source_registry}/${image}"
            else
                full_image="$image"
            fi
            
            # 检查镜像是否已加载（先尝试原始名称）
            image_exists=false
            if docker inspect "$full_image" &>/dev/null; then
                image_exists=true
            fi
            
            # 如果原始名称不存在，尝试检查带前缀的名称（如果指定了前缀）
            if ! $image_exists && [ -n "$registry_prefix" ]; then
                prefixed_image="${registry_prefix}/${full_image}"
                if docker inspect "$prefixed_image" &>/dev/null; then
                    image_exists=true
                    full_image="$prefixed_image"  # 使用找到的带前缀镜像名
                    echo -e "${BLUE}[找到] 使用带前缀的镜像: $prefixed_image${NONE}"
                fi
            fi

            if ! $image_exists; then
                echo -e "${RED}[失败] 镜像 $full_image 不存在，请先拉取或导入该镜像${NONE}"
                ((failed++))
                continue
            fi
            
            # 如果需要去除仓库前缀，则对输出文件名使用去除前缀后的名称
            if [ "$strip_registry" = "true" ]; then
                save_image_name=$(strip_registry_prefix "$image" "$registry_prefix")
                echo -e "${BLUE}[处理] 原始镜像: $image${NONE}"
                echo -e "${BLUE}[处理] 去除前缀后: $save_image_name${NONE}"
            else
                save_image_name="$image"
            fi
            
            # 获取镜像文件名
            safe_filename=$(get_safe_filename "$save_image_name")
            output_file_gz="${images_dir}/${safe_filename}.tar.gz"
            output_file_tar="${images_dir}/${safe_filename}.tar"
            
            # 检查镜像是否已存在
            if [ -f "$output_file_gz" ] || [ -f "$output_file_tar" ]; then
                if [ -f "$output_file_gz" ]; then
                    echo -e "${YELLOW}[跳过] 镜像文件已存在: $output_file_gz${NONE}"
                else
                    echo -e "${YELLOW}[跳过] 镜像文件已存在: $output_file_tar${NONE}"
                fi
                ((success++))
                continue
            fi
            
            # 导出镜像
            echo -e "${BLUE}[导出] $full_image${NONE}"
            if docker save "$full_image" | gzip > "$output_file_gz"; then
                echo -e "${GREEN}[成功] 导出镜像: $full_image -> $output_file_gz${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 导出镜像: $full_image${NONE}"
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "import")
        # 检查必要参数
        if [ -z "$images_dir" ]; then
            echo -e "${RED}错误: 导入容器文件系统需要指定镜像目录 (-d|--images-dir)${NONE}"
            exit 1
        fi
        
        echo -e "${GREEN}开始从容器文件系统导入镜像...${NONE}"
        echo -e "${BLUE}使用docker import命令导入，创建单层镜像，不包含镜像历史和元数据${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        echo "$images_list" | while IFS= read -r image; do
            # 忽略空行
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 获取镜像文件名
            safe_filename=$(get_safe_filename "$image")
            image_file="${images_dir}/${safe_filename}.tar.gz"
            
            # 检查镜像文件是否存在
            if [ ! -f "$image_file" ]; then
                # 尝试查找非压缩的 tar 格式
                image_file="${images_dir}/${safe_filename}.tar"
                if [ ! -f "$image_file" ]; then
                    echo -e "${RED}[失败] 未找到容器归档文件: ${safe_filename}.tar(.gz)${NONE}"
                    ((failed++))
                    continue
                fi
            fi
            
            # 导入镜像
            echo -e "${BLUE}[导入] $image_file -> $image${NONE}"
            if docker import "$image_file" "$image"; then
                echo -e "${GREEN}[成功] 导入镜像: $image${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 导入镜像: $image${NONE}"
                ((failed++))
            fi
        done
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "export")
        # 检查必要参数
        if [ -z "$images_dir" ]; then
            echo -e "${RED}错误: 导出容器文件系统需要指定镜像目录 (-d|--images-dir)${NONE}"
            exit 1
        fi
        
        # 创建输出目录
        mkdir -p "$images_dir"
        
        echo -e "${GREEN}开始导出容器文件系统到目录 $images_dir...${NONE}"
        echo -e "${BLUE}使用docker export命令导出，仅导出容器的文件系统，不含镜像历史和元数据${NONE}"
        echo -e "${YELLOW}注意: export命令用于导出运行中的容器，而不是镜像。如需导出镜像请使用--save选项。${NONE}"
        echo -e "${YELLOW}您需要先通过docker run创建并运行容器，然后才能使用export导出。${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个容器: $image_name${NONE}"
        else
            echo -e "${BLUE}使用容器列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理容器数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r line; do
            # 忽略空行
            [ -z "$line" ] && continue
            
            ((total++))
            
            # 容器信息处理：支持容器ID:导出名称格式
            if [[ "$line" == *":"* ]]; then
                # 格式: container_id:export_name
                container_id="${line%%:*}"
                export_name="${line#*:}"
            else
                # 只有容器ID或名称，使用相同名称导出
                container_id="$line"
                export_name="$line"
            fi
            
            # 检查容器是否存在
            if ! docker inspect "$container_id" &>/dev/null; then
                echo -e "${RED}[失败] 容器不存在: $container_id${NONE}"
                ((failed++))
                continue
            fi
            
            # 获取安全的文件名
            safe_filename=$(get_safe_filename "$export_name")
            output_file="${images_dir}/${safe_filename}.tar"
            
            # 导出容器
            echo -e "${BLUE}[导出] 容器 $container_id -> $output_file${NONE}"
            if docker export "$container_id" > "$output_file"; then
                echo -e "${GREEN}[成功] 导出容器: $container_id -> $output_file${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 导出容器: $container_id${NONE}"
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "delete")
        echo -e "${GREEN}开始删除镜像...${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r image; do
            # 忽略空行
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 处理源仓库前缀
            if [ -n "$source_registry" ]; then
                full_image="${source_registry}/${image}"
            else
                full_image="$image"
            fi
            
            # 检查镜像是否存在
            if ! docker inspect "$full_image" &>/dev/null; then
                echo -e "${YELLOW}[跳过] 镜像不存在: $full_image${NONE}"
                continue
            fi
            
            # 删除镜像
            echo -e "${BLUE}[删除] $full_image${NONE}"
            if docker rmi -f "$full_image"; then
                echo -e "${GREEN}[成功] 删除镜像: $full_image${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 删除镜像: $full_image${NONE}"
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "pull")
        # 检查必要参数
        if [ -z "$source_registry" ]; then
            echo -e "${YELLOW}警告: 未指定源仓库地址，将从默认的Docker Hub拉取镜像${NONE}"
        fi
        
        echo -e "${GREEN}开始拉取镜像...${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r image; do
            # 忽略空行
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 处理源仓库前缀
            if [ -n "$source_registry" ]; then
                full_image="${source_registry}/${image}"
            else
                full_image="$image"
            fi
            
            # 检查镜像是否已存在 - 更精确的检查
            image_exists=false
            if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${full_image}$"; then
                image_exists=true
            fi
            
            if $image_exists; then
                echo -e "${YELLOW}[跳过] 镜像已存在: $full_image${NONE}"
                ((success++))
                continue
            fi
            
            # 拉取镜像
            echo -e "${BLUE}[拉取] $full_image${NONE}"
            if docker pull "$full_image"; then
                echo -e "${GREEN}[成功] 拉取镜像: $full_image${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 拉取镜像: $full_image${NONE}"
                if [ -n "$registry" ] || [ -n "$source_registry" ]; then
                    echo -e "${YELLOW}提示: 可能需要先登录到私有仓库: ${NONE}"
                    if [ -n "$registry" ]; then
                        echo -e "${CYAN}    docker login $registry${NONE}"
                    fi
                    if [ -n "$source_registry" ]; then
                        echo -e "${CYAN}    docker login $source_registry${NONE}"
                    fi
                fi
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "push")
        # 检查必要参数
        if [ -z "$registry" ]; then
            echo -e "${RED}错误: 推送镜像需要指定目标仓库地址 (-r|--registry)${NONE}"
            exit 1
        fi
        
        echo -e "${GREEN}开始推送镜像到 $registry...${NONE}"
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r image; do
            # 忽略空行
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 提取镜像名称和标签
            if [[ $image == *":"* ]]; then
                image_name=$(echo "$image" | cut -d':' -f1)
                tag=$(echo "$image" | cut -d':' -f2)
            else
                image_name="$image"
                tag="latest"
            fi
            
            # 处理镜像名称
            if [ -n "$target_registry" ]; then
                # 提取镜像名称，移除可能存在的域名部分
                if [[ "$image_name" == *"/"* ]]; then
                    # 检查是否是域名（包含.）或标准仓库（包含/）
                    if [[ "$image_name" == *"."*"/"* ]] || [[ "$image_name" == *"/"*"/"* ]]; then
                        # 移除域名部分，保留路径
                        simple_name="${image_name#*/}"
                    else
                        simple_name="$image_name"
                    fi
                else
                    simple_name="$image_name"
                fi
                
                # 使用target_registry作为命名空间
                target_image="${registry}/${target_registry}/${simple_name}:${tag}"
                echo -e "${BLUE}[处理] 使用目标仓库前缀: $target_registry${NONE}"
            elif [ -n "$project" ]; then
                # 使用project作为前缀
                target_image="${registry}/${project}/${image_name}:${tag}"
            else
                # 不使用额外前缀
                target_image="${registry}/${image_name}:${tag}"
            fi
            
            # 标记镜像
            echo -e "${BLUE}[标记] $image -> $target_image${NONE}"
            if ! docker tag "$image" "$target_image"; then
                echo -e "${RED}[失败] 无法标记镜像: $image -> $target_image${NONE}"
                ((failed++))
                continue
            fi
            
            # 推送镜像
            echo -e "${BLUE}[推送] $target_image${NONE}"
            if docker push "$target_image"; then
                echo -e "${GREEN}[成功] 推送镜像: $target_image${NONE}"
                ((success++))
            else
                echo -e "${RED}[失败] 推送镜像: $target_image${NONE}"
                echo -e "${YELLOW}提示: 可能需要先登录到私有仓库: ${NONE}"
                echo -e "${CYAN}    docker login $registry${NONE}"
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
        
    "strip_registry")
        echo -e "${GREEN}开始对本地镜像进行重命名...${NONE}"
        
        # 必须指定registry_prefix参数用于去除前缀
        if [ -z "$registry_prefix" ]; then
            echo -e "${RED}错误: --strip-registry 操作必须指定要去除的仓库前缀${NONE}"
            echo -e "${YELLOW}示例: ./docker.sh --strip-registry registry.cn-hangzhou.aliyuncs.com -i rancher-images.txt${NONE}"
            exit 1
        fi
        
        # 显示使用的镜像来源
        if [ -n "$image_name" ]; then
            echo -e "${BLUE}使用单个镜像: $image_name${NONE}"
        else
            echo -e "${BLUE}使用镜像列表: $image_list${NONE}"
        fi
        
        # 显示目标仓库信息
        if [ -n "$target_registry" ]; then
            echo -e "${BLUE}指定目标仓库前缀: $target_registry${NONE}"
        fi
        
        # 统计计数器
        total=0
        success=0
        failed=0
        
        # 获取镜像列表
        images_list=$(process_images)
        
        # 显示镜像数量
        image_count=$(echo "$images_list" | grep -v "^$" | wc -l)
        echo -e "${BLUE}处理镜像数量: $image_count${NONE}"
        
        # 处理镜像列表
        while IFS= read -r image; do
            # 忽略空行
            [ -z "$image" ] && continue
            
            ((total++))
            
            # 检查是否存在指定前缀的镜像
            prefixed_image="${registry_prefix}/${image}"
            
            # 构建目标镜像名（如果指定了target_registry）
            if [ -n "$target_registry" ]; then
                # 解析镜像名和标签
                if [[ "$image" == *":"* ]]; then
                    image_without_tag="${image%:*}"
                    tag="${image#*:}"
                else
                    image_without_tag="$image"
                    tag="latest"
                fi
                
                # 构建带目标仓库前缀的镜像名
                target_image="${target_registry}/${image_without_tag}:${tag}"
                echo -e "${BLUE}[目标] 重命名为: $target_image${NONE}"
            else
                target_image="$image"
            fi
            
            # 检查镜像是否存在
            if ! docker inspect "$prefixed_image" &>/dev/null; then
                echo -e "${RED}[失败] 镜像 $prefixed_image 不存在，无法重命名${NONE}"
                ((failed++))
                continue
            fi
            
            # 重命名镜像（使用tag和删除原镜像的方式）
            echo -e "${BLUE}[重命名] $prefixed_image -> $target_image${NONE}"
            if docker tag "$prefixed_image" "$target_image"; then
                if docker rmi "$prefixed_image"; then
                    echo -e "${GREEN}[成功] 重命名镜像: $prefixed_image -> $target_image${NONE}"
                    ((success++))
                else
                    echo -e "${YELLOW}[警告] 重命名成功但无法删除原镜像: $prefixed_image${NONE}"
                    ((success++))
                fi
            else
                echo -e "${RED}[失败] 重命名镜像: $prefixed_image${NONE}"
                ((failed++))
            fi
        done <<< "$(echo "$images_list")"
        
        echo -e "${GREEN}完成!${NONE}"
        echo -e "总共: $total, 成功: $success, 失败: $failed"
        ;;
esac
