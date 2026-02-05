# MATLAB Toolbox Skills for Claude

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/MATLAB-R2025b-orange.svg" alt="MATLAB R2025b">
</p>

As a biomedical engineering PhD student, I use MATLAB daily for medical image analysis. I created these skills because Claude often suggests Python workarounds for things MATLAB can do natively, or recommends functions that were deprecated several versions ago.

These skills give Claude accurate, toolbox-specific knowledge so it suggests code that actually works.

> **New to Claude Skills?** Skills are knowledge packages that extend Claude's capabilities. [Learn more →](https://docs.anthropic.com/en/docs/claude-ai/skills)

<br>

## See the Difference

I tested each skill by asking Claude the same question with and without the skill loaded.

<br>

<table>
<tr>
<td colspan="3">

**How do I use MedSAM to segment a tumor from a CT volume in MATLAB?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Python bridge required</td><td><strong>Native MATLAB</strong></td></tr>
<tr><td>Code complexity</td><td>100+ lines across two languages</td><td><strong>~40 lines pure MATLAB</strong></td></tr>
<tr><td>Key function</td><td>Doesn't know it exists</td><td><code>medicalSegmentAnythingModel</code></td></tr>
<tr><td>Workflow</td><td>Temp files, subprocess calls</td><td><code>extractEmbeddings</code> → <code>segmentObjectsFromEmbeddings</code></td></tr>
<tr><td>3D handling</td><td>"Loop over slices" (vague)</td><td><strong>Propagates results across slices with spatial continuity</strong></td></tr>
</table>

<br>

<table>
<tr>
<td colspan="3">

**How do I visualize a 3D medical volume with a segmentation overlay?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Workarounds (isosurface, loops)</td><td><strong><code>OverlayData</code> parameter</strong></td></tr>
<tr><td>Code</td><td>30+ lines</td><td><strong>3 lines</strong></td></tr>
<tr><td>Key syntax</td><td>Doesn't know it</td><td><code>volshow(V, OverlayData=L.Voxels)</code></td></tr>
</table>

<br>

---

## Installation

#### Claude Desktop

1. Download or clone this repository
2. Zip the skill folder you want:
   ```
   zip -r matlab-medical-imaging-toolbox.zip matlab-medical-imaging-toolbox
   ```
3. Go to **Settings → Capabilities → Add Skill** and upload the zip
4. Toggle the skill on and start a new conversation

#### Claude.ai (Web)

Go to **Settings → Capabilities → Add Skill** and upload the zip file.

#### Claude Code

Copy the skill folder to your skills directory:

```bash
# For all your projects (personal)
cp -r matlab-medical-imaging-toolbox ~/.claude/skills/

# Or for a specific project only
cp -r matlab-medical-imaging-toolbox .claude/skills/
```

See the [Claude Code skills documentation](https://code.claude.com/docs/en/skills) for more details.

---

## Use with MathWorks MATLAB MCP Server

These skills work great alongside the official [MATLAB MCP Core Server](https://github.com/matlab/matlab-mcp-core-server) from MathWorks:

|   | What It Provides |
|:--|:-----------------|
| **MCP Server** | Code execution, syntax checking, toolbox detection |
| **These Skills** | Toolbox-specific knowledge for accurate suggestions |

See [MathWorks AI resources](https://github.com/matlab) for more tools.

---

## Available Skills

| Skill | What It Covers |
|:------|:---------------|
| `matlab-medical-imaging-toolbox` | DICOM/NIfTI I/O, MedSAM, Cellpose, radiomics, 3D visualization |
| `matlab-image-processing-toolbox` | Filtering, segmentation, morphology, watershed, regionprops |
| `matlab-deep-learning` | U-Net, semantic segmentation, custom training, transfer learning |
| `matlab-stats-ml` | Classification, regression, survival analysis, Bayesian methods |
| `matlab-wavelet-toolbox` | 2D transforms, denoising, lifting schemes, shearlets |

---

<details>
<summary><h2>More Examples</h2></summary>

<br>

<table>
<tr>
<td colspan="3">

**How do I segment overlapping cells in a microscopy image?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Basic watershed</td><td><strong>Production-ready watershed</strong></td></tr>
<tr><td>Preprocessing</td><td>Simple threshold</td><td><code>imtophat</code> for background correction</td></tr>
<tr><td>Edge handling</td><td>Not addressed</td><td><code>imclearborder</code> for edge cases</td></tr>
<tr><td>Parameters</td><td>Generic values</td><td>Specific values with explanations</td></tr>
</table>

<br>

<table>
<tr>
<td colspan="3">

**How do I create a U-Net for image segmentation in MATLAB?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Functions used</td><td><code>unetLayers</code>, <code>trainNetwork</code> (deprecated)</td><td><strong>Both legacy and modern functions</strong></td></tr>
<tr><td>Modern syntax</td><td>Not mentioned</td><td><code>unet</code>, <code>trainnet</code> (R2024b+)</td></tr>
<tr><td>Custom architecture</td><td>Not shown</td><td>Manual construction code included</td></tr>
</table>

<br>

<table>
<tr>
<td colspan="3">

**How do I use shearlets for directional texture analysis?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Third-party toolbox (ShearLab 3D)</td><td><strong>Native MATLAB Wavelet Toolbox</strong></td></tr>
<tr><td>Setup required</td><td>Download from shearlab.org</td><td><strong>None — built-in</strong></td></tr>
<tr><td>Forward transform</td><td><code>SLsheardec2D</code></td><td><code>sheart2</code></td></tr>
<tr><td>External dependencies</td><td>Yes</td><td><strong>No</strong></td></tr>
</table>

</details>

---

## Contributing

Found an error? Have a suggestion? Contributions are welcome.

- **Report issues** — Open an [issue](../../issues) to report bugs or suggest improvements
- **Submit fixes** — See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

All feedback is appreciated.

## License

[MIT](LICENSE)
