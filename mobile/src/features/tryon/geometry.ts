import type { FaceLandmark } from "../../../modules/glow-face";
export type Point = { x: number; y: number };
export function containTransform(
  imageWidth: number,
  imageHeight: number,
  viewWidth: number,
  viewHeight: number,
) {
  if (
    [imageWidth, imageHeight, viewWidth, viewHeight].some(
      (v) => !Number.isFinite(v) || v <= 0,
    )
  )
    throw new Error("Invalid image dimensions");
  const scale = Math.min(viewWidth / imageWidth, viewHeight / imageHeight);
  return {
    scale,
    x: (viewWidth - imageWidth * scale) / 2,
    y: (viewHeight - imageHeight * scale) / 2,
    width: imageWidth * scale,
    height: imageHeight * scale,
  };
}
export function transformLandmark(
  point: Point,
  imageWidth: number,
  imageHeight: number,
  viewWidth: number,
  viewHeight: number,
) {
  const t = containTransform(imageWidth, imageHeight, viewWidth, viewHeight);
  return { x: t.x + point.x * t.width, y: t.y + point.y * t.height };
}
export function landmarkPoints(
  landmarks: FaceLandmark[],
  indices: number[],
  width: number,
  height: number,
): Point[] {
  return indices.map((i) => ({
    x: landmarks[i].x * width,
    y: landmarks[i].y * height,
  }));
}
