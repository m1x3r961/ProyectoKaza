import { NestFactory } from '@nestjs/core';
import { createApp } from './bootstrap';
import { configuration } from './config';
// Vercel detects NestJS through a direct import in this entrypoint.
createApp(NestFactory).then(app => app.listen(configuration().port));
