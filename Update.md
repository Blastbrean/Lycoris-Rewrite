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
+ (added) IceHeroBlade
+ (changed) TelegraphMinor
+ (changed) MetalRain
+ (changed) WeaponTest
+ (changed) IceLance
+ (changed) ElderPrimaSixStomp
```
Relentless Hunt now should no longer parries your own move. 
It attempts to parry instead of block with some added information in the notification.
**Base combat has been changed heavily, report any bad hitboxes.**

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
+ (changed) Animation : BoneBoyRushGo (by Juanito)
+ (changed) Animation : CrabboRexBeam (by Juanito)
+ (changed) Animation : DarkBlade (by Juanito)
+ (changed) Animation : BoneBoyLeapAttack (by Juanito)
+ (changed) Animation : BounderSwing1 (by Juanito)
+ (changed) Animation : BrainsuckerDive (by Juanito)
+ (changed) Animation : BounderLeap (by Juanito)
+ (changed) Animation : BounderSwing2 (by Juanito)
+ (changed) Animation : BounderChargePrep (by Juanito)
+ (changed) Animation : BruteHeavyPunch (by Juanito)
+ (changed) Animation : CrabboDoubleSlash (by Juanito)
+ (changed) Animation : CoralSpear (by Juanito)
+ (changed) Animation : CrabboGrab (by Juanito)
+ (changed) Animation : CroccoPoison (by Juanito)
+ (changed) Animation : CrabboRexFall (by Juanito)
+ (changed) Animation : CrabboSlam (by Juanito)
+ (changed) Animation : DeepOwlSwipe1 (by Juanito)
+ (changed) Animation : DeepSpiderSpit (by Juanito)
+ (changed) Animation : DeepOwlSwipe2 (by Juanito)
+ (changed) Animation : DukeWindBlast (by Juanito)
+ (changed) Animation : EdenbrandCrit (by Juanito)
+ (changed) Animation : EthironPunch (by Juanito)
+ (changed) Animation : GaleLungeWindup (by Juanito)
+ (changed) Animation : ForgeGHCrit (by Juanito)
+ (changed) Animation : GreatMaulCrit (by Juanito)
+ (changed) Animation : Heartwing (by Juanito)
- (removed) Animation : IceHeroCrit (by Juanito)
+ (changed) Animation : KanaboCrit (by Juanito)
+ (changed) Animation : KingCroccoPoisonBreath (by Juanito)
+ (changed) Animation : KingCroccoSlam (by Juanito)
+ (changed) Animation : LionfishTripleBite (by Juanito)
+ (changed) Animation : MawbladesCrit (by Juanito)
+ (changed) Animation : MaestroTripleSlash (by Juanito)
+ (changed) Animation : MiniCrabDoubleSwipe (by Juanito)
+ (changed) Animation : MechaGatling (by Juanito)
+ (changed) Animation : OwlPrimeSwipe (by Juanito)
+ (changed) Animation : Onslaught (by Juanito)
+ (changed) Animation : PetrasCritFollowup (by Juanito)
+ (changed) Animation : PyreKeeperCrit (by Juanito)
+ (changed) Animation : PyreKeeperCritRunning (by Juanito)
+ (changed) Animation : RogueConstructStomp (by Juanito)
+ (changed) Animation : RogueConstructGroundPound (by Juanito)
+ (changed) Animation : RogueConstructSwipe (by Juanito)
+ (changed) Animation : SharkoDropKick (by Juanito)
+ (changed) Animation : SkyreapCrit (by Juanito)
+ (changed) Animation : SquidwardSlash2 (by Juanito)
+ (changed) Animation : StonesparkSwing1 (by Juanito)
+ (changed) Animation : StonesparkSwing2 (by Juanito)
+ (changed) Animation : SquidwardSlash3 (by Juanito)
+ (changed) Animation : StonesparkHeavy (by Juanito)
+ (changed) Animation : SquidwardSlash1 (by Juanito)
+ (changed) Animation : TitusVent (by Juanito)
+ (changed) Animation : TerrapodStandSwipe (by Juanito)
+ (changed) Animation : TerrapodTripleSwipe (by Juanito)
+ (changed) Animation : UmbriteCrit (by Juanito)
```
*A lot of these moves that were changed now have the 'Hyperarmor' flag turned on.*

**New features?**
```diff
- (bug fix) Animation speed changer cycled through many random speeds in one timing
- (bug fix) Updated info spoofing to use the new pathing
- (bug fix) Info spoofing now spoofs player properties
- (removed) "User is in hit animation" check is now removed
- (removed) Temporarily removed using the map position to locate far away players (32k+ studs)
+ (added) Animation speed changer has new switch between speeds feature
+ (added) Aggressive auto feint type which ignores all player attacking checks and functions like Legacy does
+ (added) Entity ESP rework
+ (added) Hide Allies On ESP
+ (added) Player list whitelisting
+ (added) Damage indicators
+ (changed) Auto feint now respects hyperarmor (this caused auto feint to be useless in PVE) (this data may be missing for some timings; please report if so)
+ (changed) Auto feint now runs another check a bit before the timing to combat feinting latency
+ (changed) Whitelisted players are now considered allies
```
*Info spoofing does not prevent you from hovering over the spectate list. If you do so, it will show real usernames.*

*Your commit ID should == "asdasdasd" when the update is fully pushed to you.*