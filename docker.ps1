#!/usr/bin/env pwsh

# 定义颜色
$RED = 'Red'
$GREEN = 'Green'
$YELLOW = 'Yellow'
$BLUE = 'Cyan'
$CYAN = 'Cyan'
$PURPLE = 'Magenta'
$GRAY = 'Gray'

# 颜色输出函数
function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [string]$ForegroundColor
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Docker命令说明
function Show-DockerCommandExplanation {
    Write-ColorOutput "Docker命令说明" $PURPLE
    Write-ColorOutput "以下是Docker中save、export、load和import命令的区别:" $CYAN
    Write-Host ""
    Write-ColorOutput "docker save与docker load" $PURPLE
    Write-Host "保存和加载" -NoNewline -ForegroundColor $GREEN
    Write-Host "镜像" -NoNewline
    Write-Host "的完整内容，包括镜像的" -NoNewline
    Write-Host "分层结构和元数据" -ForegroundColor $YELLOW
    Write-Host "适合用于" -NoNewline
    Write-Host "镜像的备份和迁移" -ForegroundColor $GREEN
    Write-Host ""
    Write-ColorOutput "docker export与docker import" $PURPLE
    Write-Host "导出和导入" -NoNewline -ForegroundColor $GREEN
    Write-Host "容器" -NoNewline
    Write-Host "的文件系统，" -NoNewline
    Write-Host "不包含分层结构和元数据" -ForegroundColor $RED
    Write-Host "导出的是" -NoNewline
    Write-Host "扁平的文件系统" -ForegroundColor $YELLOW
    Write-Host "，可以直接解压使用"
    Write-Host "导入后生成的镜像" -NoNewline
    Write-Host "只有一个单一的层" -ForegroundColor $RED
    Write-Host "，无法保留版本历史"
    Write-Host "适合从" -NoNewline
    Write-Host "容器创建新的基础镜像" -ForegroundColor $GREEN
    Write-Host "或备份容器的运行状态"
    Write-Host ""
    Write-ColorOutput "docker pull与docker push" $PURPLE
    Write-Host "用于与" -NoNewline
    Write-Host "镜像仓库" -ForegroundColor $GREEN
    Write-Host "之间传输镜像"
    Write-Host "保留了镜像的" -NoNewline
    Write-Host "所有元数据和分层信息" -ForegroundColor $YELLOW
    Write-Host ""
    Write-ColorOutput "按任意键继续..." $PURPLE
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# 显示帮助信息
function Show-Usage {
    Write-ColorOutput "用法: .\docker.ps1 [--option] [--option-value]" $PURPLE
    Write-ColorOutput "指定镜像" $GREEN
    Write-ColorOutput "  [-i|--image-list] 指定镜像文件列表" $CYAN
    Write-ColorOutput "  [-n|--image-name] 指定单个镜像名称（优先级高于镜像列表）" $CYAN
    Write-ColorOutput "指定镜像目录" $GREEN
    Write-ColorOutput "  [-d|--images-dir] 指定导出/导入镜像的目录" $CYAN
    Write-ColorOutput "docker 相关操作" $GREEN
    Write-ColorOutput "  --load    导入镜像的完整内容，包含原始镜像的分层结构和元数据" $CYAN
    Write-ColorOutput "  --save    导出镜像的完整内容，包含原始镜像的分层结构和元数据" $CYAN
    Write-ColorOutput "  --import  从容器导出的文件系统创建新镜像，仅生成单层镜像" $CYAN
    Write-ColorOutput "  --export  导出容器的文件系统，生成扁平的文件系统归档" $CYAN
    Write-ColorOutput "  --delete  删除指定镜像" $CYAN
    Write-ColorOutput "  --strip-registry 前缀  重命名本地镜像，移除指定的仓库前缀" $CYAN
    Write-ColorOutput "仓库相关操作" $GREEN
    Write-ColorOutput "  --pull    从仓库拉取镜像" $CYAN
    Write-ColorOutput "  --push    推送镜像到仓库" $CYAN
    Write-ColorOutput "  [-r|--registry] 指定私有仓库地址" $CYAN
    Write-ColorOutput "  [-s|--source-registry] 指定源仓库地址" $CYAN
    Write-ColorOutput "  [-p|--project] 指定项目名称" $CYAN
    Write-ColorOutput "  [--target-registry] 指定目标仓库前缀，用于推送或重命名（替代默认的docker.io）" $CYAN
    Write-ColorOutput "  [--explain] 显示Docker命令说明" $CYAN
    Write-ColorOutput "  [-h|--help] 显示帮助信息" $CYAN
    Write-ColorOutput "直接操作示例" $GREEN
    Write-ColorOutput "  .\docker.ps1 --save -n nginx:latest -d ./images" $CYAN
    Write-ColorOutput "  .\docker.ps1 --load -n nginx:latest -d ./images" $CYAN
    Write-ColorOutput "  .\docker.ps1 --delete -n nginx:latest" $CYAN
    Write-ColorOutput "  .\docker.ps1 --strip-registry registry.cn-hangzhou.aliyuncs.com -i rancher-images.txt" $CYAN
    Write-ColorOutput "  .\docker.ps1 --push -i rancher-images.txt -r registry.example.com --target-registry library" $CYAN
}

# 获取安全的文件名
function Get-SafeFilename {
    param (
        [string]$filename
    )
    # 替换冒号和斜杠为下划线
    return $filename -replace '[:\/]', '_'
}

# 去除镜像名称的仓库前缀
function Strip-RegistryPrefix {
    param (
        [string]$imageName,
        [string]$prefix = $null
    )
    
    # 如果指定了前缀
    if ($prefix) {
        # 检查镜像名是否以指定前缀开头
        if ($imageName.StartsWith("$prefix/")) {
            # 移除前缀
            return $imageName.Substring("$prefix/".Length)
        } else {
            # 不是指定前缀，原样返回
            return $imageName
        }
    } else {
        # 没有指定前缀，使用通用逻辑
        # 如果镜像名包含至少两个/，则移除第一个/前的所有内容
        if ($imageName -match ".*/.+/.+") {
            $parts = $imageName.Split('/', 2)
            return $parts[1]
        } else {
            return $imageName
        }
    }
}

# 检查Docker服务是否正常运行
function Test-DockerRunning {
    try {
        $null = docker info 2>$null
        return $true
    }
    catch {
        Write-ColorOutput "错误: Docker服务未运行或无法连接!" $RED
        Write-Host "请确保Docker服务正常运行后再试。"
        return $false
    }
}

# 主要脚本参数处理
$params = @{}
$operationMode = ""
$registryMode = ""

$i = 0
while ($i -lt $args.Count) {
    $key = $args[$i]
    
    switch ($key) {
        # 指定镜像文件列表
        { $_ -in "-i", "--image-list" } {
            $params.imageList = $args[$i + 1]
            $i += 2
            break
        }
        # 指定单个镜像名称
        { $_ -in "-n", "--image-name" } {
            $params.imageName = $args[$i + 1]
            $i += 2
            break
        }
        # 指定镜像目录
        { $_ -in "-d", "--images-dir" } {
            $params.imagesDir = $args[$i + 1]
            $i += 2
            break
        }
        # 指定目标仓库前缀
        "--target-registry" {
            $params.targetRegistry = $args[$i + 1]
            $i += 2
            break
        }
        # 去除镜像仓库前缀
        "--strip-registry" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "strip_registry"
            $params.stripRegistry = $true
            if (($i + 1) -lt $args.Count -and -not $args[$i + 1].StartsWith("-")) {
                $params.registryPrefix = $args[$i + 1]
                $i += 2
            } else {
                $i++
            }
            break
        }
        # 导入镜像
        "--load" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "load"
            $params.load = $true
            $i++
            break
        }
        # 导出镜像
        "--save" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "save"
            $params.save = $true
            $i++
            break
        }
        # 删除镜像
        "--delete" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "delete"
            $params.delete = $true
            $i++
            break
        }
        # 拉取镜像
        "--pull" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "pull"
            $params.pull = $true
            $i++
            break
        }
        # 推送镜像
        "--push" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "push"
            $params.push = $true
            $i++
            break
        }
        # 导入容器文件系统为镜像
        "--import" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "import"
            $params.import = $true
            $i++
            break
        }
        # 导出容器文件系统
        "--export" {
            if ($operationMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
                exit 1
            }
            $operationMode = "export"
            $params.export = $true
            $i++
            break
        }
        # 指定私有仓库地址
        { $_ -in "-r", "--registry" } {
            if ($registryMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (-r|--registry, -s|--source-registry)" $RED
                exit 1
            }
            $registryMode = "destination"
            $params.registry = $args[$i + 1]
            Write-ColorOutput "提示: 使用私有仓库 $($args[$i + 1])，如果推送/拉取失败，可能需要先登录: " $YELLOW
            Write-ColorOutput "    docker login $($args[$i + 1])" $CYAN
            $i += 2
            break
        }
        # 指定源仓库地址
        { $_ -in "-s", "--source-registry" } {
            if ($registryMode -ne "") {
                Write-ColorOutput "错误: 不能同时指定多个操作 (-r|--registry, -s|--source-registry)" $RED
                exit 1
            }
            $registryMode = "source"
            $params.sourceRegistry = $args[$i + 1]
            $i += 2
            break
        }
        # 指定项目名称
        { $_ -in "-p", "--project" } {
            $params.project = $args[$i + 1]
            $i += 2
            break
        }
        # 显示Docker命令说明
        "--explain" {
            Show-DockerCommandExplanation
            exit 0
        }
        # 显示帮助信息
        { $_ -in "-h", "--help" } {
            $params.help = $true
            $i++
            break
        }
        default {
            Show-Usage
            exit 1
        }
    }
}

# 检查是否需要显示帮助信息
if ($params.help) {
    Show-Usage
    exit 0
}

# 检查必要参数
if ($operationMode -eq "") {
    Write-ColorOutput "错误: 必须指定一个操作 (--load, --save, --delete, --import, --export, --pull, --push, --strip-registry)" $RED
    Show-Usage
    exit 1
}

# 检查镜像来源（镜像名称优先于镜像列表）
if (-not $params.imageName -and -not $params.imageList) {
    Write-ColorOutput "警告: 未指定镜像名称或镜像列表，默认使用 rancher-images.txt" $YELLOW
    $params.imageList = "rancher-images.txt"
}

# 如果没有指定镜像名称但有指定镜像列表，则检查列表文件是否存在
if (-not $params.imageName -and -not (Test-Path $params.imageList)) {
    Write-ColorOutput "错误: 镜像列表文件 '$($params.imageList)' 不存在!" $RED
    exit 1
}

# 检查Docker是否运行
if (-not (Test-DockerRunning)) {
    exit 1
}

# 处理镜像来源，如果指定了单个镜像，则生成只包含这个镜像的列表
$imagesList = @()
if ($params.imageName) {
    $imagesList = @($params.imageName)
    Write-ColorOutput "使用单个镜像: $($params.imageName)" $BLUE
} else {
    Write-ColorOutput "使用镜像列表: $($params.imageList)" $BLUE
    $imagesList = Get-Content $params.imageList | Where-Object { $_ -and (-not $_.StartsWith('#')) }
    Write-ColorOutput "共 $($imagesList.Count) 个镜像" $BLUE
}

# 执行操作
switch ($operationMode) {
    "load" {
        # 检查必要参数
        if (-not $params.imagesDir) {
            Write-ColorOutput "错误: 导入镜像需要指定镜像目录 (-d|--images-dir)" $RED
            exit 1
        }
        
        Write-ColorOutput "开始从目录 $($params.imagesDir) 导入镜像..." $GREEN
        Write-ColorOutput "使用docker load命令导入，包含镜像的分层结构和元数据" $BLUE
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 获取镜像文件名
            $safeFilename = Get-SafeFilename $image
            $imageFile = Join-Path $params.imagesDir "$safeFilename.tar.gz"
            
            # 检查镜像文件是否存在
            if (-not (Test-Path $imageFile)) {
                $imageFile = Join-Path $params.imagesDir "$safeFilename.tar"
                if (-not (Test-Path $imageFile)) {
                    Write-ColorOutput "[失败] 未找到镜像文件: ${safeFilename}.tar(.gz)" $RED
                    $failed++
                    continue
                }
            }
            
            # 加载镜像
            Write-ColorOutput "[加载] $image" $BLUE
            try {
                docker load -i "$imageFile"
                Write-ColorOutput "[成功] 加载镜像: $image" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 加载镜像: $image" $RED
                Write-Host $_.Exception.Message
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "save" {
        # 检查必要参数
        if (-not $params.imagesDir) {
            Write-ColorOutput "错误: 导出镜像需要指定镜像目录 (-d|--images-dir)" $RED
            exit 1
        }
        
        # 创建输出目录
        if (-not (Test-Path $params.imagesDir)) {
            New-Item -Path $params.imagesDir -ItemType Directory -Force | Out-Null
        }
        
        Write-ColorOutput "开始将镜像导出到目录 $($params.imagesDir)..." $GREEN
        Write-ColorOutput "使用docker save命令导出，保留镜像的分层结构和元数据" $BLUE
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 处理源仓库前缀
            if ($params.sourceRegistry) {
                $fullImage = "$($params.sourceRegistry)/$image"
            }
            else {
                $fullImage = $image
            }
            
            # 检查镜像是否已加载
            try {
                $null = docker inspect $fullImage 2>$null
            }
            catch {
                Write-ColorOutput "[失败] 镜像 $fullImage 不存在，请先拉取或导入该镜像" $RED
                $failed++
                continue
            }
            
            # 获取镜像文件名
            $safeFilename = Get-SafeFilename $image
            $tempTarGz = Join-Path $params.imagesDir "$safeFilename.tar.gz"
            $tempTar = Join-Path $params.imagesDir "$safeFilename.tar"
            
            # 检查镜像文件是否已存在
            if ((Test-Path $tempTarGz) -or (Test-Path $tempTar)) {
                if (Test-Path $tempTarGz) {
                    Write-ColorOutput "[跳过] 镜像文件已存在: $tempTarGz" $YELLOW
                } else {
                    Write-ColorOutput "[跳过] 镜像文件已存在: $tempTar" $YELLOW
                }
                $success++
                continue
            }
            
            # 导出镜像
            Write-ColorOutput "[导出] $fullImage" $BLUE
            try {
                # 先导出为 .tar，再压缩为 .tar.gz
                docker save $fullImage -o $tempTar
                # 使用 gzip 压缩
                if (Get-Command gzip -ErrorAction SilentlyContinue) {
                    & gzip -f $tempTar
                    $outputFile = "$tempTar.gz"
                } else {
                    # 如果没有 gzip，警告用户安装 gzip，并保留未压缩的 .tar 文件
                    Write-ColorOutput "警告: 未检测到 gzip，将保留未压缩的 .tar 文件。建议安装 gzip 以生成标准 .tar.gz 文件并节省空间" $YELLOW
                    $outputFile = $tempTar
                }
                Write-ColorOutput "[成功] 导出镜像: $fullImage -> $outputFile" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 导出镜像: $fullImage" $RED
                Write-Host $_.Exception.Message
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "import" {
        # 检查必要参数
        if (-not $params.imagesDir) {
            Write-ColorOutput "错误: 导入容器文件系统需要指定镜像目录 (-d|--images-dir)" $RED
            exit 1
        }
        
        Write-ColorOutput "开始从容器文件系统导入镜像..." $GREEN
        Write-ColorOutput "使用docker import命令导入，创建单层镜像，不包含镜像历史和元数据" $BLUE
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 获取镜像文件名
            $safeFilename = Get-SafeFilename $image
            $imageFile = Join-Path $params.imagesDir "$safeFilename.tar.gz"
            
            # 检查镜像文件是否存在
            if (-not (Test-Path $imageFile)) {
                # 尝试查找非压缩的 tar 格式
                $imageFile = Join-Path $params.imagesDir "$safeFilename.tar"
                if (-not (Test-Path $imageFile)) {
                    Write-ColorOutput "[失败] 未找到容器归档文件: ${safeFilename}.tar(.gz)" $RED
                    $failed++
                    continue
                }
            }
            
            # 导入镜像
            Write-ColorOutput "[导入] $imageFile -> $image" $BLUE
            try {
                docker import $imageFile $image
                Write-ColorOutput "[成功] 导入镜像: $image" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 导入镜像: $image" $RED
                Write-Host $_.Exception.Message
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "export" {
        # 检查必要参数
        if (-not $params.imagesDir) {
            Write-ColorOutput "错误: 导出容器文件系统需要指定镜像目录 (-d|--images-dir)" $RED
            exit 1
        }
        
        # 创建输出目录
        if (-not (Test-Path $params.imagesDir)) {
            New-Item -Path $params.imagesDir -ItemType Directory -Force | Out-Null
        }
        
        Write-ColorOutput "开始导出容器文件系统到目录 $($params.imagesDir)..." $GREEN
        Write-ColorOutput "使用docker export命令导出，仅导出容器的文件系统，不含镜像历史和元数据" $BLUE
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($line in $imagesList) {
            $total++
            
            # 容器信息处理：支持容器ID:导出名称格式
            if ($line -like "*:*") {
                # 格式: container_id:export_name
                $container_id = $line.Split(':')[0]
                $export_name = $line.Split(':')[1]
            } else {
                # 只有容器ID或名称，使用相同名称导出
                $container_id = $line
                $export_name = $line
            }
            
            # 检查容器是否存在
            try {
                $null = docker inspect $container_id 2>$null
            }
            catch {
                Write-ColorOutput "[失败] 容器不存在: $container_id" $RED
                $failed++
                continue
            }
            
            # 获取安全的文件名
            $safeFilename = Get-SafeFilename $export_name
            $outputFile = Join-Path $params.imagesDir "$safeFilename.tar"
            
            # 导出容器
            Write-ColorOutput "[导出] 容器 $container_id -> $outputFile" $BLUE
            try {
                docker export $container_id -o $outputFile
                Write-ColorOutput "[成功] 导出容器: $container_id -> $outputFile" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 导出容器: $container_id" $RED
                Write-Host $_.Exception.Message
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "delete" {
        Write-ColorOutput "开始删除镜像..." $GREEN
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 处理源仓库前缀
            if ($params.sourceRegistry) {
                $fullImage = "$($params.sourceRegistry)/$image"
            }
            else {
                $fullImage = $image
            }
            
            # 检查镜像是否存在
            try {
                $null = docker inspect $fullImage 2>$null
            }
            catch {
                Write-ColorOutput "[跳过] 镜像不存在: $fullImage" $YELLOW
                continue
            }
            
            # 删除镜像
            Write-ColorOutput "[删除] $fullImage" $BLUE
            try {
                docker rmi -f $fullImage
                Write-ColorOutput "[成功] 删除镜像: $fullImage" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 删除镜像: $fullImage" $RED
                Write-Host $_.Exception.Message
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "pull" {
        # 检查必要参数
        if (-not $params.sourceRegistry) {
            Write-ColorOutput "警告: 未指定源仓库地址，将从默认的Docker Hub拉取镜像" $YELLOW
        }
        
        Write-ColorOutput "开始拉取镜像..." $GREEN
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 处理源仓库前缀
            if ($params.sourceRegistry) {
                $fullImage = "$($params.sourceRegistry)/$image"
            }
            else {
                $fullImage = $image
            }
            
            # 检查镜像是否已存在 - 更精确的检查
            $imageExists = $false
            $existingImages = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
            if ($existingImages -contains $fullImage) {
                $imageExists = $true
            }
            
            if ($imageExists) {
                Write-ColorOutput "[跳过] 镜像已存在: $fullImage" $YELLOW
                $success++
                continue
            }
            
            # 拉取镜像
            Write-ColorOutput "[拉取] $fullImage" $BLUE
            try {
                docker pull $fullImage
                Write-ColorOutput "[成功] 拉取镜像: $fullImage" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 拉取镜像: $fullImage" $RED
                if ($params.registry -or $params.sourceRegistry) {
                    Write-ColorOutput "提示: 可能需要先登录到私有仓库: " $YELLOW
                    if ($params.registry) {
                        Write-ColorOutput "    docker login $($params.registry)" $CYAN
                    }
                    if ($params.sourceRegistry) {
                        Write-ColorOutput "    docker login $($params.sourceRegistry)" $CYAN
                    }
                }
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "push" {
        # 检查必要参数
        if (-not $params.registry) {
            Write-ColorOutput "错误: 推送镜像需要指定目标仓库地址 (-r|--registry)" $RED
            exit 1
        }
        
        Write-ColorOutput "开始推送镜像到 $($params.registry)..." $GREEN
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 处理源仓库前缀
            if ($params.sourceRegistry) {
                $sourceImage = "$($params.sourceRegistry)/$image"
            }
            else {
                $sourceImage = $image
            }
            
            # 检查源镜像是否存在
            try {
                $null = docker inspect $sourceImage 2>$null
            }
            catch {
                Write-ColorOutput "[拉取] 镜像 $sourceImage 不存在，尝试拉取..." $BLUE
                try {
                    docker pull $sourceImage
                }
                catch {
                    Write-ColorOutput "[失败] 无法拉取镜像: $sourceImage" $RED
                    $failed++
                    continue
                }
            }
            
            # 提取镜像名称和标签
            if ($image -like "*:*") {
                $imageName = $image.Split(':')[0]
                $tag = $image.Split(':')[1]
            }
            else {
                $imageName = $image
                $tag = "latest"
            }
            
            # 提取原始镜像的主机地址作为目标仓库的目录
            # 如果是完整镜像名(包含主机地址)
            if (($imageName -like "*.*") -and ($imageName -like "*/*")) {
                # 提取主机部分，例如 quay.io
                $hostPart = $imageName.Split('/')[0]
                # 提取剩余部分，例如 jetstack/cert-manager-cainjector
                $remainder = $imageName.Substring($hostPart.Length + 1)
                
                # 构建目标镜像名，格式: registry.example.com/quay.io/jetstack/cert-manager-cainjector:v1.17.2
                if ($params.project) {
                    $targetImage = "$($params.registry)/$($params.project)/$hostPart/$remainder`:$tag"
                }
                else {
                    $targetImage = "$($params.registry)/$hostPart/$remainder`:$tag"
                }
            }
            else {
                # 处理没有主机地址的镜像(如Docker Hub上的镜像)
                if ($params.project) {
                    $targetImage = "$($params.registry)/$($params.project)/$imageName`:$tag"
                }
                else {
                    # 如果设置了targetRegistry则使用它，否则使用docker.io
                    $repoPrefix = "docker.io"
                    if ($params.targetRegistry) {
                        $repoPrefix = $params.targetRegistry
                    }
                    $targetImage = "$($params.registry)/$repoPrefix/$imageName`:$tag"
                }
            }
            
            # 标记镜像
            Write-ColorOutput "[标记] $sourceImage -> $targetImage" $BLUE
            try {
                docker tag $sourceImage $targetImage
            }
            catch {
                Write-ColorOutput "[失败] 无法标记镜像: $sourceImage -> $targetImage" $RED
                $failed++
                continue
            }
            
            # 推送镜像
            Write-ColorOutput "[推送] $targetImage" $BLUE
            try {
                docker push $targetImage
                Write-ColorOutput "[成功] 推送镜像: $targetImage" $GREEN
                $success++
                
                # 清理临时标记
                docker rmi $targetImage >$null 2>&1
            }
            catch {
                Write-ColorOutput "[失败] 推送镜像: $targetImage" $RED
                Write-ColorOutput "提示: 可能需要先登录到私有仓库: " $YELLOW
                Write-ColorOutput "    docker login $($params.registry)" $CYAN
                $failed++
                
                # 清理失败的标记
                docker rmi $targetImage >$null 2>&1
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
    
    "strip_registry" {
        # 必须指定registry_prefix参数用于去除前缀
        if (-not $params.registryPrefix) {
            Write-ColorOutput "错误: --strip-registry 操作必须指定要去除的仓库前缀" $RED
            Write-ColorOutput "示例: .\docker.ps1 --strip-registry registry.cn-hangzhou.aliyuncs.com -i rancher-images.txt" $YELLOW
            exit 1
        }
        
        Write-ColorOutput "开始对本地镜像进行重命名..." $GREEN
        
        # 显示使用的镜像来源
        if ($params.imageName) {
            Write-ColorOutput "使用单个镜像: $($params.imageName)" $BLUE
        } else {
            Write-ColorOutput "使用镜像列表: $($params.imageList)" $BLUE
        }
        
        # 显示目标仓库信息
        if ($params.targetRegistry) {
            Write-ColorOutput "指定目标仓库前缀: $($params.targetRegistry)" $BLUE
        }
        
        # 统计计数器
        $total = 0
        $success = 0
        $failed = 0
        
        # 处理镜像列表
        foreach ($image in $imagesList) {
            $total++
            
            # 检查是否存在指定前缀的镜像
            $prefixedImage = "$($params.registryPrefix)/$image"
            
            # 构建目标镜像名（如果指定了targetRegistry）
            if ($params.targetRegistry) {
                # 解析镜像名和标签
                if ($image -like "*:*") {
                    $imageWithoutTag = $image.Split(':')[0]
                    $tag = $image.Split(':')[1]
                } else {
                    $imageWithoutTag = $image
                    $tag = "latest"
                }
                
                # 构建带目标仓库前缀的镜像名
                $targetImage = "$($params.targetRegistry)/${imageWithoutTag}:${tag}"
                Write-ColorOutput "[目标] 重命名为: $targetImage" $BLUE
            } else {
                $targetImage = $image
            }
            
            # 检查镜像是否存在
            try {
                $null = docker inspect $prefixedImage 2>$null
            }
            catch {
                Write-ColorOutput "[失败] 镜像 $prefixedImage 不存在，无法重命名" $RED
                $failed++
                continue
            }
            
            # 重命名镜像（使用tag和删除原镜像的方式）
            Write-ColorOutput "[重命名] $prefixedImage -> $targetImage" $BLUE
            try {
                docker tag $prefixedImage $targetImage
                docker rmi $prefixedImage -f
                Write-ColorOutput "[成功] 重命名镜像: $prefixedImage -> $targetImage" $GREEN
                $success++
            }
            catch {
                Write-ColorOutput "[失败] 重命名镜像: $prefixedImage" $RED
                Write-Host $_.Exception.Message
                $failed++
            }
        }
        
        Write-ColorOutput "完成!" $GREEN
        Write-Host "总共: $total, 成功: $success, 失败: $failed"
    }
}
