import * as Picker from "expo-image-picker";
import { ImageManipulator, SaveFormat } from "expo-image-manipulator";
import { File, Paths } from "expo-file-system";
import type { Photo } from "../../types";
export async function pickPhoto(camera = false): Promise<Photo | undefined> {
  if (camera) {
    const permission = await Picker.requestCameraPermissionsAsync();
    if (!permission.granted)
      throw new Error(
        "Camera access is off. Enable it in Android Settings, or choose from your gallery.",
      );
  }
  const options: Picker.ImagePickerOptions = {
    mediaTypes: ["images"],
    quality: 1,
    allowsEditing: false,
    exif: false,
  };
  const result = camera
    ? await Picker.launchCameraAsync(options)
    : await Picker.launchImageLibraryAsync(options);
  if (result.canceled) return;
  const source = result.assets[0];
  const context = ImageManipulator.manipulate(source.uri);
  if (Math.max(source.width, source.height) > 1600)
    context.resize(
      source.width > source.height ? { width: 1600 } : { height: 1600 },
    );
  const image = await context.renderAsync();
  const normalized = await image.saveAsync({
    format: SaveFormat.JPEG,
    compress: 0.9,
  });
  const target = new File(Paths.cache, `glow-portrait-${Date.now()}.jpg`);
  new File(normalized.uri).move(target);
  return {
    uri: target.uri,
    width: normalized.width,
    height: normalized.height,
  };
}
export function removePhoto(photo?: Photo) {
  if (
    photo?.uri.startsWith(Paths.cache.uri) &&
    photo.uri.includes("glow-portrait-")
  ) {
    try {
      const file = new File(photo.uri);
      if (file.exists) file.delete();
    } catch {
      /* OS may already have cleared cache. */
    }
  }
}
export function clearOldPhotos() {
  try {
    for (const file of Paths.cache.list())
      if (file instanceof File && /^glow-(portrait|export)-/.test(file.name))
        file.delete();
  } catch {
    /* Cache cleanup is best effort. */
  }
}
