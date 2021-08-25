# Removal of SSVM dependency

a somewhat long task that will grant more freedom and make future creations a lot more stable

## functions to replace

init and update hold a whole lot of stuff so I'm not going to bother with them yet

vsoNext

vsoStorageSaveAndLoad
	vsoStorageSave
		vsoStorageSaveData
	vsoStorageLoad
		vsoStorageLoadData

vsoPill

vsoPillValue

vsoStorageLoad
	vsoStorageLoadData

_add_vso_rpc

vsoTimerEvery
	vsoTimerSet
		vsoTT
	vsoTTCheck

vsoFacePoint
	vsoFaceDirection
		vsoMotionParam
			mMotionParametersSet

vsoDebugRect

_vsoOnDeath
