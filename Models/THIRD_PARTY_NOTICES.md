# Third-party notices

## Real-ESRGAN (RealESRGAN.mlpackage, RealESRGANAnime.mlpackage, RealESRNet.mlpackage, RealESRGeneralV3.mlpackage)

All four bundled models are Core ML conversions of checkpoints from
[xinntao/Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) (architectures
defined in [xinntao/BasicSR](https://github.com/xinntao/BasicSR) and in
Real-ESRGAN's own `realesrgan/archs/`):

- `RealESRGAN.mlpackage` ← `RealESRGAN_x4plus.pth` (general photo, RRDBNet 23 blocks)
- `RealESRGANAnime.mlpackage` ← `RealESRGAN_x4plus_anime_6B.pth`
  (anime/illustration, RRDBNet 6 blocks)
- `RealESRNet.mlpackage` ← `RealESRNet_x4plus.pth` (portrait, RRDBNet 23
  blocks — same architecture/data as x4plus, trained without a GAN loss)
- `RealESRGeneralV3.mlpackage` ← `realesr-general-x4v3.pth` (fast & clean
  everyday default, SRVGGNetCompact 32 conv layers — a different, smaller
  architecture from the other three)

All four converted with [`convert.py`](convert/convert.py) — see that
folder to reproduce or adapt any of them.

```
BSD 3-Clause License

Copyright (c) 2021, Xintao Wang
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

Fetched directly from the upstream repo's `LICENSE` file at conversion time
(`https://raw.githubusercontent.com/xinntao/Real-ESRGAN/master/LICENSE`) —
re-verify it hasn't changed if you re-convert from a newer checkpoint.
