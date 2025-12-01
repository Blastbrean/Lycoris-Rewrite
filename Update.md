# Deepwoken Rewrite
**Module diff vs. previous snapshot: +1/-0/~10 (added/removed/changed)**
```diff
+ (added) SilentheartWarn
+ (changed) PressureBlast
+ (changed) WeaponTest
+ (changed) RisingShadow
+ (changed) WeaponAerialAttackTest
+ (changed) OwlDisperse
+ (changed) WeaponFlourishTest
+ (changed) RapidPunches
+ (changed) GaleHeroblade
+ (changed) WeaponUppercutTest
+ (changed) WeaponRunningAttackTest
+ (changed) WeaponTest
+ (changed) PressureBlast

```
Relentless Hunt now should no longer parries your own move. 
It attempts to parry instead of block with some added information in the notification.
**Base combat has been changed massively, report any bad hitboxes.**

**Timing diff vs. previous snapshot: +1/-1/~5 (animation: +1/-1/~4, effect: +0/-0/~1)**
```diff
+ (changed) Animation : IceLance (by Blastbrean)
+ (added) Animation : IceSmashWindup (by Blastbrean)
- (removed) Animation : IceSmash (by Blastbrean)
+ (changed) Animation : RisingFrost (by Blastbrean)
+ (changed) Animation : TwisterKicks (by Blastbrean)
+ (changed) Animation : HeavenlyWind (by Blastbrean)
+ (changed) Effect : SilentheartWarn (by Blastbrean)
+ (changed) Animation : IceCarve (by Blastbrean)
+ (changed) Animation : DarkBlade (by Blastbrean)
+ (changed) Animation : HeavenlyWind (by Blastbrean)
```

**New features?**
```diff
- (bug fix) Animation speed changer cycled through many random speeds in one timing
- (removed) "User is in hit animation" check is now removed
+ (added) Animation speed changer has new switch between speeds feature
+ (added) Aggressive auto feint type which ignores all player attacking checks
+ (changed) Auto feint now respects hyperarmor (this caused auto feint to be useless in PVE) (this data may be missing for some timings; please report if so)
+ (changed) Auto feint now runs another check a bit before the timing to combat feinting latency
```

*No change in commit ID. This update is super minor.*