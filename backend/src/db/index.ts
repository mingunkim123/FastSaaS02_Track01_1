// backend/src/db/index.ts
import { drizzle } from 'drizzle-orm/libsql';
import { createClient, type Client } from '@libsql/client';
import * as schema from './schema';

export type Env = {
    TURSO_DB_URL: string;
    TURSO_AUTH_TOKEN: string;
    SUPABASE_JWT_SECRET: string;
    SUPABASE_URL: string;
    // GROQ_API_KEY: string;
    // GROQ_MODEL_NAME?: string;
    GEMINI_API_KEY?: string;
    GEMINI_MODEL_NAME?: string;
    AI_PROVIDER?: 'gemini' | 'workers-ai'; // defaults to 'workers-ai'
    AI?: any; // Cloudflare Workers AI binding
    VECTORIZE?: any; // Cloudflare Vectorize binding (optional)
    CLOUDFLARE_ACCOUNT_ID?: string; // For Vectorize API calls
    CLOUDFLARE_API_TOKEN?: string; // For Vectorize API authentication
    ALLOWED_ORIGINS?: string; // Comma-separated list of allowed CORS origins
    ENVIRONMENT?: string; // e.g. 'development' | 'production'
};

export function createDb(client: Client) {
    // Drizzle ORM으로 타입 안전한 쿼리 작성 가능하게 래핑
    return drizzle(client, { schema });
}

export function getDb(env: Env) {
    // Turso(SQLite 호스팅 서비스)에 연결하기 위한 클라이언트 생성
    const client = createClient({
        url: env.TURSO_DB_URL,
        authToken: env.TURSO_AUTH_TOKEN,
    });
    return createDb(client);
}
