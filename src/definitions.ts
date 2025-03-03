export interface GalleryEnginePlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  loadTensorFromDB(options: { emptyArg: number }): Promise<void>;
  offloadTensor(options: { emptyArg: number }): Promise<void>;
  calculateCosineSimilarity(options: { tensorArray: number[] }): Promise<{ prob: number[] }>;
}
