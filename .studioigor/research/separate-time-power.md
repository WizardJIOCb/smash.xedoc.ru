# Separate day/night and ultimate, 2026-11-14

User explicitly requested separate controls. T toggles a persistent world-night
flag without charge/timer/combat changes. Q activates existing 8s power; L remains
its impulse. World grading and aura have separate smoothed strengths. Expiry,
relays and room loading cannot change the selected time; a new run starts in day.
Quarantine still supplies a subtle daytime warning wash and full night artwork.

Official input reference checked (echo disabled by default):
https://docs.godotengine.org/en/stable/classes/class_inputevent.html

Verify T alone, Q in daylight, T during power, expiry while night remains selected,
and T with empty charge. Keep normal combat and score persistence unchanged.
