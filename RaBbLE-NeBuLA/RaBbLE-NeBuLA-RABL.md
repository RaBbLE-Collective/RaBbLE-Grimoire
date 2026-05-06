# RABL (RaBbLE's JSON Notation) Specification

## Overview
RABL (RaBbLE's JSON Notation) is a simple extension of JSON designed specifically for RaBbLE projects. It uses the `.rabl` file extension instead of `.json` and includes metadata headers for RaBbLE-specific information.

## File Format
RABL files are identical to JSON files in structure and syntax, with the following differences:

### 1. File Extension
- **.rabl** instead of .json
- Standard JSON content underneath

### 2. Metadata Headers
RABL files include a special `rabble_metadata` object at the root level containing RaBbLE-specific information:

```json
{
  "rabble_metadata": {
    "version": "1.0.0",
    "created": "2026-03-16T22:59:44Z",
    "author": "RaBbLE System",
    "entropy_level": 0.75,
    "manifest_type": "scene"
  },
  "entities": [
    {
      "rabble_id": "ent_abc123",
      "dna_type": "box",
      "flux_matrix": [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
      "e_color": "#ff0000",
      "entropy_sig": 42
    }
  ]
}
```

### 3. Special Properties
RABL files use RaBbLE-specific property names:
- `rabble_id`: Unique identifier for entities
- `dna_type`: Type of geometric primitive
- `flux_matrix`: Transformation matrix
- `e_color`: Color with entropy consideration
- `entropy_sig`: Entropy signature value

### 4. Comments
RABL files support comments using JSON5 syntax or special comment format:

```json
{
  // This is a comment in JSON5 format
  "entities": [
    /* This is a block comment */
  ]
}
```

## Validation
RABL files are validated using standard JSON validation tools with additional checks for:
- Required metadata properties
- Valid RaBbLE-specific property names
- Proper data types for special properties

## Tools
Any standard JSON tool can read RABL files. RaBbLE-specific tools will recognize the `.rabl` extension and process metadata accordingly.

## Examples
### Simple RABL File
```json
{
  "rabble_metadata": {
    "version": "1.0.0",
    "created": "2026-03-16T22:59:44Z",
    "author": "RaBbLE System"
  },
  "entities": [
    {
      "rabble_id": "ent_001",
      "dna_type": "sphere",
      "flux_matrix": [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
      "e_color": "#00ff00",
      "entropy_sig": 10
    }
  ]
}
```

### Complex RABL File
```json
{
  "rabble_metadata": {
    "version": "1.0.0",
    "created": "2026-03-16T22:59:44Z",
    "author": "RaBbLE System",
    "entropy_level": 0.8,
    "manifest_type": "character"
  },
  "entities": [
    {
      "rabble_id": "ent_head",
      "dna_type": "sphere",
      "flux_matrix": [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1.5, 0, 1],
      "e_color": "#8a2be2",
      "entropy_sig": 15
    },
    {
      "rabble_id": "ent_eye_left",
      "dna_type": "sphere",
      "flux_matrix": [0.2, 0, 0, 0, 0, 0.2, 0, 0, 0, 0, 0.2, 0, -0.3, 1.6, 0, 1],
      "e_color": "#00ffff",
      "entropy_sig": 5
    }
  ]
}
```

## Best Practices
1. Always include metadata headers
2. Use consistent property naming
3. Validate files before use
4. Use comments for documentation
5. Keep files well-formatted for readability

## Tools and Libraries
- Standard JSON parsers can read RABL files
- RaBbLE-specific tools will recognize .rabl extension
- Validation tools should check both JSON syntax and metadata