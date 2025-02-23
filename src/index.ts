import { registerPlugin } from '@capacitor/core';

import type { GalleryEnginePlugin } from './definitions';

const GalleryEngine = registerPlugin<GalleryEnginePlugin>('GalleryEngine', {
  web: () => import('./web').then((m) => new m.GalleryEngineWeb()),
});

export * from './definitions';
export { GalleryEngine };
