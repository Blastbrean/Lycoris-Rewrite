# Deepwoken Rewrite
**Module diff vs. previous snapshot: +7/-25/~29 (added/removed/changed)**
```diff
+ (added) DisplayThorns
+ (added) DisplayThornsRed
+ (added) FirePalm
+ (added) InfernoRunningCrit
+ (added) RapidSlashes
+ (added) SilentheartHeavyMayhem
+ (added) SoulthornCrit
- (removed) DaggerAerial
- (removed) DaggerSwing
- (removed) FangCoilSwing
- (removed) FistAerial
- (removed) FistRunningAttack
- (removed) Flourish
- (removed) GreataxeSwing
- (removed) GreathammerUppercut
- (removed) GreatswordSwing
- (removed) GreatswordUppercut
- (removed) GunShot
- (removed) GunUppercut
- (removed) HeavyAerial
- (removed) JusKaritaSwing
- (removed) JusKaritaUppercut
- (removed) LegionMasterySwing
- (removed) LegionSwing
- (removed) MusketSwing
- (removed) NavaeSwing
- (removed) RapierSwing
- (removed) RunningAttack
- (removed) SpearSwing
- (removed) SpearUppercut
- (removed) SwordAerial
- (removed) SwordSwing
+ (changed) FireEruption
+ (changed) SilentheartHeavyRelentless
+ (changed) Scythe
+ (changed) GreatswordCritical
+ (changed) JusKaritaCritical
+ (changed) RocketLance
+ (changed) RapierCritical
+ (changed) WeaponAerialAttackTest
+ (changed) SilentheartMediumMayhem
+ (changed) SilentheartLightRisingStar
+ (changed) SilentheartMediumRelentless
+ (changed) GreataxeCritical
+ (changed) DaggerCritical
+ (changed) MetalRush
+ (changed) WeaponRunningAttackTest
+ (changed) RapidPunches
+ (changed) DaggerThrow
+ (changed) NavaeCritical
+ (changed) SpearCritical
+ (changed) WeaponTest
+ (changed) ShadowEruptionCast
+ (changed) SwordCritical
+ (changed) GroundSlideSilentheart
+ (changed) Veinbreaker
+ (changed) WeaponUppercutTest
+ (changed) EtherBarrage
+ (changed) WeaponFlourishTest
+ (changed) KatanaCritical
+ (changed) SilentheartLightMayhem
```

**Timing diff vs. previous snapshot: +35/-3/~125 (animation: +29/-0/~118, part: +5/-1/~7, sound: +1/-1/~0, effect: +0/-1/~0)**
```diff
+ (changed) Animation : ShadowGun
+ (changed) Animation : ShadowEruptionCast
+ (changed) Animation : 1_GenericHeavyAerial
+ (changed) Animation : 1_GenericGreatswordRunning
+ (changed) Animation : KatanaCritical
+ (changed) Animation : 1_GenericSwordAerial
+ (changed) Animation : RunningAttackKatana
+ (changed) Animation : Punishment
+ (changed) Animation : Twincleave
+ (changed) Animation : FirePalm
+ (changed) Animation : Windgun
+ (changed) Animation : GaleLungeGo
+ (changed) Animation : MetalFakeout
+ (added) Animation : Impel
+ (changed) Animation : Restrain
+ (changed) Animation : Restrain_2
+ (changed) Animation : Rupture
+ (added) Animation : Rupture2
+ (changed) Animation : 1_GenericDaggerRunning
+ (changed) Animation : MayhemSilentheart
+ (changed) Animation : SilentheartMediumMayhem
+ (changed) Animation : SlientheartLightRelentless
+ (changed) Animation : SilentheartLightMayhem
+ (added) Animation : StormbreakerCrit
+ (added) Animation : LightningBlades
+ (added) Animation : StormcallerSlash
+ (changed) Animation : BrachialSpear
+ (changed) Animation : EnforcerPullHuman
+ (changed) Animation : BeastBurrow
+ (changed) Animation : CoralSpear
+ (changed) Animation : RapidPunches
+ (changed) Animation : BloodfoulerCrit
+ (changed) Animation : BloodfoulerCritRunning
+ (changed) Animation : Scythe_2
+ (changed) Animation : RazorBlitz
+ (added) Animation : CeaselessSlashes
+ (changed) Animation : RapidSlashes
+ (changed) Animation : RhythmAdvance
+ (changed) Animation : MastersFlourish
+ (changed) Animation : TacetKick
+ (changed) Animation : MetalRush
+ (changed) Animation : MetalHug
+ (changed) Animation : RocketLance
+ (changed) Animation : SkyreapCrit
+ (changed) Animation : WraithclawCrit
+ (changed) Animation : 1_GenericSwordUppercut
+ (changed) Animation : 1_GenericFangCoil1
+ (changed) Animation : 1_GenericTwinblade1
+ (changed) Animation : 2_GenericPistol1
+ (changed) Animation : 1_GenericPistolShot2
+ (changed) Animation : 1_GenericSword2
+ (changed) Animation : 2_GenericPistol2
+ (changed) Animation : 1_GenericKarita3
+ (changed) Animation : 1_GenericKaritaFlourish
+ (changed) Animation : 2_GenericGreatsword1
+ (changed) Animation : 1_GenericMusket3
+ (changed) Animation : 1_GenericGreatAxe1
+ (changed) Animation : 1_GenericHeavyUppercut
+ (changed) Animation : 1_GenericDagger1
+ (changed) Animation : 1_GenericGaleKata2
+ (changed) Animation : 1_GenericSpearUppercut
+ (changed) Animation : 1_GenericLegionKata1
+ (changed) Animation : 1_GenericPistol2
+ (changed) Animation : 1_GenericNavae3
+ (changed) Animation : 1_GenericFlourish
+ (changed) Animation : 1_GenericNavaeFlourish
+ (changed) Animation : 2_GenericBow2
+ (changed) Animation : 1_GenericTwinbladeRunning
+ (changed) Animation : 1_GenericKarita2
+ (changed) Animation : 1_GenericGaleKata3
+ (added) Animation : 2_GenericPistolAerial
+ (changed) Animation : 1_GenericGreatsword2
+ (changed) Animation : 1_GenericNavae1
+ (changed) Animation : 1_GenericTwinblade2
+ (changed) Animation : 1_GenericDagger3
+ (changed) Animation : 1_GenericFistAerial
+ (changed) Animation : 1_GenericFangCoil3
+ (added) Animation : 1_GenericBowAerial
+ (changed) Animation : 2_GenericTwinblade1
+ (changed) Animation : 1_GenericSpear2
+ (changed) Animation : 1_GenericLegionKata2
+ (changed) Animation : 1_GenericRapier2
+ (changed) Animation : 1_GenericGreatAxe2
+ (changed) Animation : 1_GenericLegionKata3
+ (added) Animation : 1_GenericKaritaRunning
+ (added) Animation : 1_GenericRifleRunning
+ (changed) Animation : 2_GenericBow3
+ (changed) Animation : 1_GenericKarita1
+ (changed) Animation : 1_GenericRapierRunning
+ (changed) Animation : 2_GenericSpearRunning
+ (changed) Animation : 1_GenericGaleKata4
+ (changed) Animation : 1_GenericGaleKata1
+ (changed) Animation : 2_GenericSpear2
+ (changed) Animation : 2_GenericTwinblade2
+ (added) Animation : 1_GenericBowRunning
+ (changed) Animation : 1_GenericGreatcannon2
+ (changed) Animation : 1_GenericGreatsword1
+ (changed) Animation : 1_GenericFangCoilFlourish
+ (changed) Animation : 2_GenericBowFlourish
+ (changed) Animation : 1_GenericPistol1
+ (changed) Animation : 1_GenericPistolShot1
+ (changed) Animation : 2_GenericBow1
+ (changed) Animation : 1_GenericMusket2
+ (changed) Animation : 1_GenericPistolShot3
+ (added) Animation : 1_GenericPistolUppercut
+ (changed) Animation : 2_GenericGreatsword2
+ (changed) Animation : 1_GenericGreatAxe3
+ (changed) Animation : 1_GenericLegionKataFlourish
+ (changed) Animation : 1_GenericNavae2
+ (changed) Animation : 1_GenericTwinbladeAerial
+ (changed) Animation : 1_GenericFangCoil2
+ (changed) Animation : 1_GenericDaggerUppercut
+ (changed) Animation : 1_GenericRapier1
+ (changed) Animation : 1_GenericPistolRunning
+ (changed) Animation : 1_GenericTwinblade3
+ (changed) Animation : 1_GenericSword1
+ (changed) Animation : 1_GenericGreatcannon1
+ (changed) Animation : 1_GenericMusket1
+ (changed) Animation : 1_GenericSpear1
+ (changed) Animation : 1_GenericDagger2
+ (changed) Animation : 1_GenericDaggerAerial
+ (changed) Animation : 2_GenericSpear1
+ (changed) Animation : 1_GenericGreathammerUppercut
+ (added) Animation : IceSaber1
+ (added) Animation : IceSaber3
+ (added) Animation : IceSaber2
+ (changed) Animation : 1SwordSwing1
+ (changed) Animation : 1SwordSwing2
+ (added) Animation : PurpleCloud1
+ (added) Animation : PurpleCloud2
+ (added) Animation : PurpleCloud3
+ (added) Animation : PurpleCloudCrit
+ (changed) Animation : SoulthornCrit
+ (changed) Animation : ChorusCrit
+ (added) Animation : 1Inferno1
+ (added) Animation : 1Inferno2
+ (added) Animation : 1Inferno3
+ (added) Animation : 2Inferno1
+ (added) Animation : 2Inferno2
+ (added) Animation : 2Inferno3
+ (added) Animation : InfernoRunningCrit
+ (added) Animation : InfernoRunningCritt
+ (changed) Animation : FrostGrabWindup
+ (changed) Animation : FangCoilCritical
+ (added) Animation : EtherBarrage
+ (added) Animation : DaggerThrow
+ (changed) Animation : KyrswynterCritRunning
+ (added) Part : ChainwardenProjectile
+ (added) Part : Bubble
- (removed) Part : BrachialSpear
+ (changed) Part : MetalGatling
+ (changed) Part : AbyssalRidge
+ (changed) Part : Rock
+ (added) Part : MetalTurret
+ (changed) Part : FlameBlind
+ (changed) Part : MalStrike1
+ (changed) Part : MalStrike3
+ (changed) Part : MalStrike2
+ (added) Part : LightningStrike
+ (added) Part : IceBirdRed
- (removed) Sound : RputureSecond
+ (added) Sound : Rupture
- (removed) effect : ManiKatti
```
*New weapon system is in the script. The hitboxes should be really huge, let me know if they're a big issue. I also want to know if it parries late at all on any weapon type.*
*I am aware that 'Pistol / Gun' does not have bullet support. This will be re-implemented later.*

**New features?**
No new features added.

*Your commit ID should == "bf1395" when the update is fully pushed to you.*