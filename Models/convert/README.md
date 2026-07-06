# Converting Real-ESRGAN to Core ML

Reproduces `../RealESRGAN.mlpackage` and `../RealESRGANAnime.mlpackage`.
Requires Python 3.11 (coremltools 9.0 at time of writing doesn't yet
support 3.13) and works on Linux or macOS — only the final `.mlpackage` →
`.mlmodelc` compile step needs Xcode.

```bash
python3.11 -m venv venv
source venv/bin/activate
pip install coremltools torch --index-url https://download.pytorch.org/whl/cpu

# Weights from the official releases (BSD-3-Clause, see ../THIRD_PARTY_NOTICES.md)
curl -sL https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -o RealESRGAN_x4plus.pth
curl -sL https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth -o RealESRGAN_x4plus_anime_6B.pth

# General photo model (23 RRDB blocks — the default args)
python3 convert.py --weights RealESRGAN_x4plus.pth --num-block 23 \
    --out RealESRGAN.mlpackage --description "Real-ESRGAN x4plus"

# Anime/illustration model (6 blocks — smaller & faster)
python3 convert.py --weights RealESRGAN_x4plus_anime_6B.pth --num-block 6 \
    --out RealESRGANAnime.mlpackage --description "Real-ESRGAN x4plus anime_6B"
```

`rrdbnet.py` is the RRDBNet architecture (the model `x4plus` actually is)
copied out of `xinntao/BasicSR`'s `basicsr/archs/rrdbnet_arch.py`, with the
`basicsr` package dependency stripped out — the full `basicsr`/`realesrgan`
pip packages pull in `torchvision.transforms.functional_tensor`, which was
removed in current torchvision and breaks on import. Since we only need
inference with pretrained weights (not training), the only real dependency
was `make_layer`, which is a few lines and easy to inline; the
`default_init_weights` and `pixel_unshuffle` helpers the original file
imports are either irrelevant at inference time or dead code for the x4plus
(scale=4) configuration specifically.

`convert.py` wraps the raw model to bake Real-ESRGAN's pixel-range
convention into the graph: input `ImageType(scale=1/255)` divides the
incoming 0-255 image down to the `[0,1]` range the model expects, and the
wrapper clamps + multiplies the model's output back up to `[0,255]` before
it's declared as an output `ImageType` — so the compiled model takes and
returns plain images with no manual normalization needed on the Swift side.
