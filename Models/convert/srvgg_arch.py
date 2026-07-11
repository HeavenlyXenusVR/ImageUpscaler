# SRVGGNetCompact (the compact VGG-style architecture behind Real-ESRGAN's
# realesr-general-x4v3/realesr-animevideov3), copied from xinntao/Real-ESRGAN's
# realesrgan/archs/srvgg_arch.py (BSD-3-Clause) with the `basicsr`
# ARCH_REGISTRY decorator/import stripped out — it only matters for
# discovering architectures by name during training, not for inference with
# pretrained weights.
from torch import nn as nn
from torch.nn import functional as F


class SRVGGNetCompact(nn.Module):
    """A compact VGG-style network structure for super-resolution.

    It performs upsampling in the last layer and no convolution is
    conducted on the HR feature space — much smaller/faster than RRDBNet
    for a comparable result, at the cost of the largest model's fine detail.
    """

    def __init__(self, num_in_ch=3, num_out_ch=3, num_feat=64, num_conv=32, upscale=4, act_type="prelu"):
        super(SRVGGNetCompact, self).__init__()
        self.upscale = upscale

        self.body = nn.ModuleList()
        self.body.append(nn.Conv2d(num_in_ch, num_feat, 3, 1, 1))
        self.body.append(self._activation(act_type, num_feat))

        for _ in range(num_conv):
            self.body.append(nn.Conv2d(num_feat, num_feat, 3, 1, 1))
            self.body.append(self._activation(act_type, num_feat))

        self.body.append(nn.Conv2d(num_feat, num_out_ch * upscale * upscale, 3, 1, 1))
        self.upsampler = nn.PixelShuffle(upscale)

    @staticmethod
    def _activation(act_type, num_feat):
        if act_type == "relu":
            return nn.ReLU(inplace=True)
        if act_type == "prelu":
            return nn.PReLU(num_parameters=num_feat)
        if act_type == "leakyrelu":
            return nn.LeakyReLU(negative_slope=0.1, inplace=True)
        raise ValueError(f"Unknown act_type: {act_type}")

    def forward(self, x):
        out = x
        for layer in self.body:
            out = layer(out)
        out = self.upsampler(out)
        # Learns the residual against a plain nearest-neighbor upsample of
        # the input, rather than the absolute output — same trick RRDBNet
        # uses via its own skip connections.
        base = F.interpolate(x, scale_factor=self.upscale, mode="nearest")
        out += base
        return out
