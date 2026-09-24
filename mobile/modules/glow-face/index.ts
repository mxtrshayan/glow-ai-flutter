import { requireOptionalNativeModule } from "expo-modules-core";
export type FaceLandmark = { x: number; y: number; z: number };
export type FaceDetection =
  | {
      status: "success";
      width: number;
      height: number;
      landmarks: FaceLandmark[];
    }
  | { status: "no_face" | "multiple_faces"; landmarks: [] };
const native = requireOptionalNativeModule<{
  detect(uri: string): Promise<FaceDetection>;
}>("GlowFace");
export async function detectFace(uri: string): Promise<FaceDetection> {
  if (!native)
    throw new Error("Local makeup needs the GlowAI Android development build.");
  try {
    return await native.detect(uri);
  } catch {
    throw new Error(
      "We could not read this portrait. Choose a clear JPG or PNG and try again.",
    );
  }
}
