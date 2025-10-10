# Deepwoken Rewrite
Module diff vs. previous snapshot: +5/-2/~18 (added/removed/changed)
```diff
+ (added) FlameRepulsion
+ (added) IceBeam
+ (added) IronSlam
+ (added) LightningAssault
+ (added) RisingFlame
- (removed) LightningImpact
- (removed) WindCarve
+ (changed) FireEruption
+ (changed) StrongLeft
+ (changed) Scythe
+ (changed) ElderPrimaUltimateStomp
+ (changed) ShadowGun
+ (changed) BurningServants
+ (changed) Revenge
+ (changed) ShadowSludge
+ (changed) ElderPrimaSixStomp
+ (changed) PrimadonTripleStomp
+ (changed) HitTendril
+ (changed) WeaponAerialAttackTest
+ (changed) TitusKick
+ (changed) Decimate
+ (changed) WeaponTest
+ (changed) DeepspindleCrit
+ (changed) FirePalm
+ (changed) KaritaLeap
```

Timing diff vs. previous snapshot: +12/-4/~69 (animation: +8/-1/~60, part: +3/-2/~5, sound: +1/-0/~2, effect: +0/-1/~2)
```diff
+ (changed) Animation : 2_GenericGreatsword1
+ (changed) Animation : WindCarve
+ (changed) Animation : 1_GenericGreatAxe2
+ (changed) Animation : WindBlade
+ (changed) Animation : SilentheartHeavyRelentless
+ (changed) Animation : DeepspindleCrit
+ (changed) Animation : ShadowEruptionCast
+ (changed) Animation : KaritaLeap
+ (changed) Animation : KaritaDiveBomb
+ (changed) Animation : ExhaustionStrike
+ (added) Animation : DuskguardAxeCrit
+ (changed) Animation : LightningImpact
+ (changed) Animation : DaggerThrow
+ (changed) Animation : PyreKeeperCrit
+ (changed) Animation : BoltcrusherCrit
+ (changed) Animation : PyreKeeperM1_1
+ (changed) Animation : PyreKeeperM1_3
+ (changed) Animation : PyreKeeperM1_2
+ (changed) Animation : PyreKeeperM1_Aerial
+ (added) Animation : FrozenServantsBlast
+ (changed) Animation : BurningServants
+ (changed) Animation : FlameRepulsion
+ (changed) Animation : RisingFlameWindup
+ (changed) Animation : AshSlam
+ (changed) Animation : FireBlade
+ (changed) Animation : FlameLeap
+ (changed) Animation : DeathFromAbove
+ (changed) Animation : RisingWind
+ (changed) Animation : ImperialM1_1
+ (changed) Animation : ImperialM1_3
+ (changed) Animation : ImperialM1_2
+ (changed) Animation : FlashdrawStrike
+ (changed) Animation : ShoulderBashGo
+ (changed) Animation : ShadeBringer
+ (changed) Animation : ShadeBringer2
+ (changed) Animation : ScytheRunning
+ (changed) Animation : IronSlam
+ (changed) Animation : IceCarve
+ (added) Animation : IceCarveSpin
+ (changed) Animation : RisingFrost
+ (changed) Animation : IceBeam
+ (added) Animation : LightningBlade
- (removed) Animation : LightningBlades
+ (added) Animation : LightningBladeMagnet
+ (changed) Animation : StormcallerSlash
+ (added) Animation : LightningAssault
+ (changed) Animation : IceForgeCast
+ (changed) Animation : PurpleCloud1
+ (changed) Animation : PurpleCloud2
+ (changed) Animation : PurpleCloud3
+ (changed) Animation : PurpleCloudCrit
+ (added) Animation : PhoenixSlam
+ (changed) Animation : PyreKeeperCritRunningHit
+ (changed) Animation : PyreKeeperCritRunning
+ (changed) Animation : EnforcersAxeCrit
+ (changed) Animation : DarksteelSwordCrit
+ (changed) Animation : ReverieCrit
+ (changed) Animation : VigillongswordCrit
+ (changed) Animation : MaliceM1_4
+ (changed) Animation : MaliceM1_1
+ (changed) Animation : MaliceM1_2
+ (changed) Animation : MaliceM1_3
+ (changed) Animation : MaliceRunning
+ (changed) Animation : MaliceAerial
+ (changed) Animation : SoulflareSiphon
+ (changed) Animation : ElderPrimaDoubleHangSwing2
+ (changed) Animation : PrimadonTripleStomp
+ (changed) Animation : PrimadonStomp
+ (added) Animation : HiddenBlade
+ (changed) Part : MetalTurret
+ (changed) Part : SnareTrap
- (removed) Part : MalStrike3
+ (changed) Part : MalStrike1
- (removed) Part : MalStrike2
+ (added) Part : StaticBall
+ (changed) Part : windyp
+ (added) Part : FlameBallista
+ (changed) Part : FlameBallistaBlue
+ (added) Part : IceSpike
+ (changed) Sound : TelegraphMinor
+ (changed) Sound : Iceberg
+ (added) Sound : GrandWardensAxe
- (removed) Effect : ManiKatti
+ (changed) Effect : DisplayThornsRed
+ (changed) Effect : DisplayThorns
```
*More fixes later. I am working on upcoming features. Juan is working on timings. When I come back, I will fix everything.*

**New features?**
```diff
+ (added) Attach to back rework
```
*Planning on revamping Tween To Objectives and adding quality of life on my list.*

*Your commit ID should == "8573a4" when the update is fully pushed to you.*