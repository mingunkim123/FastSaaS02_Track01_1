import { createClient } from '@libsql/client';
import { readFileSync } from 'fs';

// .dev.vars 읽기
const vars = {};
readFileSync('.dev.vars', 'utf8').split('\n').forEach(l => {
    if (l && !l.startsWith('#')) {
        const idx = l.indexOf('=');
        vars[l.slice(0, idx).trim()] = l.slice(idx + 1).trim();
    }
});

const db = createClient({ url: vars.TURSO_DB_URL, authToken: vars.TURSO_AUTH_TOKEN });

async function run() {
    const tables = await db.execute("SELECT name FROM sqlite_master WHERE type='table'");
    console.log('현재 테이블:', tables.rows.map(r => r.name));

    if (!tables.rows.find(r => r.name === 'chat_messages')) {
        console.log('chat_messages 테이블 없음 - 생성 중...');
        await db.execute(`CREATE TABLE chat_messages (
      id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
      user_id text NOT NULL,
      role text NOT NULL,
      content text NOT NULL,
      metadata text,
      created_at text DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`);
        console.log('✅ chat_messages 테이블 생성 완료!');
    } else {
        console.log('✅ chat_messages 테이블 이미 존재함');
    }
}

run().catch(e => console.error('에러:', e.message));
