import argparse

import coremltools as ct
import torch
import torch.nn as nn

from rrdbnet import RRDBNet
from srvgg_arch import SRVGGNetCompact

TILE_SIZE = 128  # must match PixelBoost's CoreMLTileUpscaler.Config.tileSize


class Wrapped(nn.Module):
    """Bakes Real-ESRGAN's pixel-range convention into the graph so the
    compiled model can take/return plain 0-255 images directly, with no
    manual normalization needed on the Swift side:
    - Input: coremltools' ImageType(scale=1/255) preprocessing divides the
      incoming 0-255 image down to the [0,1] float range the base model
      expects, before this wrapper even runs.
    - Output: the base model's raw output isn't guaranteed to land exactly
      in [0,1] (some pixels can overshoot), so clamp then scale back up to
      0-255 here, in-graph, before it's declared as an output ImageType.
    """

    def __init__(self, base: nn.Module):
        super().__init__()
        self.base = base

    def forward(self, x):
        out = self.base(x)
        out = torch.clamp(out, 0.0, 1.0) * 255.0
        return out


def main():
    parser = argparse.ArgumentParser(description="Convert a Real-ESRGAN checkpoint (RRDBNet or SRVGGNetCompact) to Core ML.")
    parser.add_argument("--weights", default="RealESRGAN_x4plus.pth", help="Path to the .pth checkpoint")
    parser.add_argument(
        "--arch", default="rrdbnet", choices=["rrdbnet", "srvgg"],
        help="rrdbnet (x4plus/anime_6B/RealESRNet_x4plus) or srvgg (realesr-general-x4v3 and friends)"
    )
    parser.add_argument("--num-block", type=int, default=23, help="RRDBNet num_block (23 for x4plus/RealESRNet, 6 for anime_6B)")
    parser.add_argument("--num-conv", type=int, default=32, help="SRVGGNetCompact num_conv (32 for general-x4v3, 16 for animevideov3)")
    parser.add_argument("--out", default="RealESRGAN.mlpackage", help="Output .mlpackage path")
    parser.add_argument("--description", default="Real-ESRGAN x4plus", help="Short description baked into the model")
    args = parser.parse_args()

    if args.arch == "rrdbnet":
        base = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=args.num_block, num_grow_ch=32)
    else:
        base = SRVGGNetCompact(num_in_ch=3, num_out_ch=3, num_feat=64, num_conv=args.num_conv, upscale=4, act_type="prelu")

    state = torch.load(args.weights, map_location="cpu", weights_only=True)
    # RRDBNet checkpoints store the EMA'd weights under "params_ema";
    # SRVGGNetCompact checkpoints (no EMA) store them under "params".
    key = "params_ema" if "params_ema" in state else "params"
    base.load_state_dict(state[key])
    base.eval()

    wrapped = Wrapped(base)
    wrapped.eval()

    example = torch.rand(1, 3, TILE_SIZE, TILE_SIZE)
    with torch.no_grad():
        traced = torch.jit.trace(wrapped, example)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="input", shape=(1, 3, TILE_SIZE, TILE_SIZE), scale=1.0 / 255.0, bias=[0, 0, 0])],
        outputs=[ct.ImageType(name="output")],
        compute_precision=ct.precision.FLOAT16,
        minimum_deployment_target=ct.target.iOS16,
    )
    mlmodel.short_description = (
        f"{args.description} (BSD-3-Clause, github.com/xinntao/Real-ESRGAN) — "
        f"fixed {TILE_SIZE}x{TILE_SIZE} input, 4x output, for tiled use via ImageTiler."
    )
    mlmodel.save(args.out)
    print(f"Saved {args.out}")


if __name__ == "__main__":
    main()
