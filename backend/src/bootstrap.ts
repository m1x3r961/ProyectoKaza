import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { AppModule } from './app.module';
import { configuration } from './config';
import { ErrorFilter } from './security/error.filter';
export async function createApp() {
 const config = configuration();
 const app = await NestFactory.create(AppModule, { bodyParser: false });
 const express = require('express');
 app.use(express.json({ limit: '128kb' }));
 app.enableCors({ origin: config.origins, methods: ['GET','POST','PATCH','DELETE','OPTIONS'], allowedHeaders: ['Authorization','Content-Type','Idempotency-Key'], credentials: false });
 app.use((req: any, res: any, next: () => void) => {
   req.requestId = randomUUID(); res.setHeader('X-Request-Id', req.requestId);
   res.setHeader('X-Content-Type-Options', 'nosniff'); res.setHeader('Cache-Control', 'no-store');
   const started = Date.now(); res.on('finish', () => console.log(JSON.stringify({ requestId: req.requestId, method: req.method, status: res.statusCode, durationMs: Date.now()-started })));
   next();
 });
 app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
 app.useGlobalFilters(new ErrorFilter());
 return app;
}
