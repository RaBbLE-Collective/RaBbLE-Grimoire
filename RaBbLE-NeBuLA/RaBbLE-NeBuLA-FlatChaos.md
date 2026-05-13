# RaBbLE-NeBuLA-FlatChaos.md

```
transcribe ~ grimoire >> Flat-Chaos pattern distilled from NeBuLA-JS // %FLAT_CHAOS_LOCKED%
```

> This pattern is the core architectural insight of NeBuLA. Carry it forward into the v2 rebuild.
> Source: NeBuLA-JS (`RaBbLE-Xperimental/`). Aligned to Grimoire 2026-05-13.

---

## Overview

Flat-Chaos replaces hierarchical scene graphs with a flat stream of self-contained entities.
Each entity carries its own geometry (DNA), transform (Flux), and entropy — no parent-child
relationships, no scene tree. Complexity emerges from composition, not nesting.

## Core Principles

### 1. Stream-Based Architecture
Instead of hierarchical relationships, Flat-Chaos uses linear data streams where each "drop" in the stream is an object containing its own DNA (geometry), its Flux (transformation), and its Entropy (shading).

### 2. Pipeline Processing
Data flows through a series of discrete functions: Source → Filter → Transmute → Sink. Each stage is independent and can be modified without affecting the others.

### 3. Emergent Behavior
The system doesn't "build" scenes; it "defines states." This allows for hot-swapping, parallel processing, and truly dynamic behavior.

## Architecture Comparison

### Traditional Scene Graph
```
Scene
├── Group 1
│   ├── Mesh A
│   ├── Mesh B
│   └── Group 2
│       └── Mesh C
└── Light
```

### Flat-Chaos Stream
```
Stream Array:
[
  { id: 'ent_001', type: 'mesh', dna: 'box', flux: [matrix], entropy: 0.5 },
  { id: 'ent_002', type: 'mesh', dna: 'sphere', flux: [matrix], entropy: 1.2 },
  { id: 'ent_003', type: 'light', dna: 'point', flux: [matrix], entropy: 0.3 }
]
```

## The Pipeline Structure

### Source (The Babble)
The source generates raw data chunks. In RaBbLE, this is where the system's "thoughts" emerge as data structures.

```javascript
// Source: Generating the initial data stream
const RaBbLE_Stream = [
  { id: 'q_core_01', type: 'primitive', dna: 'sphere', entropy: 0.5 },
  { id: 'q_core_02', type: 'primitive', dna: 'box', entropy: 1.2 }
];
```

### Filter (The Chaos)
The filter applies jitter, noise, or logic to the data. This is where entropy is introduced and controlled.

```javascript
// Filter: Adding controlled chaos to the stream
const injectChaos = (stream) => stream.map(ent => ({
  ...ent,
  flux_matrix: applyEntropy(ent.entropy, Date.now()) 
}));
```

### Transmute (The Bridge)
The transmute converts abstract data into concrete implementations. This is the bridge between data and rendering.

```javascript
// Transmute: Converting data to Three.js objects
const transmuteToThree = (stream) => stream.map(ent => {
  const mesh = RaBbLE_Cache.get(ent.id) || createNewMesh(ent);
  mesh.matrix.fromArray(ent.flux_matrix);
  return mesh;
});
```

### Sink (The Render)
The sink is the final output - the actual rendering call. This could be WebGL, native OpenGL, or any other rendering target.

```javascript
// Sink: The final rendering step
function igniteRenderFlow() {
  const chaoticStream = injectChaos(RaBbLE_Stream);
  const renderables = transmuteToThree(chaoticStream);
  
  renderables.forEach(q_obj => RaBbLE_Renderer.render(q_obj, q_camera));
  
  requestAnimationFrame(igniteRenderFlow);
}
```

## Implementation Examples

### Basic Flat-Chaos Pipeline
```javascript
// RaBbLE_FlatChaosPipeline.js
class RaBbLE_FlatChaosPipeline {
  constructor() {
    this.e_source = []; // The Babble
    this.e_filter = this.q_injectChaos; // The Chaos
    this.e_transmute = this.q_toThree; // The