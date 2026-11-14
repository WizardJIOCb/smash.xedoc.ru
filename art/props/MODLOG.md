# Painted campaign props

Original sources: built-in imagegen. Exact prompts: prompts.json.
Runtime directory: assets/environment/props.

Front elevation / slight depth matching the existing painted environment.
PNG with soft alpha; original opaque water/alley patches stay opaque.
Trim transparent margin, resize once with LANCZOS, no palette reduction.
Sills/deck walking top bind to room floor + mechanic foot_offset, not to an
arbitrary screen coordinate. Roof support and cover art follow live hitboxes.
Tool: tools/prepare_world_props.py. Source masters never ship in Web export.

Metro train: side elevation facing right, soft alpha PNG 1320x440; runtime 660x220,
flipped for the return pass, front-right pivot. Two clean plates 1280x720 WebP.
Trim car alpha once and resize once with LANCZOS; no palette reduction.
Original sound beds: 22050 Hz mono PCM16, 2-second loops. Rebuild with
tools/prepare_metro_train.py; exact built-in imagegen prompts in metro-prompts.json.
