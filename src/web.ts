import { WebPlugin } from '@capacitor/core';

import type { GalleryEnginePlugin } from './definitions';

export class GalleryEngineWeb extends WebPlugin implements GalleryEnginePlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }

  async loadTensorFromDB(): Promise<void> {
    console.error('Not Implemented on web: loadTensorFromDB');
  }

  async offloadTensor(): Promise<void> {
    console.error('Not Implemented on web: offloadTensor');
  }

  async calculateCosineSimilarity(options: { tensorArray: number[] }): Promise<{
    prob: number[]
  }> {
    console.error('Not Implemented on web: calculateCosineSimilarity', options);
    return { prob: options.tensorArray };
  }
}
