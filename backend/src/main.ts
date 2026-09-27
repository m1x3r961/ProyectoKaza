import { createApp } from './bootstrap';
import { configuration } from './config';
createApp().then(app => app.listen(configuration().port));
