import { test } from "node:test";
import assert from "node:assert/strict";
import { recommendationSchema, type UserProfileInput } from "../src/types";
import { normalizeHex, safeHex } from "../src/utils/color";
import { validateProfile } from "../src/features/analysis/validation";
import { parseRecommendation } from "../src/services/api";
import {
  containTransform,
  transformLandmark,
} from "../src/features/tryon/geometry";
import fixture from "./fixtures/curated.json";
import { makeupSchema, recommendedMakeup } from "../src/features/tryon/config";
import {
  localRecommendation,
  OFFLINE_VARIANT_COUNT,
} from "../src/services/localRecommendation";
import { occasions } from "../src/constants/options";
const profile: UserProfileInput = {
  skin_tone: "medium",
  undertone: "warm",
  skin_type: "normal",
  event: "eid",
  time_of_day: "day",
  outfit_color: "#d4a0c0",
  hijab: "yes",
  style_preference: "traditional",
  owned_items: "",
};
test("hex colours normalize and reject invalid input", () => {
  assert.equal(normalizeHex(" abc "), "#AABBCC");
  assert.equal(normalizeHex("#e07a7a"), "#E07A7A");
  for (const invalid of ["red", "#GG1122", "#12345", "#12345678", ""])
    assert.equal(normalizeHex(invalid), null);
  assert.equal(safeHex(null, "#000000"), "#000000");
});
test("consultation validates required fields but allows AI tone estimate", () => {
  assert.equal(validateProfile(profile, false), null);
  assert.match(
    validateProfile({ ...profile, skin_tone: "" }, false)!,
    /skin tone/,
  );
  assert.equal(validateProfile({ ...profile, skin_tone: "" }, true), null);
  assert.ok(validateProfile({ ...profile, event: "" }, true));
  assert.ok(validateProfile({ ...profile, outfit_color: "bad color" }, true));
  assert.ok(
    validateProfile({ ...profile, owned_items: "x".repeat(2001) }, true),
  );
});
test("malformed API payloads never become recommendations", () => {
  for (const raw of [
    null,
    {},
    [],
    { status: "success" },
    { status: "success", face: "bad" },
  ])
    assert.throws(() => parseRecommendation(raw), /incomplete/);
});
test("portrait and landscape contain transforms preserve coordinates", () => {
  assert.deepEqual(containTransform(800, 1600, 400, 400), {
    scale: 0.25,
    x: 100,
    y: 0,
    width: 200,
    height: 400,
  });
  assert.deepEqual(transformLandmark({ x: 0.5, y: 0.5 }, 1600, 800, 400, 400), {
    x: 200,
    y: 200,
  });
  assert.deepEqual(transformLandmark({ x: 0, y: 1 }, 800, 1600, 400, 400), {
    x: 100,
    y: 400,
  });
  assert.throws(() => containTransform(0, 10, 100, 100));
});
test("real backend curated response parses and preserves recommendation colours", () => {
  const result = parseRecommendation(fixture);
  assert.equal(result.status, "fallback");
  const config = recommendedMakeup(result);
  assert.equal(config.lipstick.color, normalizeHex(result.lips.hex));
  assert.equal(config.blush.color, normalizeHex(result.face.blush_hex));
  assert.equal(config.eyeshadow.color, normalizeHex(result.eyes.eyeshadow_hex));
  assert.equal(config.eyeliner.color, normalizeHex(result.eyes.eyeliner_hex));
  assert.ok(makeupSchema.safeParse(config).success);
});
test("offline catalogue covers every consultation occasion", () => {
  for (const [event] of occasions) {
    const result = localRecommendation({ ...profile, event });
    assert.equal(result.status, "fallback");
    assert.equal(recommendationSchema.safeParse(result).success, true);
    assert.match(result.overall_tip, new RegExp(event === "everyday" ? "everyday" : "look|designed"));
  }
  assert.ok(OFFLINE_VARIANT_COUNT > 1_000_000);
});
test("offline responses vary with meaningful profile combinations", () => {
  const base = localRecommendation(profile);
  const evening = localRecommendation({ ...profile, event: "party", time_of_day: "night", skin_type: "oily", style_preference: "western" });
  assert.notEqual(base.overall_tip, evening.overall_tip);
  assert.notEqual(base.face.foundation, evening.face.foundation);
  assert.notEqual(base.lips.hex, evening.lips.hex);
});
test("makeup controls reject unsafe colours, intensity and unsupported finishes", () => {
  const config = recommendedMakeup();
  assert.equal(
    makeupSchema.safeParse({
      ...config,
      lipstick: { ...config.lipstick, intensity: 1.1 },
    }).success,
    false,
  );
  assert.equal(
    makeupSchema.safeParse({
      ...config,
      lipstick: { ...config.lipstick, finish: "plastic" },
    }).success,
    false,
  );
  assert.equal(
    makeupSchema.safeParse({
      ...config,
      eyeliner: { ...config.eyeliner, color: "red" },
    }).success,
    false,
  );
  const next = recommendedMakeup();
  next.blush.enabled = false;
  assert.equal(config.blush.enabled, true);
});
