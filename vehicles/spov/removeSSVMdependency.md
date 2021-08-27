# Removal of SSVM dependency

a somewhat long task that will grant more freedom and make future creations a lot more stable

## functions to replace

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

vsoFacePoint
	vsoFaceDirection
		vsoMotionParam
			mMotionParametersSet
