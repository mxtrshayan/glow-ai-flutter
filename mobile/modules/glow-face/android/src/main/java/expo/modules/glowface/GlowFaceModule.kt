package expo.modules.glowface

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.core.RunningMode
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File

/** Geometry only. No network, identity matching, or photo persistence. */
class GlowFaceModule : Module() {
  private var landmarker: FaceLandmarker? = null
  private val lock = Any()

  override fun definition() = ModuleDefinition {
    Name("GlowFace")
    AsyncFunction("detect") { uri: String ->
      synchronized(lock) {
        val context = appContext.reactContext ?: throw IllegalStateException("Face detector unavailable")
        val parsed = Uri.parse(uri)
        require(parsed.scheme == "file") { "Choose a local portrait." }
        val file = File(parsed.path ?: "")
        require(file.canonicalPath.startsWith(context.cacheDir.canonicalPath + File.separator)) { "Choose a photo using the app photo picker." }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0 && bounds.outWidth.toLong() * bounds.outHeight <= 25_000_000) { "This photo could not be opened." }
        val original = BitmapFactory.decodeFile(file.path) ?: throw IllegalArgumentException("This photo could not be opened.")
        val exif = ExifInterface(file)
        val matrix = Matrix().apply {
          if (exif.isFlipped) postScale(-1f, 1f)
          postRotate(exif.rotationDegrees.toFloat())
        }
        val bitmap = Bitmap.createBitmap(original, 0, 0, original.width, original.height, matrix, true)
        try {
          if (landmarker == null) {
            val base = BaseOptions.builder().setModelAssetPath("face_landmarker.task").build()
            landmarker = FaceLandmarker.createFromOptions(context,
              FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(base).setRunningMode(RunningMode.IMAGE)
                .setNumFaces(2).setMinFaceDetectionConfidence(0.5f)
                .setMinFacePresenceConfidence(0.5f).build())
          }
          val image = BitmapImageBuilder(bitmap).build()
          val faces = try { landmarker!!.detect(image).faceLandmarks() } finally { image.close() }
          when {
            faces.isEmpty() -> mapOf("status" to "no_face", "landmarks" to emptyList<Any>())
            faces.size > 1 -> mapOf("status" to "multiple_faces", "landmarks" to emptyList<Any>())
            else -> mapOf("status" to "success", "width" to bitmap.width, "height" to bitmap.height,
              "landmarks" to faces[0].map { mapOf("x" to it.x(), "y" to it.y(), "z" to it.z()) })
          }
        } finally {
          if (bitmap !== original) bitmap.recycle()
          original.recycle()
        }
      }
    }
    OnDestroy { synchronized(lock) { landmarker?.close(); landmarker = null } }
  }
}
