#!/usr/bin/env python3
"""
云原生DevOps平台 - 示例应用后端
Flask REST API with PostgreSQL
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
import os
import redis
from datetime import datetime
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# 数据库配置
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'demo_app'),
    'user': os.getenv('DB_USER', 'demo'),
    'password': os.getenv('DB_PASSWORD', 'demo123')
}

# Redis配置
REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
REDIS_PORT = int(os.getenv('REDIS_PORT', '6379'))

# 初始化Redis连接
try:
    redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
    redis_client.ping()
    logger.info("Redis连接成功")
except Exception as e:
    logger.error(f"Redis连接失败: {e}")
    redis_client = None


def get_db_connection():
    """获取数据库连接"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"数据库连接失败: {e}")
        return None


def init_db():
    """初始化数据库表"""
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    id SERIAL PRIMARY KEY,
                    content TEXT NOT NULL,
                    author VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.commit()
            cursor.close()
            logger.info("数据库表初始化成功")
        except Exception as e:
            logger.error(f"数据库初始化失败: {e}")
        finally:
            conn.close()


@app.route('/')
def index():
    """首页"""
    return jsonify({
        'service': 'DevOps Demo App API',
        'version': '1.0.0',
        'status': 'running',
        'timestamp': datetime.now().isoformat()
    })


@app.route('/health')
def health():
    """健康检查"""
    health_status = {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'checks': {}
    }
    
    # 检查数据库
    conn = get_db_connection()
    if conn:
        health_status['checks']['database'] = 'ok'
        conn.close()
    else:
        health_status['checks']['database'] = 'error'
        health_status['status'] = 'unhealthy'
    
    # 检查Redis
    if redis_client:
        try:
            redis_client.ping()
            health_status['checks']['redis'] = 'ok'
        except:
            health_status['checks']['redis'] = 'error'
    else:
        health_status['checks']['redis'] = 'unavailable'
    
    return jsonify(health_status)


@app.route('/api/messages', methods=['GET'])
def get_messages():
    """获取所有消息"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': '数据库连接失败'}), 500
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id, content, author, created_at FROM messages ORDER BY created_at DESC LIMIT 100")
        messages = []
        for row in cursor.fetchall():
            messages.append({
                'id': row[0],
                'content': row[1],
                'author': row[2],
                'created_at': row[3].isoformat() if row[3] else None
            })
        cursor.close()
        return jsonify(messages)
    except Exception as e:
        logger.error(f"获取消息失败: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/messages', methods=['POST'])
def create_message():
    """创建新消息"""
    data = request.get_json()
    if not data or 'content' not in data:
        return jsonify({'error': '缺少消息内容'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': '数据库连接失败'}), 500

    try:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO messages (content, author) VALUES (%s, %s) RETURNING id",
            (data['content'], data.get('author', 'Anonymous'))
        )
        message_id = cursor.fetchone()[0]
        conn.commit()
        cursor.close()

        # 增加访问计数（使用Redis）
        if redis_client:
            redis_client.incr('message_count')

        return jsonify({
            'id': message_id,
            'message': '消息创建成功'
        }), 201
    except Exception as e:
        logger.error(f"创建消息失败: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/stats')
def get_stats():
    """获取统计信息"""
    stats = {
        'timestamp': datetime.now().isoformat()
    }

    # 从Redis获取访问计数
    if redis_client:
        try:
            stats['message_count'] = int(redis_client.get('message_count') or 0)
            stats['redis_status'] = 'connected'
        except:
            stats['redis_status'] = 'error'

    # 从数据库获取消息总数
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM messages")
            stats['total_messages'] = cursor.fetchone()[0]
            cursor.close()
        except Exception as e:
            logger.error(f"获取统计失败: {e}")
        finally:
            conn.close()

    return jsonify(stats)


if __name__ == '__main__':
    # 初始化数据库
    init_db()

    # 启动应用
    port = int(os.getenv('PORT', '5000'))
    app.run(host='0.0.0.0', port=port, debug=False)

