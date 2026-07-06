# Models

Two Core ML models are bundled, picked automatically via `UpscalerProvider`'s
model picker (Settings, or the app-level environment) — both
[Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) conversions,
BSD-3-Clause. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the
license text and [`convert/`](convert/) for the (now parameterized, one
script covers both) conversion pipeline.

| File | Source | RRDB blocks | Best for |
|---|---|---|---|
| `RealESRGAN.mlpackage` | `RealESRGAN_x4plus.pth` | 23 | General photos (default) |
| `RealESRGANAnime.mlpackage` | `RealESRGAN_x4plus_anime_6B.pth` | 6 (smaller/faster) | Anime/illustration art |

**Not verified end-to-end.** Both conversions (`torch.jit.trace` →
`coremltools.convert`) produce a `.mlpackage` with the right input/output
shapes, and the underlying PyTorch model + weights were checked separately
for each (ran the un-converted model on a real photo, got a plausible
sharper/higher-res result, no NaNs) — but neither compiled Core ML model has
been run on-device or in Xcode's simulator, since that requires macOS. Build
and try them on a real photo before trusting the output; if something looks
wrong, that's the first place to look.

**Performance:** the general model (23 blocks) is the highest-quality but
heaviest config — test on a physical device, not the simulator. The anime
model (6 blocks) is noticeably smaller (~9MB vs ~33MB) and should run
faster per tile. Neural Engine inference should be reasonably fast either
way; CPU-only fallback will be slow per 128x128 tile, multiplied by however
many tiles a full photo needs.

## Swapping in a different model

Change `UpscaleModelChoice` in `UpscalerProvider.swift` to match (add a
case, or repoint an existing one's `modelName`). Two ways to get another
model:

1. **Find one already converted** — search for "coreml" alongside the
   model name; check its license before shipping it.
2. **Convert one yourself** — see [`convert/`](convert/); `convert.py`
   takes `--weights`/`--num-block`/`--out`/`--description` so the same
   script covers any RRDBNet-architecture Real-ESRGAN checkpoint. For a
   genuinely different architecture, adapt it: trace the PyTorch model at a
   fixed input size with `torch.jit.trace`, then
   `coremltools.convert(..., inputs=[ct.ImageType(...)],
   outputs=[ct.ImageType(...)])` so the compiled model takes/returns
   `CVPixelBuffer`s directly — that's what lets `CoreMLTileUpscaler` use
   `VNCoreMLRequest`/`VNPixelBufferObservation` without manual pixel-format
   handling. Bake any output denormalization (e.g. clamp + scale back to
   0-255) into the traced graph itself, since output `ImageType` doesn't
   apply scale/bias the way input `ImageType` does.

## Matching `CoreMLTileUpscaler.Config`

| Config field | Must equal |
|---|---|
| `tileSize` | The model's fixed input width/height, in pixels (128 for both bundled models) |
| `scaleFactor` | The model's output size ÷ input size (4 for both bundled models) |
| `overlap` | Your choice — context pixels fed to the model beyond what's kept; 8-16 is reasonable for a 128px tile (see `UpscaleQuality`'s Standard/Best presets) |
