# MEDIA — files held in course media storage, not in GitHub

The assignment requires MP4 and MP3 files to be kept out of GitHub. They are
excluded by `.gitignore` and stored in course media storage instead. This file
is the manifest: every excluded file with its SHA-256, so a copy retrieved from
course storage can be verified byte-for-byte against this repository.

Verify any one of them with:

    shasum -a 256 <file>


---

## 1. Required — the film and its evidence

These six files are what a reviewer needs. Everything else below is derived
from them and can be regenerated.

| File | Size | Role |
|---|---|---|
| `capture/run-01.mp4` | 1.8 MB | Evidence — take 1, high route start to finish (beat B02) |
| `capture/run-02.mp4` | 1.6 MB | Evidence — take 2, failure, recovery and menus (beat B04) |
| `capture/run-03.mp4` | 1.8 MB | Evidence — take 3, ground route and backtrack (beat B06) |
| `capture/run-04.mp4` | 1.1 MB | Evidence — take 4, control-model edges (beat B03) |
| `capture/run-05.mp4` | 0.4 MB | Evidence — take 5, focus-loss pause (beat B05) |
| `exports/landscape/claude-liam-walker-jumpman-walkthrough.mp4` | 13.3 MB | THE FILM — 4K master, the deliverable |

```
ff0f0c31d9a664a3dbf4cce2750d603db8383fcc5118e2d9c47419e7cc2bca4e  capture/run-01.mp4
b498f0d094e89e382b0da4a8e80f19ec6124f478abfbe727606e1c9bf161c6bb  capture/run-02.mp4
26d89e7ff978a6b8eda0600ac8c3d6245ca1cfa49b1eeda3378719f3b9b8e356  capture/run-03.mp4
b3eabef6246d0fb54e59b0b3052f2ddb098ed81fe8fa479637ddac36ee7a7ee2  capture/run-04.mp4
5e71654355dca84d27f5b5cf2351487de17732b9ba80281bb0b24768a2b8d04f  capture/run-05.mp4
a6a46018fdf342300cb94f5dc6886b6c0f2add217da710d8c6a17e9d4bbf329a  exports/landscape/claude-liam-walker-jumpman-walkthrough.mp4
```

The five `capture/*.mp4` hashes are also recorded in `coverage.json`, which is
tracked in git — that is the evidence contract the walkthrough gate checks.
The master's hash is also in the tracked `build-state.json` and
`exports/landscape/*.verified.json`.


## 2. Derived — regenerable, upload only if you want the exact build

`media/*.mp4` are the per-beat slots (the five gameplay slots are byte-identical
copies of the captures above); `mp3/*` is the Kokoro narration, `mp3/raw/*` the
unpadded originals. All are rebuilt by `BUILD-PROMPT.md`.

| File | Size |
|---|---|
| `claude-liam-walker-jumpman-walkthrough-slate.mp4` | 13115 KB |
| `media/B00.mp4` | 1142 KB |
| `media/B01.mp4` | 883 KB |
| `media/B02.mp4` | 1827 KB |
| `media/B03.mp4` | 1084 KB |
| `media/B04.mp4` | 1604 KB |
| `media/B05.mp4` | 401 KB |
| `media/B06.mp4` | 1804 KB |
| `media/BHTF.mp4` | 1043 KB |
| `media/BOUT.mp4` | 242 KB |
| `media/BVDT.mp4` | 2320 KB |
| `mp3/beat-B00.mp3` | 191 KB |
| `mp3/beat-B01.mp3` | 97 KB |
| `mp3/beat-B02.mp3` | 116 KB |
| `mp3/beat-B03.mp3` | 74 KB |
| `mp3/beat-B04.mp3` | 114 KB |
| `mp3/beat-B05.mp3` | 51 KB |
| `mp3/beat-B06.mp3` | 115 KB |
| `mp3/beat-BHTF.mp3` | 285 KB |
| `mp3/beat-BOUT.mp3` | 28 KB |
| `mp3/beat-BVDT.mp3` | 336 KB |
| `mp3/raw/beat-B00.mp3` | 191 KB |
| `mp3/raw/beat-B01.mp3` | 95 KB |
| `mp3/raw/beat-B02.mp3` | 113 KB |
| `mp3/raw/beat-B03.mp3` | 74 KB |
| `mp3/raw/beat-B04.mp3` | 111 KB |
| `mp3/raw/beat-B05.mp3` | 51 KB |
| `mp3/raw/beat-B06.mp3` | 112 KB |
| `mp3/raw/beat-BHTF.mp3` | 286 KB |
| `mp3/raw/beat-BOUT.mp3` | 28 KB |
| `mp3/raw/beat-BVDT.mp3` | 337 KB |
| `mp4/claude-liam-walker-jumpman-walkthrough-slate.mp4` | 13115 KB |

```
fd7e55151229bd28c053bce83eb6eb26396447eeaea5f0b3274ee2c28a6b193a  claude-liam-walker-jumpman-walkthrough-slate.mp4
48fdd736293fdd358e383f6ae254552422f64e181148f51525f91da5f4def8d3  media/B00.mp4
492902218a72f92f8e41ad014d5e021d49dec92b5cf46828a97764db74dd3854  media/B01.mp4
ff0f0c31d9a664a3dbf4cce2750d603db8383fcc5118e2d9c47419e7cc2bca4e  media/B02.mp4
b3eabef6246d0fb54e59b0b3052f2ddb098ed81fe8fa479637ddac36ee7a7ee2  media/B03.mp4
b498f0d094e89e382b0da4a8e80f19ec6124f478abfbe727606e1c9bf161c6bb  media/B04.mp4
5e71654355dca84d27f5b5cf2351487de17732b9ba80281bb0b24768a2b8d04f  media/B05.mp4
26d89e7ff978a6b8eda0600ac8c3d6245ca1cfa49b1eeda3378719f3b9b8e356  media/B06.mp4
5ba03670884686acdfb8d6b258a3c9f0a7a9a080464bb8519adee668c43e91e3  media/BHTF.mp4
2f40891f2791676652f564e4e3d50c73e515ad677ef889e605658f5020bb9189  media/BOUT.mp4
b736c1772ff6562bc65064d9f47138d607fadf4d2c3dde8c2e4bfd2e82a4da87  media/BVDT.mp4
fa1ea7566b7f52164f67b72b1f0a8d05d1d1fc01594372d4363e1bd4ab7a9500  mp3/beat-B00.mp3
dc8fd1ce090cbd4340171c4c5a6aecfc3c14462e864b9ce94a2b1d347f856411  mp3/beat-B01.mp3
8364f0002fd0da4d9f6ae32b70d40f71f3d9f8b9ca1158d322289b53c710f6a0  mp3/beat-B02.mp3
ea19e4f13013e597d85110673c082b5a6d55bcab568edbcfaff025a38748b3d5  mp3/beat-B03.mp3
e616bd06dcc016e60c220ac8832a8d6754c21cef84a642620e274dba3908c643  mp3/beat-B04.mp3
3ff1bd632e41337dec3730226d93ab8476fbc2d8566a8b5b6211f00ee6c81170  mp3/beat-B05.mp3
1b446afbf31598c67e38c97aee825ad53112ad207fef4ce6bf1e7cd709499a50  mp3/beat-B06.mp3
52f00f436e7cbbaeedb89dacd07db8aa342be6b37f1c794dc1313a7bcfa295a1  mp3/beat-BHTF.mp3
8bcd98775bd9588786e1f1762fec290addc529d6fd174381cbcd9c964c5a0d3b  mp3/beat-BOUT.mp3
444fc15e564b5b37d5bfa7a17c8d42c6a82b536effa202c45bc2c1a8f54347be  mp3/beat-BVDT.mp3
c0ff823537cc802e8cfd9e5195d6b391eacea1ad285623331614825f4f656511  mp3/raw/beat-B00.mp3
8952386f383277e4dae7fd38d9ef97075b4028ea66cfc6dd16712f3e71fdb07c  mp3/raw/beat-B01.mp3
30f0145e44f8946413693a8483062eac8813f661a4e90413a1eee92154ab0eea  mp3/raw/beat-B02.mp3
4eaf292d9fa2b8af891745d4747ca4e79eac4b7604ee46df535ea4921289e43a  mp3/raw/beat-B03.mp3
6bac607dc8e5569e4ca0067299a2a6a441bbccd8e5745d4bab0f4976e8a1e622  mp3/raw/beat-B04.mp3
b96084b65fb9754181b56b75a61c1b01a3a26b7e3ed45cecf4fa322b50c77fd9  mp3/raw/beat-B05.mp3
756dd074254fdb44039ed9e7dac63d41fffdc1d3bd0be7f50f0c2dd839c771c1  mp3/raw/beat-B06.mp3
3dd468fcb46c377cdc742ed6a5dc350a8e98b739af8cafa19da801fd75a5234a  mp3/raw/beat-BHTF.mp3
04faa6e2a83135fedfba847fce9b3b8d0d984d342447fc72d1d7f33ea4651baa  mp3/raw/beat-BOUT.mp3
032a785e52d03d43c6b59725e733396b93546012fa723e84467bfb307c7a2fba  mp3/raw/beat-BVDT.mp3
fd7e55151229bd28c053bce83eb6eb26396447eeaea5f0b3274ee2c28a6b193a  mp4/claude-liam-walker-jumpman-walkthrough-slate.mp4
```


---

Total excluded media: **38 files, 60.2 MB.**
Required subset: **6 files, 19.8 MB.**
