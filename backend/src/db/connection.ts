import { Pool } from 'pg'

// Railway 內部主機（*.railway.internal）走內網、不使用 SSL；
// 對外連線（含本機指向公開 DB）才啟用 SSL。
const url = process.env.DATABASE_URL ?? ''
const useSsl = url.length > 0 && !url.includes('railway.internal') && !url.includes('localhost')

const pool = new Pool({
  connectionString: url || undefined,
  ssl: useSsl ? { rejectUnauthorized: false } : false,
})

export default pool
