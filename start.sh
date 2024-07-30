echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
# 更新软件源并升级系统软件
sudo apt update -y

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    # 如果 Docker 未安装，则进行安装
    echo "未检测到 Docker，正在安装..."
    sudo apt-get install ca-certificates curl gnupg lsb-release -y

    # 添加 Docker 官方 GPG 密钥
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 授权 Docker 文件
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update -y

    # 安装 Docker 最新版本
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
else
    echo "Docker 已安装。"
fi

# 克隆或更新 nwaku-compose 项目
if [ -d "nwaku-compose" ]; then
    echo "更新 nwaku-compose 项目..."
    cd nwaku-compose || { echo "进入 nwaku-compose 目录失败，请检查错误信息。"; exit 1; }
    git stash push --include-untracked
    git pull origin master
    cd ..
else
    echo "克隆 nwaku-compose 项目 ..."
    git clone https://github.com/waku-org/nwaku-compose
fi

# 进入 nwaku-compose 目录
cd nwaku-compose

echo "成功进入 nwaku-compose 目录。"

# 复制 .env.example 到 .env
cp .env.example .env

echo "成功复制 .env.example 到 .env 文件。"

# 编辑 .env 文件
echo "现在开始编辑 .env 文件"
read -p "请输入你的api_key: " api_key
read -p "请输入你的钱包私钥: " wallet_pubkey
read -p "请输入你的rln密码，自定义即可: " rln_password
sed -i "s|^RLN_RELAY_ETH_CLIENT_ADDRESS=https://sepolia.infura.io/v3/<key>|RLN_RELAY_ETH_CLIENT_ADDRESS=https://sepolia.infura.io/v3/$api_key|g" .env
sed -i "s|^ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$wallet_pubkey|" .env
sed -i "s|^RLN_RELAY_CRED_PASSWORD=\"my_secure_keystore_password\"|RLN_RELAY_CRED_PASSWORD=\"$rln_password\"|g" .env

echo ".env 文件编辑完成。"

# 执行 register_rln.sh 脚本
echo "正在执行 register_rln.sh 脚本..."
./register_rln.sh

echo "register_rln.sh 脚本执行完成。"

# 启动 Docker Compose 服务
echo "启动 Docker Compose 服务..."
docker-compose up -d

echo "Docker Compose 服务启动完成。"
echo "waku启动完成。"
