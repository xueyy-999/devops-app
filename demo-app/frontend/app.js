// 云原生DevOps平台 - 前端应用
const API_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5001' 
    : 'http://backend:5000';

// 更新时间戳
function updateTimestamp() {
    const now = new Date();
    document.getElementById('timestamp').textContent = now.toLocaleString('zh-CN');
}

// 检查系统健康状态
async function checkHealth() {
    try {
        const response = await fetch(`${API_URL}/health`);
        const data = await response.json();
        
        // 更新API状态
        const apiStatus = document.getElementById('api-status');
        apiStatus.textContent = data.status === 'healthy' ? '正常' : '异常';
        apiStatus.className = 'status-value ' + (data.status === 'healthy' ? 'ok' : 'error');
        
        // 更新数据库状态
        if (data.checks && data.checks.database) {
            const dbStatus = document.getElementById('db-status');
            dbStatus.textContent = data.checks.database === 'ok' ? '已连接' : '连接失败';
            dbStatus.className = 'status-value ' + (data.checks.database === 'ok' ? 'ok' : 'error');
        }
        
        // 更新Redis状态
        if (data.checks && data.checks.redis) {
            const redisStatus = document.getElementById('redis-status');
            redisStatus.textContent = data.checks.redis === 'ok' ? '已连接' : '连接失败';
            redisStatus.className = 'status-value ' + (data.checks.redis === 'ok' ? 'ok' : 'error');
        }
    } catch (error) {
        console.error('健康检查失败:', error);
        document.getElementById('api-status').textContent = '离线';
        document.getElementById('api-status').className = 'status-value error';
    }
}

// 获取统计信息
async function getStats() {
    try {
        const response = await fetch(`${API_URL}/api/stats`);
        const data = await response.json();
        
        if (data.total_messages !== undefined) {
            document.getElementById('message-count').textContent = data.total_messages;
        }
    } catch (error) {
        console.error('获取统计失败:', error);
    }
}

// 加载消息列表
async function loadMessages() {
    const messagesDiv = document.getElementById('messages');
    
    try {
        const response = await fetch(`${API_URL}/api/messages`);
        const messages = await response.json();
        
        if (messages.length === 0) {
            messagesDiv.innerHTML = '<p class="loading">暂无留言，快来发表第一条吧！</p>';
            return;
        }
        
        messagesDiv.innerHTML = messages.map(msg => `
            <div class="message-item">
                <div class="message-header">
                    <span class="message-author">${escapeHtml(msg.author || 'Anonymous')}</span>
                    <span class="message-time">${formatTime(msg.created_at)}</span>
                </div>
                <div class="message-content">${escapeHtml(msg.content)}</div>
            </div>
        `).join('');
    } catch (error) {
        console.error('加载消息失败:', error);
        messagesDiv.innerHTML = '<p class="error">加载失败，请检查后端服务是否正常运行</p>';
    }
}

// 提交新消息
async function submitMessage(event) {
    event.preventDefault();
    
    const author = document.getElementById('author').value;
    const content = document.getElementById('content').value;
    
    try {
        const response = await fetch(`${API_URL}/api/messages`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ author, content })
        });
        
        if (response.ok) {
            // 清空表单
            document.getElementById('message-form').reset();
            
            // 重新加载消息
            await loadMessages();
            await getStats();
            
            alert('留言发送成功！');
        } else {
            alert('留言发送失败，请重试');
        }
    } catch (error) {
        console.error('提交消息失败:', error);
        alert('网络错误，请检查后端服务');
    }
}

// HTML转义，防止XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// 格式化时间
function formatTime(isoString) {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toLocaleString('zh-CN');
}

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    // 更新时间戳
    updateTimestamp();
    setInterval(updateTimestamp, 1000);
    
    // 检查健康状态
    checkHealth();
    setInterval(checkHealth, 30000); // 每30秒检查一次
    
    // 加载消息
    loadMessages();
    getStats();
    
    // 绑定表单提交事件
    document.getElementById('message-form').addEventListener('submit', submitMessage);
    
    // 每10秒自动刷新消息
    setInterval(() => {
        loadMessages();
        getStats();
    }, 10000);
});

