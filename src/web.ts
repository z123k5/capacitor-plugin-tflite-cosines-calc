import { WebPlugin } from '@capacitor/core';

import type { GalleryEnginePlugin } from './definitions';

export class GalleryEngineWeb extends WebPlugin implements GalleryEnginePlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
