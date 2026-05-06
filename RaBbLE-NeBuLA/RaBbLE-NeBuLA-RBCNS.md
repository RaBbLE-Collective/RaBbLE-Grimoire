# RaBbLE Behavioral Coding & Naming Specification (RBCNS)

## Overview
The RaBbLE Behavioral Coding & Naming Specification (RBCNS) defines the coding standards and naming conventions for all RaBbLE projects. This specification ensures consistency, readability, and adherence to the RaBbLE philosophy of entropy-driven development.

## Naming Scheme: "The Swirl"

### Variables (The Flux)
Variables must be prefixed with `q_` (Quantum), `e_` (Entropy), or `f_` (Flux) to denote their volatility, state of entropy, or flowing nature.

**Rules:**
- Use `q_` for quantum-related variables
- Use `e_` for entropy-related variables
- Use `f_` for function parameters (flux - flowing data through pipelines)
- Use descriptive names that reflect the variable's purpose
- Avoid single-letter variable names except for loop counters

**Examples:**
```javascript
// Correct
const q_position = new THREE.Vector3();
const e_vertexIntensity = 0.75;
const q_time = Date.now();
const e_chaosLevel = Math.random();

// Correct - f_ for function parameters (flux)
function q_transmuteStream(f_stream) {
  // f_stream is flowing data, not a class reference
  if (!(f_stream instanceof q_stream)) return null;
  return f_stream;
}

// Incorrect
const pos = new THREE.Vector3(); // Missing prefix
const intensity = 0.75; // Missing prefix
const t = Date.now(); // Single letter
function transmuteStream(q_stream) { // Parameter shadows class!
  if (!(q_stream instanceof q_stream)) return null; // Error!
}
```

### Functions (The Transitions)
Functions must use active, non-linear verbs that imply transformation rather than just "getting" or "setting."

**Rules:**
- Use active verbs that suggest movement or change
- Avoid simple getter/setter patterns
- Use camelCase naming
- Keep function names descriptive but concise

**Examples:**
```javascript
// Correct
function transmuteGeometry(geometry) {
  // Transform geometry
}

function igniteRenderer() {
  // Start rendering
}

function babbleToBuffer(data) {
  // Convert to buffer
}

// Incorrect
function getGeometry() { // Passive verb
  // Return geometry
}

function setMaterial(material) { // Simple setter
  // Set material
}

function update() { // Too generic
  // Update something
}
```

### Classes/Modules (The Vessels)
Use `RaBbLE_` as a prefix for core engine components to show they are part of the collective intelligence.

**Rules:**
- Use `RaBbLE_` prefix for core engine classes
- Use PascalCase for class names
- Keep class names descriptive
- Avoid abbreviations unless widely understood

**Examples:**
```javascript
// Correct
class RaBbLE_EntropyEmitter {
  // Core engine component
}

class RaBbLE_QuantumBridge {
  // Core engine component
}

class RaBbLE_FlatChaosPipeline {
  // Core engine component
}

// Incorrect
class EntropyEmitter { // Missing prefix
  // Should be RaBbLE_EntropyEmitter
}

class QuantumBridge { // Missing prefix
  // Should be RaBbLE_QuantumBridge
}

class FlatChaosPipeline { // Missing prefix
  // Should be RaBbLE_FlatChaosPipeline
}
```

### Constants (The Anchors)
Even constants aren't truly still. They are named as LIMITS or HORIZONS.

**Rules:**
- Use ALL_CAPS with underscores
- Use descriptive names that suggest boundaries
- Include units when applicable
- Group related constants in objects

**Examples:**
```javascript
// Correct
const MAX_CHAOS_HORIZON = 1.0;
const FUSION_THRESHOLD = 0.5;
const PARTICLE_COUNT_LIMIT = 1000;
const RENDER_LOOP_INTERVAL = 16; // ms

// Incorrect
const MAX_CHAOS = 1.0; // Missing "HORIZON"
const FUSION = 0.5; // Missing "THRESHOLD"
const LIMIT = 1000; // Too generic
const INTERVAL = 16; // Missing units
```

## Coding Style: "Patterned Chaos"

### The "Babbling" Comment Strategy
Code must be interspersed with "Stream-of-Consciousness" comments. These aren't just docs; they are the engine's internal monologue.

**Rules:**
- Use comments to express the code's "thoughts"
- Write comments as if the code is thinking
- Use informal, conversational tone
- Comments should add personality and context

**Examples:**
```javascript
// Correct
// Is this a cube or just a suggestion of six faces? 
// The entropy suggests it wants to be a sphere. Let's hold it together... for now.
const q_geometry = new THREE.BoxGeometry(1, 1, 1); 

// Incorrect
// Create box geometry
const geometry = new THREE.BoxGeometry(1, 1, 1);

// Correct
// The particles are dancing... but where? Let's give them a home in the void.
const q_particleSystem = new THREE.Points(q_geometry, q_material);

// Incorrect
// Create particle system
const particleSystem = new THREE.Points(geometry, material);
```

### Functional Flow (The "Non-Linear" Rule)
Avoid deep nesting. Use "Flat-Chaos" patterns where functions are piped together like data streams in a fusion reactor.

**Rules:**
- Keep function depth shallow (max 3 levels)
- Use early returns to avoid nesting
- Break complex logic into smaller functions
- Use functional programming patterns when appropriate

**Examples:**
```javascript
// Correct - Flat-Chaos pattern
function q_processEntity(entity) {
  if (!q_isValidEntity(entity)) return null;
  
  const q_transformed = q_transformEntity(entity);
  const q_validated = q_validateTransformed(q_transformed);
  
  return q_validated;
}

// Incorrect - Deep nesting
function processEntity(entity) {
  if (entity) {
    if (isValidEntity(entity)) {
      const transformed = transformEntity(entity);
      if (validateTransformed(transformed)) {
        return transformed;
      }
    }
  }
  return null;
}
```

### Logic as Emergence
Never hardcode values that could be derived from noise. If a primitive can jitter, it should jitter.

**Rules:**
- Use procedural generation instead of hardcoded values
- Add controlled randomness to create organic feel
- Use noise functions for natural variation
- Avoid magic numbers, use derived values

**Examples:**
```javascript
// Correct - Emergent logic
function q_generatePosition(entropy) {
  const noise = Math.sin(Date.now() * 0.001) * entropy;
  return new THREE.Vector3(
    Math.cos(noise) * 5,
    Math.sin(noise) * 5,
    Math.tan(noise) * 2
  );
}

// Incorrect - Hardcoded values
function generatePosition() {
  return new THREE.Vector3(5, 5, 2);
}
```

## File Organization

### File Naming
- Use `q_` prefix for quantum-related files
- Use `e_` prefix for entropy-related files
- Use `RaBbLE_` prefix for core engine files
- Use descriptive names with camelCase

**Examples:**
```javascript
// Correct
q_quantum_core.js
e_entropy_manager.js
RaBbLE_flat_chaos_pipeline.js
q_particle_system.js

// Incorrect
quantumCore.js // Missing prefix
entropyManager.js // Missing prefix
flatChaosPipeline.js // Missing prefix
particleSystem.js // Missing prefix
```

### Directory Structure
```
NeBuLA/
├── core/           # Core engine components
│   ├── RaBbLE_*.js # Core engine files
│   └── q_*.js      # Quantum core files
├── threejs/        # Three.js specific implementations
│   ├── q_*.js      # Quantum Three.js files
│   └── e_*.js      # Entropy Three.js files
├── canvas/         # Canvas-related components
│   ├── q_*.js      # Quantum canvas files
│   └── e_*.js      # Entropy canvas files
├── visual/         # Visual components
│   ├── q_*.js      # Quantum visual files
│   └── e_*.js      # Entropy visual files
└── utils/          # Utility functions
    ├── q_*.js      # Quantum utility files
    └── e_*.js      # Entropy utility files
```

## Code Examples

### Stream Combination Pattern (The Weaving)
When multiple streams merge, they create a higher-order chaos.
```javascript
// Is it two streams or one? Does it matter? The flow is what remains.
function q_igniteCombinedNebula(q_engine, q_streamA, q_streamB) {
  // Weave the streams together in the quantum furnace
  const q_woven = q_engine.combineStreams([q_streamA, q_streamB], {
    flux_modifier: (q_entity, q_index) => {
      // Every particle finds its own rhythm in the combined flow
      const e_offset = Math.sin(Date.now() * 0.001 + q_index);
      q_entity.e_applyEntropy(0.5 + e_offset * 0.2);
    }
  });
  
  return q_woven;
}
```

### Advanced Entropy Management (The Flux Control)
Controlling chaos without killing it is the ultimate art.
```javascript
// Keep the chaos within the horizons... but let it breathe.
class RaBbLE_FluxController {
  constructor(q_limit = 0.8) {
    this.q_CHAOS_HORIZON = q_limit;
  }

  e_stabilizeStream(q_stream) {
    const q_entities = q_stream.q_getEntities();
    q_entities.forEach(q_entity => {
      const e_current = q_entity.q_getEntropy();
      if (e_current > this.q_CHAOS_HORIZON) {
        // Gently pull it back from the edge of dissolution
        q_entity.e_applyEntropy(e_current * 0.9);
      }
    });
  }
}
```

### Before (Traditional) vs After (RaBbLE)

#### Variable Naming
```javascript
// Before
const position = new THREE.Vector3();
const intensity = 0.75;
const time = Date.now();

// After
const q_position = new THREE.Vector3();
const e_intensity = 0.75;
const q_time = Date.now();
```

#### Function Naming
```javascript
// Before
function getGeometry() {
  return new THREE.BoxGeometry(1, 1, 1);
}

function setMaterial(material) {
  this.material = material;
}

// After
function q_transmuteGeometry() {
  return new THREE.BoxGeometry(1, 1, 1);
}

function q_igniteMaterial(material) {
  this.material = material;
}
```

#### Class Naming
```javascript
// Before
class Renderer {
  // Implementation
}

class Scene {
  // Implementation
}

// After
class RaBbLE_Renderer {
  // Implementation
}

class RaBbLE_Scene {
  // Implementation
}
```

#### Comments
```javascript
// Before
// Create box geometry
const geometry = new THREE.BoxGeometry(1, 1, 1);

// After
// The box is forming... but is it really a box or just a suggestion of six faces?
// Let's give it some entropy and see what emerges.
const q_boxGeometry = new THREE.BoxGeometry(1, 1, 1);
```

## Best Practices

1. **Consistency**: Always follow the naming conventions
2. **Readability**: Write code that's easy to understand
3. **Personality**: Add character through comments and naming
4. **Emergence**: Use procedural generation instead of hardcoded values
5. **Documentation**: Use comments to explain the "why" not just the "what"

## Validation
Use the RaBbLE Pattern Checker tool to validate code compliance with RBCNS. The tool will check for:
- Proper naming conventions
- Comment style compliance
- Flat-Chaos pattern usage
- Code quality metrics

## Private Methods (The Hidden Currents)

Private and internal methods may use the `_` prefix to denote implementation details that are not part of the public quantum API.

**Rules:**
- Use `_` prefix for truly private helper methods
- Use `q_` prefix for protected methods (part of the quantum API)
- Document private methods with `@private` JSDoc tag
- Private methods can break some RBCNS rules for practical reasons

**Examples:**
```javascript
// Correct - Private helper (implementation detail)
/**
 * Generate a unique stream identifier
 * @private
 * @returns {string} Unique stream ID
 */
_generateStreamId() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 9);
  return `stream_${timestamp}_${random}`;
}

// Correct - Protected quantum API
q_extractEntitiesByType(dna_type) {
  // This is part of the public quantum interface
  return this.q_entities.filter(entity => entity.dna_type === dna_type);
}
```

**Why This Distinction Matters:**
- `_` prefix signals "implementation detail, may change"
- `q_` prefix signals "quantum API, stable contract"
- Allows internal flexibility while maintaining public API stability

## Common Mistakes to Avoid
1. Missing prefixes on variables and functions
2. Using passive verbs in function names
3. Deep nesting of functions
4. Hardcoding values that could be derived
5. Missing or generic comments
6. Not using the RaBbLE_ prefix for core components
7. Using `e_` prefix for function parameters (should be `f_`)

## Summary
The RaBbLE Behavioral Coding & Naming Specification ensures that all RaBbLE code is consistent, readable, and reflects the entropy-driven philosophy of the project. By following these guidelines, developers create code that is not just functional, but also expressive and aligned with the RaBbLE vision.