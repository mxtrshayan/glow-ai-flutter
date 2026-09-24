import { useEffect, useState } from "react";
import { detectFace, type FaceDetection } from "../../../modules/glow-face";
// Cache only the current portrait; never detect again for shade/intensity changes.
let cached: { uri: string; promise: Promise<FaceDetection> } | undefined;
export function useFace(uri: string) {
  const [state, setState] = useState<{ face?: FaceDetection; error?: string }>(
    {},
  );
  useEffect(() => {
    let active = true;
    if (cached?.uri !== uri) cached = { uri, promise: detectFace(uri) };
    cached.promise
      .then((face) => {
        if (active)
          setState({
            face,
            error:
              face.status === "no_face"
                ? "No face found. Choose a clear, front-facing portrait."
                : face.status === "multiple_faces"
                  ? "We found more than one face. Choose a portrait of just you."
                  : undefined,
          });
      })
      .catch(() => {
        if (cached?.uri === uri) cached = undefined;
        if (active)
          setState({
            error:
              "Face detection could not start. Choose another clear portrait and try again.",
          });
      });
    return () => {
      active = false;
    };
  }, [uri]);
  return { ...state, busy: !state.face && !state.error };
}
