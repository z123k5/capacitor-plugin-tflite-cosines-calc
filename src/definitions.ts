export interface GalleryEnginePlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
