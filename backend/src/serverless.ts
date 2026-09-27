import { createApp } from './bootstrap';
let ready: ReturnType<typeof createApp>;
export default async function handler(req: any, res: any) {
 ready ??= createApp().then(async app => { await app.init(); return app; });
 const app = await ready; app.getHttpAdapter().getInstance()(req, res);
}
