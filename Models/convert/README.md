# Converting Real-ESRGAN to Core ML

Reproduces all four `../*.mlpackage` files. Requires Python 3.11
(coremltools 9.0 at time of writing doesn't yet support 3.13) and works on
Linux or macOS — only the final `.mlpackage` → `.mlmodelc` compile step
needs Xcode. Tested with `torch==2.7.0` specifically (coremltools 9.0's
last-verified version at time of writing); a newer `torch` will still
convert but prints a compatibility warning.

```bash
python3.11 -m venv venv
source venv/bin/activate
pip install coremltools
pip install "torch==2.7.0" --index-url https://download.pytorch.org/whl/cpu

# Weights from the official releases (BSD-3-Clause, see ../THIRD_PARTY_NOTICES.md)
curl -sL https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -o RealESRGAN_x4plus.pth
curl -sL https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth -o RealESRGAN_x4plus_anime_6B.pth
curl -sL https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.1/RealESRNet_x4plus.pth -o RealESRNet_x4plus.pth
curl -sL https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth -o realesr-general-x4v3.pth

# General photo model (23 RRDB blocks — the default args)
python3 convert.py --weights RealESRGAN_x4plus.pth --num-block 23 \
    --out RealESRGAN.mlpackage --description "Real-ESRGAN x4plus"

# Anime/illustration model (6 blocks — smaller & faster)
python3 convert.py --weights RealESRGAN_x4plus_anime_6B.pth --num-block 6 \
    --out RealESRGANAnime.mlpackage --description "Real-ESRGAN x4plus anime_6B"

# Portrait model — same RRDBNet architecture as x4plus, trained without a
# GAN loss, so it lands smoother/lower-artifact rather than sharper
python3 convert.py --weights RealESRNet_x4plus.pth --num-block 23 \
    --out RealESRNet.mlpackage --description "Real-ESRGAN RealESRNet_x4plus"

# Fast & Clean model — different architecture (SRVGGNetCompact, --arch srvgg)
python3 convert.py --weights realesr-general-x4v3.pth --arch srvgg --num-conv 32 \
    --out RealESRGeneralV3.mlpackage --description "Real-ESRGAN realesr-general-x4v3"
```

`rrdbnet.py` is the RRDBNet architecture (the `x4plus`/`anime_6B`/
`RealESRNet_x4plus` models) copied out of `xinntao/BasicSR`'s
`basicsr/archs/rrdbnet_arch.py`, with the `basicsr` package dependency
stripped out — the full `basicsr`/`realesrgan` pip packages pull in
`torchvision.transforms.functional_tensor`, which was removed in current
torchvision and breaks on import. Since we only need inference with
pretrained weights (not training), the only real dependency was
`make_layer`, which is a few lines and easy to inline; the
`default_init_weights` and `pixel_unshuffle` helpers the original file
imports are either irrelevant at inference time or dead code for the x4plus
(scale=4) configuration specifically.

`srvgg_arch.py` is the SRVGGNetCompact architecture (the
`realesr-general-x4v3` model) copied out of `xinntao/Real-ESRGAN`'s
`realesrgan/archs/srvgg_arch.py`, same treatment — the `ARCH_REGISTRY`
decorator/import is the only thing stripped, since it's only used for
name-based lookup during training. `convert.py` picks the checkpoint's
`params_ema` key if present (RRDBNet checkpoints) or falls back to `params`
(SRVGGNetCompact checkpoints have no EMA weights).

`convert.py` wraps the raw model to bake Real-ESRGAN's pixel-range
convention into the graph: input `ImageType(scale=1/255)` divides the
incoming 0-255 image down to the `[0,1]` range the model expects, and the
wrapper clamps + multiplies the model's output back up to `[0,255]` before
it's declared as an output `ImageType` — so the compiled model takes and
returns plain images with no manual normalization needed on the Swift side.
